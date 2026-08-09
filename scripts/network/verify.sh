#!/usr/bin/env sh
# Check a campus Ethernet port: what the machine is set up to send, and what
# the port gave back.
#
# Usage:
#   ./verify.sh                    readable
#   ./verify.sh --interface=NAME   a particular wired interface
#   ./verify.sh --json             machine-readable, identifiers stripped
#   ./verify.sh --evidence         write down everything it saw, for debugging later
#
# A wired port is the one thing on this site that cannot be checked from
# anywhere else: you have to be standing next to it with a cable. So this
# script is written to be run once, on campus, and to record enough that the
# rest of the work can happen at a desk. --evidence is the point of it.
#
# Nothing is sent and no password is used. Every observation is of this machine:
# its own interfaces, its own NetworkManager profiles, its own addresses.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# The page these checks belong to, for --report. Not derivable from the
# directory name: scripts/network/ documents /en/network/ethernet-802-1x.
REPORT_PAGE=/en/network/ethernet-802-1x

IFACE=${IFACE:-}

select_interface() {
  for _arg in "$@"; do
    case "$_arg" in
      --interface=*) IFACE=${_arg#--interface=} ;;
    esac
  done
  [ -n "$IFACE" ] || IFACE=$(first_wired)
}

# The first wired interface that is not something this machine made up.
#
# Container bridges, virtual machine taps and the veth halves of both are all
# `ethernet` to the kernel and to NetworkManager, and a laptop that runs either
# has more of them than it has sockets. Matching the kernel's own naming is
# cruder than asking NetworkManager and works on a machine that does not run it.
first_wired() {
  [ -d /sys/class/net ] || return 0
  for _path in /sys/class/net/*; do
    _name=${_path##*/}
    case "$_name" in
      en* | eth*) ;;
      *) continue ;;
    esac
    # A physical port has a device behind it in the sysfs tree. A tap does not.
    [ -e "$_path/device" ] || continue
    printf '%s\n' "$_name"
    return 0
  done
}

carrier() {
  [ -r "/sys/class/net/$1/carrier" ] || return 1
  [ "$(cat "/sys/class/net/$1/carrier" 2>/dev/null)" = "1" ]
}

# Prints: assigned, self-assigned, or none.
#
# The page says the same thing in prose: an address means the port let you
# through, 169.254 means it did not, and nothing at all means the same. Which
# of the two you get is a detail of how long the machine waited.
#
# `assigned` and not `campus`: this machine cannot tell a campus address from a
# home router's, no documented range says which is which, and guessing one here
# would be the kind of plausible value rule 3 exists to keep out. Whether the
# port was a campus port is something the person holding the cable knows.
address_kind() {
  _addr=$(ip -4 -brief address show "$1" 2>/dev/null | awk '{print $3}')
  case "$_addr" in
    '') printf 'none\n' ;;
    169.254.*) printf 'self-assigned\n' ;;
    *) printf 'assigned\n' ;;
  esac
}

# Every NetworkManager profile that would answer an 802.1X port on this
# interface. Usually one, occasionally several left over from trying.
wired_8021x_profiles() {
  have nmcli || return 0
  nmcli -t -f NAME,TYPE connection show 2>/dev/null |
    while IFS=: read -r _name _type; do
      [ "$_type" = "802-3-ethernet" ] || continue
      [ -n "$(nm_field "$_name" 802-1x.eap)" ] || continue
      printf '%s\n' "$_name"
    done
}

nm_field() {
  nmcli -t -f "$2" connection show "$1" 2>/dev/null | cut -d: -f2- | head -1
}

# Prints: <eap-ok> <phase2-ok> <identity-ok> <ca-set> <suffix-set>
#
# The identity check is the one that earns its place. The page's own known
# quirks say wired wants the bare kennung and eduroam wants it with a realm,
# that mixing them up fails with no useful message, and a machine that has both
# profiles is exactly where that happens.
inspect_profile() {
  _eap=$(nm_field "$1" 802-1x.eap)
  _phase2=$(nm_field "$1" 802-1x.phase2-auth)
  _identity=$(nm_field "$1" 802-1x.identity)
  _ca=$(nm_field "$1" 802-1x.ca-cert)
  _suffix=$(nm_field "$1" 802-1x.domain-suffix-match)

  _eap_ok=no
  [ "$_eap" = "$(lower "$(fact network wired_eap)")" ] && _eap_ok=yes

  _phase2_ok=no
  [ "$_phase2" = "$(lower "$(fact network wired_phase2)")" ] && _phase2_ok=yes

  _identity_ok=yes
  case "$_identity" in
    '') _identity_ok=empty ;;
    *@*) _identity_ok=has-realm ;;
  esac

  _ca_set=no
  [ -n "$_ca" ] && _ca_set=yes
  _suffix_set=no
  [ -n "$_suffix" ] && _suffix_set=yes

  printf '%s %s %s %s %s\n' \
    "$_eap_ok" "$_phase2_ok" "$_identity_ok" "$_ca_set" "$_suffix_set"
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# Hardware addresses of the wired interfaces, for the registration path.
#
# One registration per address, which is the thing the page warns about and the
# thing people get wrong: a laptop with a built-in port and a dock is two
# submissions, and the dock's address only exists while it is plugged in.
wired_macs() {
  [ -d /sys/class/net ] || return 0
  for _path in /sys/class/net/*; do
    _name=${_path##*/}
    case "$_name" in
      en* | eth*) ;;
      *) continue ;;
    esac
    [ -e "$_path/device" ] || continue
    [ -r "$_path/address" ] || continue
    printf '%s %s\n' "$_name" "$(cat "$_path/address")"
  done
}

