#!/usr/bin/env sh
# Check that the VPN gateway is reachable and that the documented chain fix works.
#
# Usage:
#   ./verify.sh           readable
#   ./verify.sh --json    machine-readable, identifiers stripped
#
# Runs from anywhere: the gateway is public. No credentials are used and no
# connection is attempted — this observes the TLS handshake only.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

fetch_leaf() {
  echo | timeout 15 openssl s_client -connect "$(fact vpn host):$(fact vpn port)" \
    -servername "$(fact vpn host)" 2>/dev/null
}

main() {
  parse_common_args "$@"

  _reachable=no
  _verifies=no
  _expires=unknown

  if _handshake=$(fetch_leaf) && [ -n "$_handshake" ]; then
    _reachable=yes
    _leaf=$(mktemp)
    trap 'rm -f "$_leaf"' EXIT
    printf '%s\n' "$_handshake" | openssl x509 -out "$_leaf" 2>/dev/null || true

    if [ -s "$_leaf" ]; then
      _expires=$(openssl x509 -in "$_leaf" -noout -enddate 2>/dev/null | cut -d= -f2)
      openssl verify "$_leaf" >/dev/null 2>&1 && _verifies=yes
    fi
  fi

  if [ "$JSON" = "1" ]; then
    _status=ok
    [ "$_reachable" = yes ] && [ "$_verifies" = yes ] || _status=incomplete
    json_result "$_status" "vpn check" \
      "reachable=$_reachable" "chain_verifies=$_verifies" \
      "leaf_expires=$_expires" "os=$(detect_os)" | redact
    [ "$_status" = ok ] || exit 1
    return 0
  fi

  log "Gateway reachable:   ${_reachable}"
  log "Chain verifies:      ${_verifies}"
  log "Certificate expires: ${_expires}"

  if [ "$_reachable" = no ]; then
    log ""
    log "Could not reach $(fact vpn host). Check your internet connection first."
    exit 1
  fi

  if [ "$_verifies" = no ]; then
    log ""
    log "The intermediate certificate is not installed on this system."
    log "See the VPN page — it is a one-time step."
    exit 1
  fi
}

case "${0##*/}" in
  verify.sh) main "$@" ;;
esac
