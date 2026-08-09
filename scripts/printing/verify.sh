#!/usr/bin/env sh
# Check that the print queue is set up and the server answers.
#
# Usage:
#   ./verify.sh                 check the staff queue
#   ./verify.sh --students      check the student queue instead
#   ./verify.sh --queue=NAME    check a named queue
#   ./verify.sh --json          machine-readable, identifiers stripped
#   ./verify.sh --evidence      write down everything it saw, for debugging later
#
# Deliberately does not print a test page: that costs paper and quota, and needs
# someone standing at the device with a card. Everything here is observation
# only, against endpoints the documentation already names.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# Both queues live on the same print server and differ only in name, so the
# queue is a parameter rather than a second script.
QUEUE=${QUEUE:-}

# The page these checks belong to, for --report. Not derivable from the
# directory name: scripts/network/ would document /en/network/ethernet-802-1x.
REPORT_PAGE=/en/printing/

select_queue() {
  for _arg in "$@"; do
    case "$_arg" in
      --students) QUEUE=$(fact printing queue_students) ;;
      --queue=*) QUEUE=${_arg#--queue=} ;;
    esac
  done
  [ -n "$QUEUE" ] || QUEUE=$(fact printing queue)
}

queue_exists() {
  lpstat -p "$QUEUE" >/dev/null 2>&1
}

server_reachable() {
  _host=$(fact printing server)
  if have nc; then
    nc -z -w 3 "$_host" 445 >/dev/null 2>&1
  else
    # No netcat on a stock macOS install; /dev/tcp is a bash feature, so fall
    # back to a name lookup. Weaker, but better than claiming nothing.
    host "$_host" >/dev/null 2>&1 || nslookup "$_host" >/dev/null 2>&1
  fi
}

finishing_options_present() {
  # Punch and staple come from the PPD. If they are missing, the wrong driver is
  # installed and every recipe on the page will fail with "unsupported option".
  lpoptions -p "$QUEUE" -l 2>/dev/null | grep -q '^Pnch'
}

main() {
  parse_common_args "$@"
  select_queue "$@"
  evidence_open printing

  _queue_ok=no
  _server_ok=no
  _options_ok=no

  queue_exists && _queue_ok=yes
  server_reachable && _server_ok=yes
  [ "$_queue_ok" = yes ] && finishing_options_present && _options_ok=yes

  _status=ok
  [ "$_queue_ok" = yes ] && [ "$_server_ok" = yes ] && [ "$_options_ok" = yes ] || _status=incomplete

  # What CUPS actually holds about this queue, which is the only place the
  # driver, the device URI and the finishing options can be compared against
  # what the page documents. "finishing_options: no" says one of those three is
  # wrong without saying which.
  {
    printf 'queue: %s\n\n' "$QUEUE"
    lpstat -l -p "$QUEUE" 2>&1
    printf '\n'
    lpoptions -p "$QUEUE" -l 2>&1
  } | evidence queue-attributes
  resolved_addresses "$(fact printing server)" | evidence resolved-addresses

  # Built once, whoever asked for it. --json prints it, --report puts it in the
  # form, and both are the same observation so they cannot disagree.
  _json=$(json_result "$_status" "printing check" \
    "queue=$_queue_ok" "queue_name=$QUEUE" "server=$_server_ok" "finishing_options=$_options_ok" \
    "os=$(detect_os)" | redact)

  if [ "$JSON" = "1" ]; then
    printf '%s\n' "$_json"
    [ "$_status" = ok ] || exit 1
    return 0
  fi

  log "Queue:                 ${QUEUE}"
  log "Queue configured:      ${_queue_ok}"
  log "Print server answers:  ${_server_ok}  (needs campus network or VPN)"
  log "Punch/staple options:  ${_options_ok}"

  if [ "$_queue_ok" = no ]; then
    log ""
    log "Queue missing. Run ./install.sh (add --students for the student queue)"
  elif [ "$_options_ok" = no ]; then
    log ""
    log "Finishing options missing. The vendor PPD is probably not installed."
    log "Without it, duplex/punch/staple recipes will be rejected."
  fi

  # After the advice, not instead of it: a report of what did not work is worth
  # filing too, and it is the report the page most needs.
  [ "$REPORT" = "1" ] && print_report "$REPORT_PAGE" "$(report_outcome "$_status")" "$_json"
  evidence_close

  [ "$_status" = ok ] || exit 1
}


# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-verify.sh.
case "${0##*/}" in
  *verify.sh) main "$@" ;;
esac
