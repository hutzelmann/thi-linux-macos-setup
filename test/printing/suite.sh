#!/usr/bin/env bash
# Assertions for the printing scripts, run inside the container.
#
# Not a unit test of the shell functions: it runs scripts/printing/install.sh
# and scripts/printing/verify.sh exactly as a reader would, and then looks at
# what CUPS ended up with. The point is to catch the two things that stay
# invisible until somebody tries it on a real machine: a command form this
# version of CUPS rejects, and a documented path the driver package does not
# use.
#
# Arch and Debian are told to do different things by the page, so the driver
# step and the PPD assertion differ here too. Each OS is checked against the
# claims its own block of the page makes, and nothing else.
#
# Never run this outside the container. It creates and deletes print queues.
set -uo pipefail # deliberately not -e: every assertion runs, then the tally

REPO=/repo
INSTALL="$REPO/scripts/printing/install.sh"
VERIFY="$REPO/scripts/printing/verify.sh"

DRIVER_DEB=/driver.deb
DRIVER_PKG=/driver.pkg.tar.zst
BUILD_AUR=${BUILD_AUR:-0}

# shellcheck source=../../scripts/lib/common.sh
. "$REPO/scripts/lib/common.sh"
# shellcheck source=../../scripts/lib/facts.sh
. "$REPO/scripts/lib/facts.sh"

OS=$(detect_os)

# Set once the driver is in, so the assertions that need a PPD know whether
# they are checking something or excusing themselves.
HAVE_DRIVER=0

passed=0
failed=0
skipped=0

ok() {
  printf '  ok    %s\n' "$1"
  passed=$((passed + 1))
}

bad() {
  printf '  FAIL  %s\n' "$1"
  shift
  local line
  for line in "$@"; do printf '        %s\n' "$line"; done
  failed=$((failed + 1))
}

skip() {
  printf '  skip  %s\n' "$1"
  shift
  local line
  for line in "$@"; do printf '        %s\n' "$line"; done
  skipped=$((skipped + 1))
}

note() {
  local line
  for line in "$@"; do printf '        %s\n' "$line"; done
}

heading() {
  printf '\n%s\n' "$1"
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    ok "$label"
  else
    bad "$label" "expected to find: $needle" "in:" "$haystack"
  fi
}

start_cups() {
  cupsd
  local waited=0
  while [ "$waited" -lt 20 ]; do
    lpstat -r >/dev/null 2>&1 && return 0
    sleep 0.5
    waited=$((waited + 1))
  done
  echo "cupsd did not come up; nothing below would mean anything." >&2
  exit 1
}

# --- the documented commands --------------------------------------------------
#
# --dry-run prints what the reader is told to type. Asserting on it is how the
# fact substitution gets tested without a print server in the room.

test_dry_run_matches_the_documented_values() {
  heading "Dry run emits the documented command"

  local out
  out=$(sh "$INSTALL" --dry-run 2>&1)

  assert_contains "staff queue name" "$out" "-p $(fact printing queue) "
  assert_contains "device URI" "$out" \
    "-v smb://$(fact printing server)/$(fact printing queue) "
  assert_contains "PPD path" "$out" "-m $(fact printing ppd_path)"

  out=$(sh "$INSTALL" --students --dry-run 2>&1)
  assert_contains "student queue name" "$out" "-p $(fact printing queue_students) "
}

# Debian's smbclient depends on samba-common, which ships /etc/samba/smb.conf,
# so on that image the file is there before any script runs. Whether the scripts
# create it is the question; whether apt did is not. Clearing it first is what
# makes the same assertion mean the same thing on both images.
clear_samba_config() {
  rm -f /etc/samba/smb.conf
}

test_dry_run_changes_nothing() {
  heading "Dry run changes nothing"

  if [ -n "$(lpstat -p 2>/dev/null)" ]; then
    bad "no queue was created" "lpstat -p reports:" "$(lpstat -p)"
  else
    ok "no queue was created"
  fi

  if [ -e /etc/samba/smb.conf ]; then
    bad "no samba config was written" "/etc/samba/smb.conf exists after a dry run"
  else
    ok "no samba config was written"
  fi
}

