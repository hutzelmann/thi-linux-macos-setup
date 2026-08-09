#!/usr/bin/env bash
# Verify the VPN page's central claim still holds.
#
# The gateway serves its leaf certificate without the intermediate, so a stock
# client cannot build a chain. The documented fix is to install the intermediate
# once. This asserts both halves are still true:
#
#   1. the chain still fails without the intermediate  (the page is still needed)
#   2. the chain still succeeds with it                (the documented bundle works)
#
# Also catches the good news: if THI starts serving the full chain, check 1
# flips and the page can be simplified. The gateway is publicly reachable, so
# this needs no campus access and runs in ordinary CI.
#
# Exit codes, because two callers act on them and one of them files a public
# issue:
#
#   0  the chain behaves exactly as the page documents
#   1  something was observed and it differs from the documentation
#   2  nothing could be observed, so there is nothing to say
#
# The difference between 1 and 2 is the whole point. A run that could not reach
# the gateway has not seen a certificate, and reporting that as a changed chain
# is a claim about something nobody looked at.
set -euo pipefail

cd "$(dirname "$0")/../.."

# The same reader the scripts use. It had a second copy here, which dropped
# everything after a `#` and would have read a documented URL with a fragment
# as a shorter URL. One value, one reader (AGENTS.md rule 2).
# shellcheck source=../lib/common.sh
. scripts/lib/common.sh
# shellcheck source=../lib/facts.sh
. scripts/lib/facts.sh

HOST=$(fact vpn host)
PORT=$(fact vpn port)
INTERMEDIATE_URL=$(fact vpn intermediate_url)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "Fetching certificate from ${HOST}:${PORT}"
if ! echo | timeout 20 openssl s_client -connect "${HOST}:${PORT}" \
  -servername "$HOST" >"$work/handshake.txt" 2>/dev/null; then
  echo "  Could not reach ${HOST}:${PORT}"
  echo "  Nothing was observed, so this says nothing about the documentation."
  exit 2
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
# curl's own exit code separates the two cases: 22 is an HTTP status of 400 or
# worse, which is the host answering that the file is not there any more, and
# anything else at this point is not having got that far.
curl_code=0
curl -fsS "$INTERMEDIATE_URL" -o "$work/inter.der" || curl_code=$?
if [ "$curl_code" -eq 22 ]; then
  echo "✗ Documented intermediate is no longer served: ${INTERMEDIATE_URL}"
  echo "  fix: find the current URL in the leaf's Authority Information Access"
  echo "       extension and update facts/vpn.yaml"
  exit 1
elif [ "$curl_code" -ne 0 ]; then
  echo "  Could not fetch ${INTERMEDIATE_URL} (curl ${curl_code})"
  echo "  Nothing was observed, so this says nothing about the documentation."
  exit 2
fi

openssl x509 -inform DER -in "$work/inter.der" -out "$work/inter.pem" 2>/dev/null ||
  cp "$work/inter.der" "$work/inter.pem"

if ! openssl verify -untrusted "$work/inter.pem" "$work/leaf.pem" >/dev/null 2>&1; then
  echo "✗ Chain does not verify even with the documented intermediate."
  echo "  The VPN page's instructions no longer work. This is user-visible."
  exit 1
fi

echo "✓ Documented intermediate still chains to a trusted root"
