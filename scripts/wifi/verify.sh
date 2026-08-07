#!/usr/bin/env sh
# Check that a Wi-Fi profile validates the authentication server.
#
# Usage:
#   ./verify.sh           readable
#   ./verify.sh --json    machine-readable, identifiers stripped
#
# Not "are you online" — that is visible already. This checks the two settings
# that decide whether your campus password can be collected by a fake access
# point, both of which are silently optional and frequently missing.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

nm_field() {
  nmcli -t -f "$2" connection show "$1" 2>/dev/null | cut -d: -f2- | head -1
}

profile_exists() {
  nmcli -t -f NAME connection show 2>/dev/null | grep -qx "$1"
}

# Prints: <ca-present> <suffix-present>
inspect_profile() {
  _ca=$(nm_field "$1" 802-1x.ca-cert)
  _suffix=$(nm_field "$1" 802-1x.domain-suffix-match)
  _sys=$(nm_field "$1" 802-1x.system-ca-certs)

  _ca_ok=no
  [ -n "$_ca" ] && _ca_ok=yes
  [ "$_sys" = "yes" ] && _ca_ok=yes

  _suffix_ok=no
  [ -n "$_suffix" ] && _suffix_ok=yes

  printf '%s %s\n' "$_ca_ok" "$_suffix_ok"
}

main() {
  parse_common_args "$@"

  if [ "$(detect_os)" = "macos" ]; then
    log "macOS stores Wi-Fi profiles in the system keychain, not NetworkManager."
    log "Check that the eduroam profile came from $(fact wifi cat_url):"
    log "  System Settings -> General -> VPN & Device Management"
    exit 0
  fi

  have nmcli || die "nmcli not found. This check assumes NetworkManager."

  _any=0
  _insecure=0

  for _ssid in "$(fact wifi eduroam_ssid)" "$(fact wifi thi_ssid)"; do
    profile_exists "$_ssid" || continue
    _any=1

    # shellcheck disable=SC2046  # deliberate word splitting of two fields
    set -- $(inspect_profile "$_ssid")
    _ca_ok=$1
    _suffix_ok=$2

    if [ "$JSON" = "1" ]; then
      _status=ok
      [ "$_ca_ok" = yes ] && [ "$_suffix_ok" = yes ] || _status=insecure
      json_result "$_status" "wifi profile check" \
        "profile=$_ssid" "ca_certificate=$_ca_ok" "server_name_match=$_suffix_ok" | redact
    else
      log "Profile ${_ssid}"
      log "  CA certificate set:   ${_ca_ok}"
      log "  Server name matched:  ${_suffix_ok}"
    fi

    [ "$_ca_ok" = yes ] && [ "$_suffix_ok" = yes ] || _insecure=1
  done

  if [ "$_any" = 0 ]; then
    log "No campus Wi-Fi profile found on this machine."
    exit 0
  fi

  if [ "$_insecure" = 1 ]; then
    [ "$JSON" = "1" ] || {
      log ""
      log "At least one profile does not fully validate the authentication server."
      log "Your campus password can be collected by an access point impersonating"
      log "this network. Fix: reconfigure with $(fact wifi cat_url), or set both"
      log "802-1x.ca-cert and 802-1x.domain-suffix-match."
    }
    exit 1
  fi
}

# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-verify.sh.
case "${0##*/}" in
  *verify.sh) main "$@" ;;
esac
