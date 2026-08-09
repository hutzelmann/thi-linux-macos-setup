#!/usr/bin/env sh
# Check that the VPN gateway is reachable and that the documented bundle works.
#
# Usage:
#   ./verify.sh           readable
#   ./verify.sh --json    machine-readable, identifiers stripped
#
# Runs from anywhere: the gateway is public. No credentials are used and no
# connection is attempted; this observes the TLS handshake only.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# The page these checks belong to, for --report. Not derivable from the
# directory name: scripts/network/ would document /en/network/ethernet-802-1x.
REPORT_PAGE=/en/vpn/openfortivpn

fetch_leaf() {
  echo | timeout 15 openssl s_client -connect "$(fact vpn host):$(fact vpn port)" \
    -servername "$(fact vpn host)" 2>/dev/null
}

main() {
  parse_common_args "$@"

  _bundle=$(fact vpn ca_bundle)
  _reachable=no
  _bundle_present=no
  _verifies=no
  _expires=unknown

  [ -r "$_bundle" ] && _bundle_present=yes

  if _handshake=$(fetch_leaf) && [ -n "$_handshake" ]; then
    _reachable=yes
    _leaf=$(mktemp)
    trap 'rm -f "$_leaf"' EXIT
    printf '%s\n' "$_handshake" | openssl x509 -out "$_leaf" 2>/dev/null || true

    if [ -s "$_leaf" ]; then
      _expires=$(openssl x509 -in "$_leaf" -noout -enddate 2>/dev/null | cut -d= -f2)
      if [ "$_bundle_present" = yes ] &&
        openssl verify -CAfile "$_bundle" "$_leaf" >/dev/null 2>&1; then
        _verifies=yes
      fi
    fi
  fi

  _status=ok
  [ "$_reachable" = yes ] && [ "$_verifies" = yes ] || _status=incomplete

  # Built once, whoever asked for it. --json prints it, --report puts it in the
  # form, and both are the same observation so they cannot disagree.
  _json=$(json_result "$_status" "vpn check" \
    "reachable=$_reachable" "bundle_present=$_bundle_present" \
    "chain_verifies=$_verifies" \
    "leaf_expires=$_expires" "os=$(detect_os)" | redact)

  if [ "$JSON" = "1" ]; then
    printf '%s\n' "$_json"
    [ "$_status" = ok ] || exit 1
    return 0
  fi

  log "Gateway reachable:   ${_reachable}"
  log "Bundle present:      ${_bundle_present}  (${_bundle})"
  log "Verifies with it:    ${_verifies}"
  log "Certificate expires: ${_expires}"

  if [ "$_reachable" = no ]; then
    log ""
    log "Could not reach $(fact vpn host). Check your internet connection first."
  elif [ "$_bundle_present" = no ]; then
    log ""
    log "The certificate bundle has not been built yet."
    log "See the VPN page; it is a one-time step and touches nothing else."
  elif [ "$_verifies" = no ]; then
    log ""
    log "The bundle exists but does not verify the gateway certificate."
    log "Rebuild it: the intermediate first, then the system root certificates."
  fi

  # After the advice, not instead of it: a report of what did not work is worth
  # filing too, and it is the report the page most needs.
  [ "$REPORT" = "1" ] && print_report "$REPORT_PAGE" "$(report_outcome "$_status")" "$_json"

  [ "$_status" = ok ] || exit 1
}


# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-verify.sh.
case "${0##*/}" in
  *verify.sh) main "$@" ;;
esac
