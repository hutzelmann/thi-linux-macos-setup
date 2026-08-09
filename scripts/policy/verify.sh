#!/usr/bin/env sh
# Look at the settings the device rules describe, on this machine.
#
# Usage:
#   ./verify.sh           readable
#   ./verify.sh --json    machine-readable, identifiers stripped
#   ./verify.sh --evidence  write down everything it saw, for debugging later
#
# This is not a compliance check and there is nothing to pass. Nothing is sent
# anywhere, nothing is scored, and no result here says whether anybody with
# authority would agree. The page lists six requirements and most people have
# never looked at more than two of them; this prints the state of the ones a
# machine can answer for itself, so the rest of the conversation starts from
# what is actually set.
#
# Read-only throughout, and it does not ask for a password. Two of the six need
# root to see properly, and those say so rather than being guessed at.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# The page these checks belong to, for --report.
REPORT_PAGE=/en/policy/secure-device-config

# The inventory number is never printed, recorded or reported.
#
# The requirement is that the hostname matches the sticker, and the sticker
# carries an `IF…` inventory number, which AGENTS.md rule 1 names as personal
# data: it identifies one machine issued to one person. So this reports whether
# the name has the documented shape and never what the name is. Whether it
# matches the sticker is something only the person looking at the sticker can
# say, and this cannot see it.
INVENTORY_PATTERN='^IF[0-9]'

hostname_shape() {
  _name=$(hostname 2>/dev/null || uname -n)
  if printf '%s' "$_name" | grep -qE "$INVENTORY_PATTERN"; then
    printf 'inventory-format\n'
  else
    printf 'other\n'
  fi
}

# --- Linux --------------------------------------------------------------------

# Whether the filesystem holding / sits on an encrypted volume.
#
# Walks from the mount point down to the physical device rather than looking for
# the word LUKS anywhere in lsblk, because a machine with an encrypted backup
# disk attached and a plaintext root would otherwise report as encrypted.
linux_disk_encryption() {
  have lsblk || {
    printf 'unknown\n'
    return
  }
  # findmnt names a btrfs subvolume as `/dev/dm-0[/@]`, and that is not a path
  # lsblk can be given. Only the device part is wanted.
  _root=$(findmnt -no SOURCE / 2>/dev/null | sed 's/\[.*\]$//') || _root=""
  [ -n "$_root" ] || {
    printf 'unknown\n'
    return
  }
  if lsblk -nlo NAME,FSTYPE --inverse "$_root" 2>/dev/null | grep -q crypto_LUKS; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
}

# Which firewall is running, if any.
#
# The requirement is two things, running and default deny inbound, and only the
# first is visible without root. Reporting the pair as one word would claim the
# half it cannot see.
linux_firewall() {
  for _unit in ufw firewalld nftables iptables; do
    if systemctl is-active --quiet "$_unit" 2>/dev/null; then
      printf '%s\n' "$_unit"
      return
    fi
  done
  printf 'none\n'
}

# Default inbound policy, where it can be read without asking for a password.
#
# /etc/default/ufw is world-readable on both distributions the page covers, and
# it is the same value `ufw status verbose` prints. Everything else answers
# needs-root, which is an honest answer and not a failure.
linux_inbound_policy() {
  case "$1" in
    ufw)
      if [ -r /etc/default/ufw ]; then
        sed -n 's/^DEFAULT_INPUT_POLICY="\{0,1\}\([A-Z]*\)"\{0,1\}.*/\1/p' /etc/default/ufw |
          head -1 | tr '[:upper:]' '[:lower:]'
      else
        printf 'needs-root\n'
      fi
      ;;
    none) printf 'n/a\n' ;;
    *) printf 'needs-root\n' ;;
  esac
}

linux_guest_account() {
  if grep -qE '^guest:' /etc/passwd 2>/dev/null; then
    printf 'present\n'
  else
    printf 'absent\n'
  fi
}

# Whether anything is set up to install updates without being asked.
#
# Arch has no such mechanism and the page does not ask for one: the requirement
# is that updates happen, and on a rolling release that is a person running
# pacman. `manual` is the documented state there, not a shortfall.
linux_updates() {
  if systemctl is-enabled --quiet unattended-upgrades 2>/dev/null; then
    printf 'unattended-upgrades\n'
  elif systemctl is-enabled --quiet dnf-automatic.timer 2>/dev/null; then
    printf 'dnf-automatic\n'
  else
    printf 'manual\n'
  fi
}

linux_scanner() {
  if systemctl is-active --quiet clamav-daemon 2>/dev/null ||
    systemctl is-active --quiet clamav-freshclam 2>/dev/null; then
    printf 'clamav\n'
  elif have clamscan; then
    printf 'clamav-installed-not-running\n'
  else
    printf 'none\n'
  fi
}

