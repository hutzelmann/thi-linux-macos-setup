#!/usr/bin/env bash
# Verify the VPN page's central claim still holds.
#
# The gateway serves its leaf certificate without the intermediate, so a stock
# client cannot build a chain. The documented fix is to install the intermediate
# once. This asserts both halves are still true:
#
#   1. the chain still fails without the intermediate  (the page is still needed)
#   2. the chain still succeeds with it                (the fix still works)
#
# Also catches the good news: if THI starts serving the full chain, check 1
# flips and the page can be simplified. The gateway is publicly reachable, so
# this needs no campus access and runs in ordinary CI.
set -euo pipefail

cd "$(dirname "$0")/../.."

fact() {
  sed -n "s/^$2:[[:space:]]*//p" "facts/$1.yaml" | head -1 | tr -d '"'
}

HOST=$(fact vpn host)
PORT=$(fact vpn port)
INTERMEDIATE_URL=$(fact vpn intermediate_url)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "Fetching certificate from ${HOST}:${PORT}"
if ! echo | timeout 20 openssl s_client -connect "${HOST}:${PORT}" \
  -servername "$HOST" >"$work/handshake.txt" 2>/dev/null; then
  echo "✗ Could not reach ${HOST}:${PORT}"
  echo "  Not necessarily a documentation problem. Check connectivity first."
  exit 1
fi

openssl x509 -in "$work/handshake.txt" -out "$work/leaf.pem" 2>/dev/null

not_after=$(openssl x509 -in "$work/leaf.pem" -noout -enddate | cut -d= -f2)
echo "  leaf expires: ${not_after}"

# 1. Without the intermediate the chain must still be incomplete.
if openssl verify "$work/leaf.pem" >/dev/null 2>&1; then
  echo "✓ ${HOST} now serves a complete chain."
  echo "  The intermediate-install step is no longer required."
  echo "  action: simplify content/en/vpn/openfortivpn.md and drop this check."
  exit 0
fi
echo "  chain incomplete without the intermediate, as documented"

# 2. With the documented intermediate it must verify against the system store.
echo "Fetching intermediate from ${INTERMEDIATE_URL}"
if ! curl -fsS "$INTERMEDIATE_URL" -o "$work/inter.der"; then
  echo "✗ Documented intermediate URL is unreachable: ${INTERMEDIATE_URL}"
  echo "  fix: find the current URL in the leaf's Authority Information Access"
  echo "       extension and update facts/vpn.yaml"
  exit 1
fi

openssl x509 -inform DER -in "$work/inter.der" -out "$work/inter.pem" 2>/dev/null ||
  cp "$work/inter.der" "$work/inter.pem"

if ! openssl verify -untrusted "$work/inter.pem" "$work/leaf.pem" >/dev/null 2>&1; then
  echo "✗ Chain does not verify even with the documented intermediate."
  echo "  The VPN page's instructions no longer work. This is user-visible."
  exit 1
fi

echo "✓ Documented chain still verifies against the system trust store"
