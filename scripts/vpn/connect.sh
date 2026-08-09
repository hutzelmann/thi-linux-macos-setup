#!/usr/bin/env sh
# Connect to the campus VPN, with a readable diagnosis when the bundle is missing.
#
# Usage:
#   ./connect.sh              connect (stays in foreground; Ctrl+C disconnects)
#   ./connect.sh --dry-run    print what would run
#
# The gateway omits its intermediate certificate, so a stock client fails with a
# TLS error that reads like a local misconfiguration. openfortivpn is pointed at
# a bundle of its own instead (--ca-file), which leaves the system trust store
# alone. Checking that bundle first turns the TLS error into an actionable one.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# Does the documented bundle exist and does the gateway verify against it?
bundle_verifies() {
  _bundle=$(fact vpn ca_bundle)
  [ -r "$_bundle" ] || return 1

  _host=$(fact vpn host)
  _port=$(fact vpn port)
  _leaf=$(mktemp)
  echo | timeout 15 openssl s_client -connect "${_host}:${_port}" \
    -servername "$_host" 2>/dev/null |
    openssl x509 -out "$_leaf" 2>/dev/null || true

  if [ -s "$_leaf" ] && openssl verify -CAfile "$_bundle" "$_leaf" >/dev/null 2>&1; then
    rm -f "$_leaf"
    return 0
  fi
  rm -f "$_leaf"
  return 1
}

explain_missing_bundle() {
  cat <<TXT
$(fact vpn ca_bundle) is missing or does not verify $(fact vpn host).

This is expected until the bundle is built once: the gateway does not send its
intermediate certificate. The bundle is $(fact vpn issuer), from

  $(fact vpn intermediate_url)

followed by the system root certificates. See the VPN page for the commands for
your system. Nothing outside openfortivpn is changed by this, and the bundle
outlives the gateway certificate.
TXT
}

main() {
  parse_common_args "$@"

  have openfortivpn || die "openfortivpn not installed."

  if [ "$DRY_RUN" != "1" ] && ! bundle_verifies; then
    explain_missing_bundle
    exit 1
  fi

  log "Connecting to $(fact vpn host). openfortivpn prints an SSO URL below."
  log "Open it in a browser yourself: nothing opens it for you. The connection"
  log "continues here once the login is done."
  log "Keep this running; Ctrl+C disconnects."
  run sudo openfortivpn "$(fact vpn host)" --saml-login \
    --ca-file="$(fact vpn ca_bundle)"
}

# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-connect.sh.
case "${0##*/}" in
  *connect.sh) main "$@" ;;
esac
