#!/usr/bin/env bash
# Run the printing scripts against a throwaway CUPS, from anywhere.
#
# Everything scripts/printing/install.sh does is a change to the CUPS
# configuration of the machine that runs it, so trying it out has meant either
# changing a working machine or not trying it out. A container is the third
# option: the queue is created for real, by the unmodified script, on a system
# that is deleted afterwards. Nothing on the host is touched.
#
# Two images, because the page gives Arch and Debian different instructions.
# Debian installs a .deb and points lpadmin at an absolute PPD path; Arch builds
# ${facts.printing.driver_aur} from the AUR and points lpadmin at a CUPS model
# name. A pass on one says nothing about the other.
#
# What no container can answer:
#
#   - whether the campus print server accepts the job    (needs the network)
#   - whether SMB authentication works                   (needs a credential)
#   - whether the sheet comes out punched                (needs the device)
#
# Those are what a check record is for. This covers the part that is code.
#
# The driver is optional and worth supplying, because it is what makes the
# documented PPD values checkable: facts.printing.ppd_path on Debian,
# facts.printing.ppd_model on Arch. Off campus, on any machine.
#
# Usage:
#   test/printing/run.sh                     both images, without the driver
#   test/printing/run.sh --os=arch           one of them
#   test/printing/run.sh --driver-deb=<deb>  Debian, with the vendor package
#   test/printing/run.sh --build-aur         Arch, building the AUR package
#   test/printing/run.sh --driver-pkg=<pkg>  Arch, with a package built earlier
#   test/printing/run.sh --os=arch --keep    a shell in the container instead
set -euo pipefail

main() {
  cd "$(dirname "$0")/../.."

  local os=both driver_deb="" driver_pkg="" build_aur=0 keep=0 arg
  for arg in "$@"; do
    case "$arg" in
      --os=arch | --os=debian | --os=both) os=${arg#--os=} ;;
      --driver-deb=*) driver_deb=$(absolute "${arg#--driver-deb=}") ;;
      --driver-pkg=*) driver_pkg=$(absolute "${arg#--driver-pkg=}") ;;
      --build-aur) build_aur=1 ;;
      --keep) keep=1 ;;
      *) usage "unknown argument: $arg" ;;
    esac
  done

  if [ "$keep" -eq 1 ] && [ "$os" = both ]; then
    usage "--keep needs a single --os"
  fi

  local engine
  engine=$(container_engine)

  local failed=0
  case "$os" in
    arch | debian) run_one "$engine" "$os" || failed=1 ;;
    both)
      # Both are run even if the first fails: the useful output is the pair.
      run_one "$engine" debian || failed=1
      run_one "$engine" arch || failed=1
      ;;
  esac

  return "$failed"
}

# run_one <engine> <os>
run_one() {
  local engine=$1 os=$2
  local image="thi-setup-printing-test-$os"

  printf '\n=== %s ===\n' "$os"
  "$engine" build -q -t "$image" -f "test/printing/Dockerfile.$os" test/printing >/dev/null

  # Read-only: the scripts under test only read the repository, and a container
  # that cannot write to it cannot leave anything behind either.
  #
  # driver_deb and the rest are main's locals. Bash scopes those dynamically, so
  # they are in view here without being threaded through the arguments.
  local opts=(--rm -v "$PWD:/repo:ro")

  case "$os" in
    debian)
      if [ -n "$driver_deb" ]; then opts+=(-v "$driver_deb:/driver.deb:ro"); fi
      ;;
    arch)
      if [ -n "$driver_pkg" ]; then opts+=(-v "$driver_pkg:/driver.pkg.tar.zst:ro"); fi
      # The AUR build reaches the network for the PKGBUILD and its sources.
      if [ "$build_aur" -eq 1 ]; then opts+=(-e BUILD_AUR=1); fi
      ;;
  esac

  if [ "$keep" -eq 1 ]; then opts+=(--entrypoint /bin/bash -it); fi

  "$engine" run "${opts[@]}" "$image"
}

absolute() {
  [ -r "$1" ] || {
    echo "error: cannot read $1" >&2
    exit 1
  }
  printf '%s/%s\n' "$(cd "$(dirname "$1")" && pwd)" "$(basename "$1")"
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
  echo "       This is the only part of the repository that needs one." >&2
  exit 1
}

usage() {
  echo "error: $1" >&2
  sed -n '/^# Usage:/,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2
  exit 2
}

# Entry point. Guarded so the functions above can be sourced and called.
case "${0##*/}" in
  run.sh) main "$@" ;;
esac
