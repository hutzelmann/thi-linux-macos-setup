#!/usr/bin/env bash
# Run one check inside a throwaway container, and keep what it saw.
#
# The problem this solves is the host. Reproducing somebody's failing check
# means running their steps, and running their steps on a working machine is
# how a working machine stops working. A container is the third option: the
# unmodified script runs on a system that is deleted afterwards, the repository
# is mounted read-only so nothing can be edited by accident, and the evidence
# lands in a directory on the host that outlives the container.
#
# Usage:
#   scripts/debug.sh vpn                    the VPN check, on Debian
#   scripts/debug.sh printing --os=arch     on Arch instead
#   scripts/debug.sh shares --shell         a shell in the container, after it
#   scripts/debug.sh vpn -- --queue=NAME    arguments for the check itself
#
# What comes out: ./debug/<domain>-<os>/, holding the evidence files and the
# JSON result. Gitignored, yours to read, and never sent anywhere.
#
# What no container answers is at the bottom of this file, per domain, and the
# script refuses the domains where the answer would be about the container
# rather than about your machine.
set -euo pipefail

# Domains a container can say something true about, and what it is.
#
# A check reads the machine it runs on. For four of these that machine can be
# any Linux with the right client tools, because the thing being observed is on
# the network. For the other four the machine *is* the subject, so a container
# would answer confidently about the container: it has no radio, no socket, no
# screen, and its own disk encryption and firewall are the host's, not the
# reader's. Those refuse rather than mislead (AGENTS.md rule 3).
supported_domains() {
  cat <<'EOF'
printing|the queue is created for real, by the unmodified script
shares|name resolution and the SMB port, from wherever this host sits
vpn|the gateway handshake and the documented bundle
EOF
}

refused_domains() {
  cat <<'EOF'
wifi|a container has no radio and no NetworkManager profiles
network|a container has no physical port and no 802.1X supplicant
policy|the disk encryption and firewall it would report are the container's
devices|a container has no display connected to anything
vm|the virtualisation support it would report is the container's
EOF
}

main() {
  cd "$(dirname "$0")/.."

  local domain="" os=debian shell=0 arg
  local -a extra=()
  local after_dashdash=0

  for arg in "$@"; do
    if [ "$after_dashdash" -eq 1 ]; then
      extra+=("$arg")
      continue
    fi
    case "$arg" in
      --) after_dashdash=1 ;;
      --os=arch | --os=debian) os=${arg#--os=} ;;
      --shell) shell=1 ;;
      --help | -h) usage ;;
      -*) usage "unknown argument: $arg" ;;
      *)
        [ -z "$domain" ] || usage "one domain at a time, got $domain and $arg"
        domain=$arg
        ;;
    esac
  done

  [ -n "$domain" ] || usage "which check? one of: $(supported_domains | cut -d'|' -f1 | tr '\n' ' ')"

  local refusal
  if refusal=$(refused_domains | grep "^${domain}|" | cut -d'|' -f2-); then
    echo "error: ${domain} cannot be checked in a container." >&2
    echo "       ${refusal}." >&2
    echo >&2
    echo "       Run it on the machine it is about:" >&2
    echo "         scripts/${domain}/verify.sh --evidence" >&2
    exit 2
  fi

  if ! supported_domains | grep -q "^${domain}|"; then
    echo "error: no check called ${domain}." >&2
    echo "       In a container: $(supported_domains | cut -d'|' -f1 | tr '\n' ' ')" >&2
    exit 2
  fi

  [ -x "scripts/${domain}/verify.sh" ] || {
    echo "error: scripts/${domain}/verify.sh is missing or not executable." >&2
    exit 2
  }

  local engine image scratch
  engine=$(container_engine)
  image="thi-setup-debug-$os"
  scratch="debug/${domain}-${os}"

  mkdir -p "$scratch"

  printf '=== %s on %s ===\n' "$domain" "$os"
  "$engine" build -q -t "$image" -f "test/debug/Dockerfile.$os" test/debug >/dev/null

  # Read-only repository, writable scratch. The check under test only reads the
  # repository, and a container that cannot write to it cannot leave anything
  # behind either. Everything it produces goes to the one directory that is
  # bind-mounted back, which is what makes the evidence survive --rm.
  #
  # As the invoking user, not root: with docker the container's root owns
  # everything it writes to a bind mount, and the evidence then needs a
  # privilege to read or delete that the person who asked for it does not have.
  # None of these checks needs root anyway, which is the same reason they do not
  # ask for one when run directly.
  local -a opts=(
    --rm
    --user "$(id -u):$(id -g)"
    -v "$PWD:/repo:ro"
    -v "$PWD/$scratch:/scratch"
    -w /scratch
    -e FACTS_DIR=/repo/facts
    -e HOME=/scratch
  )

  # Every FACT_* override on this shell goes in too, so a run against a
  # substituted value behaves the same inside and outside. The script stamps
  # them into its own result either way.
  local var
  while IFS= read -r var; do
    [ -n "$var" ] && opts+=(-e "$var")
  done < <(env | sed -n 's/^\(FACT_[A-Z0-9_]*\)=.*/\1/p')

  if [ "$shell" -eq 1 ]; then
    opts+=(-it)
    "$engine" run "${opts[@]}" "$image" /bin/sh -c \
      "/repo/scripts/${domain}/verify.sh --evidence=/scratch/evidence $(printf '%q ' "${extra[@]+"${extra[@]}"}"); exec /bin/sh"
  else
    "$engine" run "${opts[@]}" "$image" \
      "/repo/scripts/${domain}/verify.sh" --evidence=/scratch/evidence \
      ${extra[@]+"${extra[@]}"} || true
  fi

  echo
  echo "Evidence kept on this machine, in ${scratch}/evidence/."
  echo "Read it before it goes anywhere: it describes a run, not a person, but"
  echo "only you can tell whether some line of it names you."
}

container_engine() {
  local candidate
  for candidate in docker podman; do
    if command -v "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  echo "error: neither docker nor podman is installed." >&2
  echo "       Without one, run the check directly instead:" >&2
  echo "         scripts/<domain>/verify.sh --evidence" >&2
  exit 1
}

usage() {
  [ $# -gt 0 ] && echo "error: $1" >&2
  sed -n '/^# Usage:/,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2
  echo "Checks that need the machine itself, and are refused here:" >&2
  refused_domains | sed 's/|/: /; s/^/  /' >&2
  exit 2
}

# Entry point. Guarded so the functions above can be sourced and called.
case "${0##*/}" in
  debug.sh) main "$@" ;;
esac