# --- macOS --------------------------------------------------------------------

macos_disk_encryption() {
  case "$(fdesetup status 2>/dev/null)" in
    *"FileVault is On"*) printf 'yes\n' ;;
    *"FileVault is Off"*) printf 'no\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

macos_firewall() {
  case "$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)" in
    *enabled*) printf 'application-firewall\n' ;;
    *disabled*) printf 'none\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

macos_guest_account() {
  case "$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null)" in
    1) printf 'present\n' ;;
    0) printf 'absent\n' ;;
    *) printf 'absent\n' ;;
  esac
}

macos_updates() {
  case "$(softwareupdate --schedule 2>/dev/null)" in
    *on*) printf 'automatic\n' ;;
    *off*) printf 'manual\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

main() {
  parse_common_args "$@"
  evidence_open policy

  _os=$(detect_os)
  _hostname=$(hostname_shape)

  if [ "$_os" = macos ]; then
    _encrypted=$(macos_disk_encryption)
    _firewall=$(macos_firewall)
    _policy=n/a
    _guest=$(macos_guest_account)
    _updates=$(macos_updates)
    # XProtect is part of the system and cannot be turned off, which is what
    # the page says. There is no state to read.
    _scanner=xprotect

    fdesetup status 2>&1 | evidence disk-encryption
    /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1 | evidence firewall
    softwareupdate --schedule 2>&1 | evidence updates
  else
    _encrypted=$(linux_disk_encryption)
    _firewall=$(linux_firewall)
    _policy=$(linux_inbound_policy "$_firewall")
    _guest=$(linux_guest_account)
    _updates=$(linux_updates)
    _scanner=$(linux_scanner)

    # The block device tree, with no mount points: those carry usernames.
    lsblk -o NAME,TYPE,FSTYPE,SIZE 2>&1 | evidence disk-encryption
    {
      printf 'active firewall unit: %s\n\n' "$_firewall"
      [ -r /etc/default/ufw ] && cat /etc/default/ufw
    } 2>&1 | evidence firewall
  fi

  # Only the things the page states as requirements, and only where this could
  # actually see them. `unknown` and `needs-root` are neither pass nor fail.
  _attention=0
  [ "$_encrypted" = no ] && _attention=1
  [ "$_firewall" = none ] && _attention=1
  [ "$_policy" = allow ] && _attention=1
  [ "$_guest" = present ] && _attention=1

  _status=ok
  [ "$_attention" = 1 ] && _status=attention

  # Built once, whoever asked for it. --json prints it, --report puts it in the
  # form, and both are the same observation so they cannot disagree.
  #
  # The hostname is a shape, never a name: see INVENTORY_PATTERN above.
  _json=$(json_result "$_status" "device settings" \
    "disk_encryption=$_encrypted" "firewall=$_firewall" "inbound_policy=$_policy" \
    "guest_account=$_guest" "updates=$_updates" "scanner=$_scanner" \
    "hostname_shape=$_hostname" "os=$_os" | redact)

  if [ "$JSON" = "1" ]; then
    printf '%s\n' "$_json"
    evidence_close
    return 0
  fi

  log "Disk encryption:       ${_encrypted}"
  log "Firewall running:      ${_firewall}"
  log "Default inbound:       ${_policy}"
  log "Guest account:         ${_guest}"
  log "Updates:               ${_updates}"
  log "Virus scanner:         ${_scanner}"
  log "Hostname:              ${_hostname}"

  log ""
  log "Nothing here is a verdict. The requirements are a list somebody else"
  log "wrote and this only says what is currently set."

  if [ "$_hostname" != inventory-format ]; then
    log ""
    log "The hostname does not look like an inventory number. That is expected on"
    log "a personal machine and is the requirement on a university one. This"
    log "never prints or records the name itself."
  fi
  if [ "$_policy" = needs-root ]; then
    log ""
    log "The default inbound policy needs root to read. The page's own command is"
    log "  sudo ufw status verbose"
  fi

  # After the advice, not instead of it: a report of what did not work is worth
  # filing too, and it is the report the page most needs.
  #
  # `attention` is a state of this machine, not a fault in the page, so the page
  # can still have worked exactly as written.
  [ "$REPORT" = "1" ] && print_report "$REPORT_PAGE" "$(report_outcome ok)" "$_json"
  evidence_close

  # Always zero, unlike every other check here. The others exit non-zero when
  # the thing the page sets up is not working. This one has nothing to set up:
  # a non-zero exit would be this repository telling somebody their machine
  # fails a policy, which it has no standing to say and no way to know.
  return 0
}


# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-verify.sh.
case "${0##*/}" in
  *verify.sh) main "$@" ;;
esac