# --- the driver ---------------------------------------------------------------
#
# The PPD values on the printing page come from a 250 MB download nobody wants
# to repeat, which is why they are the values most likely to be stale. With a
# package to hand they can be checked here, off campus, on any machine.

install_driver() {
  heading "Driver"

  case "$OS" in
    debian) install_driver_debian ;;
    arch) install_driver_arch ;;
    *)
      skip "driver install" "unrecognised container OS: $OS"
      ;;
  esac
}

install_driver_debian() {
  if [ ! -r "$DRIVER_DEB" ]; then
    skip "vendor package installs" \
      "No package mounted, so the PPD assertions cannot run. Unpack the tarball" \
      "from facts.printing.driver_url once, then:" \
      "  test/printing/run.sh --os=debian --driver-deb=<path to $(basename "$(fact printing driver_deb)")>"
    return
  fi

  local out
  if ! out=$(dpkg -i "$DRIVER_DEB" 2>&1); then
    bad "vendor package installs" "$out"
    return
  fi
  ok "vendor package installs"
  HAVE_DRIVER=1

  # The Debian block of the page ends with "This puts the PPD at <ppd_path>",
  # so that path is a claim the page makes and this is the check of it.
  if [ -f "$(fact printing ppd_path)" ]; then
    ok "documented PPD path exists"
  else
    bad "documented PPD path exists" \
      "facts.printing.ppd_path says: $(fact printing ppd_path)" \
      "the package installed these instead:" \
      "$(installed_ppds)"
  fi
}

install_driver_arch() {
  if [ -r "$DRIVER_PKG" ]; then
    local out
    if ! out=$(pacman -U --noconfirm "$DRIVER_PKG" 2>&1); then
      bad "AUR package installs" "$out"
      return
    fi
    ok "AUR package installs"
    HAVE_DRIVER=1
    assert_arch_ppd_model
    return
  fi

  if [ "$BUILD_AUR" != "1" ]; then
    skip "AUR package installs" \
      "No package mounted and no build requested, so the PPD assertions cannot run:" \
      "  test/printing/run.sh --os=arch --build-aur" \
      "or, with a package built earlier:" \
      "  test/printing/run.sh --os=arch --driver-pkg=<$(fact printing driver_aur)-*.pkg.tar.zst>"
    return
  fi

  build_aur_package || return
  HAVE_DRIVER=1
  assert_arch_ppd_model
}

# Build ${facts.printing.driver_aur} the way the page says to.
#
# The clone address is written here rather than in facts/ because it is not a
# documented value: the package name is, and AUR git URLs are that name under a
# fixed host. A plain GET of the .git address is a 404, so putting it in facts/
# would only give check-fact-urls.sh something to fail on.
build_aur_package() {
  local pkg
  pkg=$(fact printing driver_aur)

  local out
  if ! out=$(sudo -u builder git clone --depth 1 \
    "https://aur.archlinux.org/${pkg}.git" "/tmp/$pkg" 2>&1); then
    bad "AUR package clones" "$out"
    return 1
  fi
  ok "AUR package clones"

  if out=$(cd "/tmp/$pkg" && sudo -u builder makepkg -si --noconfirm 2>&1); then
    ok "AUR package builds and installs"
    return 0
  fi

  # Two very different reasons a build stops, and calling them both "the vendor
  # archive again" hides the one that is actionable.
  #
  # A dependency that no repository and no AUR entry provides is a failure of the
  # route the page documents: nobody following it gets a PPD, on any machine, and
  # an AUR helper resolves from the same two places, so yay fails here too.
  #
  # A source that cannot be fetched unattended is the state of the world the page
  # already describes, and it is what the reader is told to expect.
  if printf '%s' "$out" | grep -qE 'Could not resolve all dependencies|target not found'; then
    bad "AUR package builds" \
      "$(fact printing driver_aur) asks for a dependency that cannot be installed:" \
      "$(printf '%s' "$out" | grep -A5 'Missing dependencies' | sed 's/^/  /')" \
      "This is the route the printing page sends Arch readers down, so the page" \
      "is currently ahead of what the AUR can deliver. Check the package's AUR" \
      "page before changing anything here: the fix belongs upstream or in the" \
      "page, not in this suite."
    return 1
  fi

  skip "AUR package builds" \
    "makepkg did not complete unattended, and not because of a dependency. The" \
    "page says the vendor archive has no stable direct link, so this is the" \
    "expected outcome when the PKGBUILD wants it placed beside the build." \
    "Last lines:" \
    "$(printf '%s' "$out" | tail -12)"
  return 1
}

