#!/usr/bin/env sh
# Add the departmental colour queue to CUPS.
#
# Usage:
#   ./install.sh                 add the staff queue
#   ./install.sh --students      add the student queue instead
#   ./install.sh --queue=NAME    add a named queue
#   ./install.sh --dry-run       print the commands, change nothing
#
# The driver tarball cannot be downloaded unattended (vendor site, ~250 MB, no
# stable direct link), so this script sets up the queue and tells you what to
# fetch. Everything it does is reversible with: sudo lpadmin -x <queue>
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# Both queues live on the same print server and differ only in name, so the
# queue is a parameter rather than a second script.
QUEUE=${QUEUE:-}

select_queue() {
  for _arg in "$@"; do
    case "$_arg" in
      --students) QUEUE=$(fact printing queue_students) ;;
      --queue=*) QUEUE=${_arg#--queue=} ;;
    esac
  done
  [ -n "$QUEUE" ] || QUEUE=$(fact printing queue)
}

check_prerequisites() {
  have lpadmin || die "cupsd not installed. See the page for the package name for your OS."

  if [ ! -f "$(fact printing ppd_path)" ] && [ "$DRY_RUN" != "1" ]; then
    warn "PPD not found at $(fact printing ppd_path)"
    warn "Install the vendor driver first: $(fact printing driver_url)"
    warn "Continuing. Some CUPS builds resolve the model name instead."
  fi
}

# Two accepted forms for -m, and which one works varies by CUPS build. The
# absolute path is tried first because it is unambiguous; the model name is the
# documented fallback, and it is the one that worked on a KDE/Debian machine
# where the path was rejected.
add_queue() {
  _queue=$QUEUE
  _uri="smb://$(fact printing server)/${QUEUE}"

  if lpstat -p "$_queue" >/dev/null 2>&1 && [ "$DRY_RUN" != "1" ]; then
    log "Queue ${_queue} already exists. Remove it first: sudo lpadmin -x ${_queue}"
    return 0
  fi

  log "Adding queue ${_queue} -> ${_uri}"
  if run sudo lpadmin -p "$_queue" -E -v "$_uri" -m "$(fact printing ppd_path)"; then
    return 0
  fi

  log "Absolute PPD path rejected, retrying with the CUPS model name"
  run sudo lpadmin -p "$_queue" -E -v "$_uri" -m "$(fact printing ppd_model)"
}

# The CUPS SMB backend fails on some systems when no Samba config exists at all.
ensure_samba_config() {
  [ "$(detect_os)" = "macos" ] && return 0
  [ -f /etc/samba/smb.conf ] && return 0

  log "No /etc/samba/smb.conf, creating an empty one for the CUPS smb backend"
  run sudo mkdir -p /etc/samba
  run sudo touch /etc/samba/smb.conf
}

main() {
  parse_common_args "$@"
  select_queue "$@"
  check_prerequisites
  ensure_samba_config
  add_queue

  log ""
  log "Next: print something. CUPS will ask for your campus credentials."
  log "  username: <kennung>   domain: $(fact printing smb_domain)"
  log "Then release the job at the device with your campus card."
}

# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-install.sh.
case "${0##*/}" in
  *install.sh) main "$@" ;;
esac
