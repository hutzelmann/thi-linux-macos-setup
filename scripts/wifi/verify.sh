#!/usr/bin/env sh
# Check that a Wi-Fi profile validates the authentication server.
#
# Usage:
#   ./verify.sh           readable
#   ./verify.sh --json    machine-readable, identifiers stripped
#   ./verify.sh --evidence  write down everything it saw, for debugging later
#
# Not "are you online"; that is visible already. This checks the two settings
# that decide whether your campus password can be collected by a fake access
# point, both of which are silently optional and frequently missing.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# The page these checks belong to, for --report. Not derivable from the
# directory name: scripts/network/ would document /en/network/ethernet-802-1x.
REPORT_PAGE=/en/wifi/

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
  evidence_open wifi

  if [ "$(detect_os)" = "macos" ]; then
    log "macOS stores Wi-Fi profiles in the system keychain, not NetworkManager."
    log "Check that the eduroam profile came from $(fact wifi cat_url):"
    log "  System Settings -> General -> VPN & Device Management"
    exit 0
  fi

  have nmcli || die "nmcli not found. This check assumes NetworkManager."

  _any=0
  _insecure=0
  _profiles=""

  for _ssid in "$(fact wifi eduroam_ssid)" "$(fact wifi thi_ssid)"; do
    profile_exists "$_ssid" || continue
    _any=1

    # The profile as NetworkManager holds it, not the two fields this check
    # reduces it to. A profile that fails here usually fails for a third reason
    # visible nowhere else, and asking somebody to re-run nmcli by hand and
    # paste the right part of it is how a report stops arriving. The identity
    # and any hardware address are replaced on the way out.
    nmcli connection show "$_ssid" 2>&1 |
      evidence "profile-$(printf '%s' "$_ssid" | tr -c 'a-zA-Z0-9' '-')"

    # shellcheck disable=SC2046  # deliberate word splitting of two fields
    set -- $(inspect_profile "$_ssid")
    _ca_ok=$1
    _suffix_ok=$2

    if [ "$JSON" = "1" ]; then
      _profile_status=ok
      [ "$_ca_ok" = yes ] && [ "$_suffix_ok" = yes ] || _profile_status=insecure
      json_result "$_profile_status" "wifi profile check" \
        "profile=$_ssid" "ca_certificate=$_ca_ok" "server_name_match=$_suffix_ok" | redact
    else
      log "Profile ${_ssid}"
      log "  CA certificate set:   ${_ca_ok}"
      log "  Server name matched:  ${_suffix_ok}"
    fi

    [ "$_ca_ok" = yes ] && [ "$_suffix_ok" = yes ] || _insecure=1
    _profiles="${_profiles}${_profiles:+ }${_ssid}"
  done

  if [ "$_any" = 0 ]; then
    log "No campus Wi-Fi profile found on this machine."
    evidence_close
    exit 0
  fi

  _status=ok
  [ "$_insecure" = 1 ] && _status=insecure

  if [ "$_insecure" = 1 ] && [ "$JSON" != "1" ]; then
    log ""
    log "At least one profile does not fully validate the authentication server."
    log "Your campus password can be collected by an access point impersonating"
    log "this network. Fix: reconfigure with $(fact wifi cat_url), or set both"
    log "802-1x.ca-cert and 802-1x.domain-suffix-match."
  fi

  # One line for the whole machine. The per-profile objects above are what --json
  # is for; a report is about whether the page worked, which is one answer.
  #
  # After the advice, not instead of it: a report of what did not work is worth
  # filing too, and it is the report the page most needs.
  if [ "$REPORT" = "1" ]; then
    _json=$(json_result "$_status" "wifi check" \
      "profiles=$_profiles" "os=$(detect_os)" | redact)
    print_report "$REPORT_PAGE" "$(report_outcome "$_status")" "$_json"
  fi
  evidence_close

  [ "$_status" = ok ] || exit 1
}


# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-verify.sh.
case "${0##*/}" in
  *verify.sh) main "$@" ;;
esac