# The Arch block of the page adds the queue with -m <ppd_model>, so what has to
# be true on Arch is that CUPS knows that model name, not that a particular file
# exists. Debian claims a path; Arch claims a catalogue entry.
assert_arch_ppd_model() {
  if lpinfo -m 2>/dev/null | grep -qF "$(fact printing ppd_model)"; then
    ok "documented PPD model is in the CUPS catalogue"
  else
    bad "documented PPD model is in the CUPS catalogue" \
      "facts.printing.ppd_model says: $(fact printing ppd_model)" \
      "the package installed these instead:" \
      "$(installed_ppds)"
  fi
}

installed_ppds() {
  find / -xdev -iname '*.ppd*' 2>/dev/null | grep -i kyocera | head -20
}

# --- the install itself -------------------------------------------------------

test_install_creates_the_queue() {
  heading "Install"

  clear_samba_config

  local out rc
  out=$(sh "$INSTALL" 2>&1)
  rc=$?

  local fell_back=0
  if printf '%s' "$out" | grep -qF 'Absolute PPD path rejected'; then fell_back=1; fi

  if [ -f /etc/samba/smb.conf ]; then
    ok "creates /etc/samba/smb.conf when the smb backend has none"
  else
    bad "creates /etc/samba/smb.conf when the smb backend has none" "$out"
  fi

  if [ "$HAVE_DRIVER" -eq 0 ]; then
    if [ "$rc" -ne 0 ]; then
      ok "fails legibly without a driver"
      assert_contains "and names where to get one" "$out" "$(fact printing driver_url)"
    else
      bad "fails legibly without a driver" \
        "install.sh reported success with no PPD installed" "$out"
    fi
    return
  fi

  if lpstat -p "$(fact printing queue)" >/dev/null 2>&1; then
    ok "queue exists afterwards"
  else
    bad "queue exists afterwards" "exit status $rc" "$out"
    return
  fi

  # Which of the two -m forms this CUPS accepted is the single most useful thing
  # the container reports, and it is only knowable once a queue exists. The page
  # carries the fallback because one machine rejected the absolute path, and on
  # Arch the fallback is the documented form to begin with, so the answer is
  # expected to differ between the two images.
  if [ "$fell_back" -eq 1 ]; then
    note "this CUPS rejected -m $(fact printing ppd_path)" \
      "and accepted the fallback -m $(fact printing ppd_model)"
  else
    note "this CUPS accepted -m $(fact printing ppd_path) directly"
  fi

  assert_contains "queue points at the documented server" \
    "$(lpstat -v "$(fact printing queue)" 2>&1)" \
    "smb://$(fact printing server)/$(fact printing queue)"

  if lpoptions -p "$(fact printing queue)" -l 2>/dev/null | grep -q '^Pnch'; then
    ok "finishing options are in the PPD"
  else
    bad "finishing options are in the PPD" \
      "verify.sh looks for an option named Pnch, and the page promises punching" \
      "and stapling. The queue offers:" \
      "$(lpoptions -p "$(fact printing queue)" -l 2>&1 | cut -d/ -f1 | tr '\n' ' ')"
  fi
}

