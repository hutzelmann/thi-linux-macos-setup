#!/usr/bin/env sh
# Check whether the campus file servers are reachable from here.
#
# Usage:
#   ./verify.sh           readable
#   ./verify.sh --json    machine-readable, identifiers stripped
#
# No credentials are used and nothing is mounted: this answers the question
# people actually have, which is "is it me, the VPN, or the server?". Name
# resolution and a TCP connection to the SMB port are enough to tell those
# apart, and they are ordinary client behaviour against documented hosts.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

SMB_PORT=445

resolves() {
  if have getent; then
    getent hosts "$1" >/dev/null 2>&1
  elif have host; then
    host "$1" >/dev/null 2>&1
  else
    nslookup "$1" >/dev/null 2>&1
  fi
}

port_open() {
  if have nc; then
    nc -z -w 3 "$1" "$SMB_PORT" >/dev/null 2>&1
  else
    # No netcat on a stock macOS install. Resolution alone is weaker evidence,
    # but better than reporting nothing.
    return 2
  fi
}

check_host() {
  _host="$1"
  if ! resolves "$_host"; then
    printf 'no-dns\n'
    return
  fi
  if port_open "$_host"; then
    printf 'ok\n'
  elif [ $? -eq 2 ]; then
    printf 'resolves\n'
  else
    printf 'no-route\n'
  fi
}

explain() {
  case "$1" in
    ok) printf 'reachable\n' ;;
    resolves) printf 'name resolves (cannot test the port without nc)\n' ;;
    no-dns) printf 'name does not resolve: not on campus and no VPN\n' ;;
    no-route) printf 'name resolves but the port is closed: firewall, or VPN still coming up\n' ;;
  esac
}

main() {
  parse_common_args "$@"

  _home=$(check_host "$(fact shares home_server)")
  _files=$(check_host "$(fact shares file_server)")

  if [ "$JSON" = "1" ]; then
    _status=ok
    [ "$_home" = ok ] || [ "$_home" = resolves ] || _status=unreachable
    json_result "$_status" "shares check" \
      "home_server=$_home" "file_server=$_files" "os=$(detect_os)" | redact
    [ "$_status" = ok ] || exit 1
    return 0
  fi

  log "Home server:  $(explain "$_home")"
  log "File server:  $(explain "$_files")"

  if [ "$_home" = no-dns ]; then
    log ""
    log "These names only exist inside the campus network. Connect the VPN first."
    exit 1
  fi
}

# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-verify.sh.
case "${0##*/}" in
  *verify.sh) main "$@" ;;
esac