macos_main() {
  log "macOS keeps 802.1X in the network service, not in a file this can read."
  log "System Settings -> Network -> Ethernet -> Details -> 802.1X shows it."
  log ""
  log "Wired interfaces and their hardware addresses:"
  networksetup -listallhardwareports 2>/dev/null |
    awk '/Hardware Port: (Ethernet|Thunderbolt|USB)/,/^$/' |
    sed 's/^/  /' || true
  log ""
  log "Each address needs its own registration if this port checks addresses."

  networksetup -listallhardwareports 2>&1 | evidence hardware-ports
  ifconfig 2>&1 | evidence interfaces

  _json=$(json_result incomplete "network check" \
    "reason=macos_profile_not_readable" "os=macos" | redact)
  [ "$JSON" = "1" ] && printf '%s\n' "$_json"
  evidence_close
  # Not a failure and not a pass. Nothing was observed that could be either.
  exit 0
}

main() {
  parse_common_args "$@"
  evidence_open network

  [ "$(detect_os)" = macos ] && macos_main

  have ip || die "ip not found. This check assumes iproute2."

  select_interface "$@"
  [ -n "$IFACE" ] || die "no wired interface found. Pass --interface=NAME."

  _carrier=no
  carrier "$IFACE" && _carrier=yes
  _address=$(address_kind "$IFACE")

  _profiles=$(wired_8021x_profiles)
  _profile_count=$(printf '%s' "$_profiles" | grep -c . || true)

  _eap_ok=n/a
  _phase2_ok=n/a
  _identity_ok=n/a
  _ca_set=n/a
  _suffix_set=n/a

  if [ -n "$_profiles" ]; then
    # The first one. Several profiles for one port is itself worth reporting,
    # and the count in the result says so, but a check that averaged them would
    # describe a profile nobody has.
    _first=$(printf '%s\n' "$_profiles" | head -1)
    # shellcheck disable=SC2046  # deliberate word splitting of five fields
    set -- $(inspect_profile "$_first")
    _eap_ok=$1
    _phase2_ok=$2
    _identity_ok=$3
    _ca_set=$4
    _suffix_set=$5
  fi

  # Evidence, before any of it is reduced to a word.
  ip -brief address show 2>&1 | evidence interfaces
  ip -brief link show 2>&1 | evidence_stream interfaces
  printf '%s\n' "$_profiles" | while read -r _p; do
    [ -n "$_p" ] || continue
    {
      printf '=== %s ===\n' "$_p"
      nmcli connection show "$_p" 2>&1
      printf '\n'
    } | evidence_stream profiles
  done
  wired_macs | evidence hardware-addresses

  _status=ok
  [ "$_address" = assigned ] || _status=incomplete
  [ "$_identity_ok" = has-realm ] && _status=misconfigured
  [ "$_profile_count" -gt 0 ] && [ "$_eap_ok" = no ] && _status=misconfigured
  [ "$_profile_count" -gt 0 ] && [ "$_phase2_ok" = no ] && _status=misconfigured

  # Built once, whoever asked for it. --json prints it, --report puts it in the
  # form, and both are the same observation so they cannot disagree.
  _json=$(json_result "$_status" "network check" \
    "carrier=$_carrier" "address=$_address" "profiles=$_profile_count" \
    "eap=$_eap_ok" "phase2=$_phase2_ok" "identity=$_identity_ok" \
    "ca_certificate=$_ca_set" "server_name_match=$_suffix_set" \
    "os=$(detect_os)" | redact)

  if [ "$JSON" = "1" ]; then
    printf '%s\n' "$_json"
    evidence_close
    [ "$_status" = ok ] || exit 1
    return 0
  fi

  log "Interface:             ${IFACE}"
  log "Cable carrying link:   ${_carrier}"
  log "Address from the port: ${_address}"
  log "802.1X profiles:       ${_profile_count}"

  if [ "$_profile_count" -gt 0 ]; then
    log "  Method matches:      ${_eap_ok}  (documented: $(fact network wired_eap))"
    log "  Inner method:        ${_phase2_ok}  (documented: $(fact network wired_phase2))"
    log "  Identity:            ${_identity_ok}"
    log "  CA certificate set:  ${_ca_set}"
    log "  Server name matched: ${_suffix_set}"
  fi

  log ""
  log "Hardware addresses, one registration each if this port checks them:"
  wired_macs | sed 's/^/  /'

  if [ "$_identity_ok" = has-realm ]; then
    log ""
    log "The identity carries a realm. Wired ports and $(fact wifi thi_ssid) want the bare"
    log "<kennung>; only eduroam wants it with @$(fact wifi eduroam_realm). This fails with"
    log "no useful message, so it is worth ruling out first."
  elif [ "$_carrier" = no ]; then
    log ""
    log "No link on ${IFACE}. Nothing below the cable can be observed from here."
  elif [ "$_address" = self-assigned ] || [ "$_address" = none ]; then
    log ""
    log "The port did not hand out an address. Either the 802.1X login was not"
    log "accepted, or this port checks hardware addresses and this one is not"
    log "registered. The page describes both paths."
  fi

  if [ "$_profile_count" -gt 0 ] && [ "$_ca_set" = no ]; then
    log ""
    log "The certificate fields are empty, which is what the page documents rather"
    log "than a mistake here: the official configuration leaves them unset and no"
    log "confirmed value exists to put in them."
  fi

  # After the advice, not instead of it: a report of what did not work is worth
  # filing too, and it is the report the page most needs.
  [ "$REPORT" = "1" ] && print_report "$REPORT_PAGE" "$(report_outcome "$_status")" "$_json"
  evidence_close

  [ "$_status" = ok ] || exit 1
}


# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-verify.sh.
case "${0##*/}" in
  *verify.sh) main "$@" ;;
esac