# --- verify.sh ----------------------------------------------------------------

test_verify_reports_what_it_can_see() {
  heading "verify.sh"

  local json
  json=$(sh "$VERIFY" --json 2>&1)

  if [ "$HAVE_DRIVER" -eq 1 ]; then
    assert_contains "sees the queue" "$json" '"queue":"yes"'
    assert_contains "sees the finishing options" "$json" '"finishing_options":"yes"'
  else
    assert_contains "reports the missing queue" "$json" '"queue":"no"'
  fi

  # The campus print server does not resolve from here. Saying so is the correct
  # result, not a failure of the script.
  assert_contains "reports the server as unreachable off campus" "$json" '"server":"no"'

  if printf '%s' "$json" | grep -qF 'facts_overridden'; then
    bad "says nothing was overridden" "$json"
  else
    ok "says nothing was overridden"
  fi
}

test_override_is_honoured_and_declared() {
  heading "Environment override"

  # A listener stands in for the print server so the reachable branch runs at
  # all. It is a socket on loopback, not a claim about campus, and the result
  # has to say so on its own.
  nc -l 127.0.0.1 445 >/dev/null 2>&1 &
  local listener=$!
  sleep 1

  local json
  json=$(FACT_PRINTING_SERVER=127.0.0.1 sh "$VERIFY" --json 2>&1)
  kill "$listener" 2>/dev/null
  wait "$listener" 2>/dev/null

  assert_contains "the override is used" "$json" '"server":"yes"'
  assert_contains "and the result declares it" "$json" '"facts_overridden":"printing.server"'

  # The same run must never offer itself as a check record.
  local report
  report=$(FACT_PRINTING_SERVER=127.0.0.1 sh "$VERIFY" --report 2>&1)
  if printf '%s' "$report" | grep -qF 'outcome=Worked'; then
    bad "no prefilled outcome from an overridden run" \
      "the link would file a passing check record for a value the page does not document"
  else
    ok "no prefilled outcome from an overridden run"
  fi
}

# --- teardown -----------------------------------------------------------------

test_removal_is_what_the_script_says_it_is() {
  heading "Removal"

  if ! lpstat -p "$(fact printing queue)" >/dev/null 2>&1; then
    skip "lpadmin -x removes the queue" "no queue was created, nothing to remove"
    return
  fi

  local out
  if ! out=$(lpadmin -x "$(fact printing queue)" 2>&1); then
    bad "lpadmin -x removes the queue" "$out"
    return
  fi

  if lpstat -p "$(fact printing queue)" >/dev/null 2>&1; then
    bad "lpadmin -x removes the queue" "the queue is still configured"
  else
    ok "lpadmin -x removes the queue"
  fi
}

main() {
  [ -d "$REPO/facts" ] || {
    echo "This runs inside the container, with the repository mounted at /repo." >&2
    echo "From a clone: test/printing/run.sh" >&2
    exit 1
  }

  start_cups
  clear_samba_config

  printf 'Print queue scripts on %s, against a throwaway CUPS.\n' "$OS"
  printf 'Nothing here reaches campus: no server, no credential, no sheet of paper.\n'

  test_dry_run_matches_the_documented_values
  test_dry_run_changes_nothing
  install_driver
  test_install_creates_the_queue
  test_verify_reports_what_it_can_see
  test_override_is_honoured_and_declared
  test_removal_is_what_the_script_says_it_is

  printf '\n%s passed, %s failed, %s skipped\n' "$passed" "$failed" "$skipped"
  printf '\n%s\n' "A pass here is not a check record. It says the scripts do what the page"
  printf '%s\n' "says on a clean machine, not that printing works at the device."

  [ "$failed" -eq 0 ]
}

# Entry point. Guarded so the functions above can be sourced and called.
case "${0##*/}" in
  suite.sh) main "$@" ;;
esac
