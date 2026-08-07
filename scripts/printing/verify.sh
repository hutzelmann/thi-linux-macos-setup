#!/usr/bin/env sh
# Check that the print queue is set up and the server answers.
#
# Usage:
#   ./verify.sh           human-readable
#   ./verify.sh --json    machine-readable, identifiers stripped
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

queue_exists() {
  lpstat -p "$(fact printing queue)" >/dev/null 2>&1
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
  lpoptions -p "$(fact printing queue)" -l 2>/dev/null | grep -q '^Pnch'
}

main() {
  parse_common_args "$@"

  _queue_ok=no
  _server_ok=no
  _options_ok=no

  queue_exists && _queue_ok=yes
  server_reachable && _server_ok=yes
  [ "$_queue_ok" = yes ] && finishing_options_present && _options_ok=yes

  if [ "$JSON" = "1" ]; then
    _status=ok
    [ "$_queue_ok" = yes ] && [ "$_server_ok" = yes ] && [ "$_options_ok" = yes ] || _status=incomplete
    json_result "$_status" "printing check" \
      "queue=$_queue_ok" "server=$_server_ok" "finishing_options=$_options_ok" \
      "os=$(detect_os)" | redact
    [ "$_status" = ok ] || exit 1
    return 0
  fi

  log "Queue configured:      ${_queue_ok}"
  log "Print server answers:  ${_server_ok}  (needs campus network or VPN)"
  log "Punch/staple options:  ${_options_ok}"

  if [ "$_queue_ok" = no ]; then
    log ""
    log "Queue missing. Run ./install.sh"
    exit 1
  fi
  if [ "$_options_ok" = no ]; then
    log ""
    log "Finishing options missing — the vendor PPD is probably not installed."
    log "Without it, duplex/punch/staple recipes will be rejected."
    exit 1
  fi
}

case "${0##*/}" in
  verify.sh) main "$@" ;;
esac
