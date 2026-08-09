#!/usr/bin/env sh
# Check whether this machine can build the Windows VM the page describes.
#
# Usage:
#   ./verify.sh           readable
#   ./verify.sh --json    machine-readable, identifiers stripped
#   ./verify.sh --evidence  write down everything it saw, for debugging later
#
# The page's own verification runs inside Windows: msinfo32 for Secure Boot,
# tpm.msc for the TPM. That is the right check and it is hours away, after an
# installation. This is the check for the hour before: whether the host has
# what the guest will need, so a missing firmware package is found now rather
# than at the point where Windows refuses to install.
#
# Nothing is installed and nothing is started. Every answer is a file that
# exists or a flag the processor reports.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# The page these checks belong to, for --report.
REPORT_PAGE=/en/vm/windows

# Where the UEFI firmware lands, which is not the same place on the two
# distributions and has moved on both. A guest without it boots in legacy mode,
# and Windows 11 then refuses to install for a reason it does not explain.
OVMF_PATHS='
/usr/share/edk2/x64/OVMF_CODE.4m.fd
/usr/share/edk2/x64/OVMF_CODE.fd
/usr/share/edk2-ovmf/x64/OVMF_CODE.fd
/usr/share/OVMF/OVMF_CODE_4M.fd
/usr/share/OVMF/OVMF_CODE.fd
/usr/share/qemu/edk2-x86_64-code.fd
'

cpu_virtualisation() {
  if [ "$(detect_os)" = macos ]; then
    case "$(sysctl -n kern.hv_support 2>/dev/null)" in
      1) printf 'yes\n' ;;
      *) printf 'no\n' ;;
    esac
    return
  fi
  if grep -qE '^flags.*[[:space:]](vmx|svm)[[:space:]]' /proc/cpuinfo 2>/dev/null; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
}

# Present is not the same as usable: /dev/kvm exists on a machine whose user is
# in no group that may open it, and the failure then arrives much later as a
# virtual machine that runs without acceleration and is unusably slow.
kvm_access() {
  [ -e /dev/kvm ] || {
    printf 'absent\n'
    return
  }
  if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    printf 'usable\n'
  else
    printf 'not-permitted\n'
  fi
}

firmware() {
  for _path in $OVMF_PATHS; do
    [ -r "$_path" ] && {
      printf 'yes\n'
      return
    }
  done
  printf 'no\n'
}

first_present() {
  for _candidate in "$@"; do
    have "$_candidate" && {
      printf '%s\n' "$_candidate"
      return
    }
  done
  printf 'none\n'
}

# Free space where a virtual machine image normally goes, in whole gigabytes.
#
# Reported rather than compared against a number: the page recommends a size
# and this cannot know whether the reader means to thin-provision it, put it on
# an external disk, or accept less. The number is what they need to decide.
free_gb() {
  _dir=${1:-$HOME}
  df -Pk "$_dir" 2>/dev/null | awk 'NR==2 {printf "%d\n", $4 / 1048576}'
}

total_ram_gb() {
  if [ "$(detect_os)" = macos ]; then
    _bytes=$(sysctl -n hw.memsize 2>/dev/null) || _bytes=0
    printf '%d\n' $((_bytes / 1073741824))
    return
  fi
  awk '/^MemTotal:/ {printf "%d\n", $2 / 1048576}' /proc/meminfo 2>/dev/null
}

macos_utm() {
  if [ -d /Applications/UTM.app ]; then
    printf 'installed\n'
  else
    printf 'absent\n'
  fi
}

main() {
  parse_common_args "$@"
  evidence_open vm

  _os=$(detect_os)
  _virt=$(cpu_virtualisation)
  _ram=$(total_ram_gb)
  _free=$(free_gb)

  if [ "$_os" = macos ]; then
    _kvm=n/a
    _firmware=n/a
    _tpm=n/a
    _manager=$(macos_utm)
    _cpu=$(uname -m)

    sysctl -n kern.hv_support machdep.cpu.brand_string hw.memsize 2>&1 | evidence host
  else
    _kvm=$(kvm_access)
    _firmware=$(firmware)
    # swtpm is what gives the guest the TPM 2.0 device Windows 11 requires.
    # Without it the installation stops at a hardware requirements screen.
    _tpm=no
    have swtpm && _tpm=yes
    _manager=$(first_present virt-manager gnome-boxes virt-install)
    _cpu=$(uname -m)

    {
      printf 'kvm: %s\n' "$_kvm"
      printf 'firmware candidates found:\n'
      for _path in $OVMF_PATHS; do
        [ -r "$_path" ] && printf '  %s\n' "$_path"
      done
      printf 'groups: %s\n' "$(id -Gn 2>/dev/null)"
    } 2>&1 | evidence host
  fi

  _status=ok
  [ "$_virt" = yes ] || _status=unsupported
  [ "$_manager" = none ] && _status=incomplete
  if [ "$_os" != macos ]; then
    [ "$_kvm" = usable ] || _status=incomplete
    [ "$_firmware" = yes ] || _status=incomplete
    [ "$_tpm" = yes ] || _status=incomplete
  fi

  # Built once, whoever asked for it. --json prints it, --report puts it in the
  # form, and both are the same observation so they cannot disagree.
  _json=$(json_result "$_status" "vm host check" \
    "cpu=$_cpu" "virtualisation=$_virt" "kvm=$_kvm" "uefi_firmware=$_firmware" \
    "software_tpm=$_tpm" "manager=$_manager" "ram_gb=$_ram" "free_gb=$_free" \
    "os=$_os" | redact)

  if [ "$JSON" = "1" ]; then
    printf '%s\n' "$_json"
    evidence_close
    [ "$_status" = ok ] || exit 1
    return 0
  fi

  log "Processor:             ${_cpu}"
  log "Hardware acceleration: ${_virt}"
  [ "$_os" = macos ] || log "/dev/kvm:              ${_kvm}"
  [ "$_os" = macos ] || log "UEFI firmware:         ${_firmware}"
  [ "$_os" = macos ] || log "Software TPM:          ${_tpm}"
  log "Virtual machine tool:  ${_manager}"
  log "Memory:                ${_ram} GB total"
  log "Free space in home:    ${_free} GB"
  log ""
  log "The page says what to give the guest. Compare the two numbers above with"
  log "it; this deliberately does not decide for you."

  if [ "$_virt" = no ]; then
    log ""
    log "The processor reports no hardware acceleration. On a machine that has it,"
    log "this usually means it is switched off in the firmware settings."
  fi
  if [ "$_kvm" = not-permitted ]; then
    log ""
    log "/dev/kvm exists but this account cannot open it. Adding yourself to the"
    log "kvm group and logging in again is the usual answer. Without it the guest"
    log "runs without acceleration, which looks like a broken installation."
  fi
  if [ "$_firmware" = no ] || [ "$_tpm" = no ]; then
    log ""
    log "Secure Boot and a TPM are what Windows 11 checks for, and on Linux they"
    log "come from the UEFI firmware package and swtpm. The page names both for"
    log "your distribution. Without them the installer stops without saying why."
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
