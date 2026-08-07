#!/usr/bin/env sh
# Connect to the campus VPN, with a readable diagnosis when the chain is broken.
#
# Usage:
#   ./connect.sh              connect (stays in foreground; Ctrl+C disconnects)
#   ./connect.sh --dry-run    print what would run
#
# The gateway omits its intermediate certificate, so a stock client fails with a
# TLS error that reads like a local misconfiguration. Checking first turns that
# into an actionable message.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# Can the system build a chain to the gateway on its own?
chain_is_complete() {
  _host=$(fact vpn host)
  _port=$(fact vpn port)
  echo | timeout 15 openssl s_client -connect "${_host}:${_port}" \
    -servername "$_host" 2>/dev/null |
    grep -q 'Verify return code: 0'
}

explain_missing_intermediate() {
  cat <<EOF
The system cannot verify $(fact vpn host).

This is expected until the missing intermediate certificate is installed once:
the gateway does not send it. Install $(fact vpn issuer) from

  $(fact vpn intermediate_url)

See the VPN page for the command for your system. After that this check passes
and no special flags are needed.
EOF
}

main() {
  parse_common_args "$@"

  have openfortivpn || die "openfortivpn not installed."

  if [ "$DRY_RUN" != "1" ] && ! chain_is_complete; then
    explain_missing_intermediate
    exit 1
  fi

  log "Connecting to $(fact vpn host). A browser window will open for SSO login."
  log "Keep this running; Ctrl+C disconnects."
  run sudo openfortivpn "$(fact vpn host)" --saml-login
}

# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-connect.sh.
case "${0##*/}" in
  *connect.sh) main "$@" ;;
esac
