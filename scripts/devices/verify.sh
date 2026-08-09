#!/usr/bin/env sh
# Check what an HDMI output is doing, before the lecture rather than during it.
#
# Usage:
#   ./verify.sh           readable
#   ./verify.sh --json    machine-readable, identifiers stripped
#   ./verify.sh --evidence  write down everything it saw, for debugging later
#
# The page's own verification is a human one and stays that way: put a black
# area and a white area on screen and look at the projector. Nothing here can
# see the wall. What it can do is answer the three questions that decide
# whether the fix on the page is even available, in the ten seconds before a
# lecture: is this a Wayland session, is anything connected, and does the
# output carry the Broadcast RGB property at all.
#
# Read-only. It changes no display setting; the page's command does that, and
# doing it here would reconfigure a screen somebody is presenting on.
set -eu

DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/common.sh
. "$DIR/../lib/common.sh"
# shellcheck source=../lib/facts.sh
. "$DIR/../lib/facts.sh"

# The page these checks belong to, for --report.
REPORT_PAGE=/en/devices/projectors

# What the kernel calls an external video connector. Anything else on the list
# is the built-in panel or a virtual output, and neither goes to a projector.
external_connectors() {
  [ -d /sys/class/drm ] || return 0
  for _path in /sys/class/drm/card*-*; do
    [ -r "$_path/status" ] || continue
    _name=${_path##*/}
    _name=${_name#card*-}
    case "$_name" in
      HDMI* | DP-* | DisplayPort* | USB-C*) ;;
      *) continue ;;
    esac
    printf '%s %s\n' "$_name" "$(cat "$_path/status")"
  done
}

connected_external() {
  external_connectors | awk '$2 == "connected" {print $1}'
}

session_type() {
  if [ -n "${WAYLAND_DISPLAY:-}" ] || [ "${XDG_SESSION_TYPE:-}" = wayland ]; then
    printf 'wayland\n'
  elif [ -n "${DISPLAY:-}" ]; then
    printf 'x11\n'
  else
    printf 'none\n'
  fi
}

# The property the page's fix sets, and what it is currently set to.
#
# Only reachable through xrandr, and only in an X session. That is the whole
# reason the page tells Wayland users to switch sessions, so reporting it as
# missing on Wayland would describe a driver problem that is not there.
broadcast_rgb() {
  have xrandr || {
    printf 'no-xrandr\n'
    return
  }
  _props=$(xrandr --props 2>/dev/null) || {
    printf 'unreadable\n'
    return
  }
  printf '%s\n' "$_props" |
    awk '
      /^[^ \t]/ { output = $1 }
      /Broadcast RGB:/ { getline value; gsub(/^[ \t]+|[ \t]+$/, "", value); print output " " value }
    '
}

main() {
  parse_common_args "$@"
  evidence_open devices

  _os=$(detect_os)

  if [ "$_os" = macos ]; then
    log "macOS negotiates the range itself and exposes no control for it."
    log "The page says so; there is no setting here to read."
    log ""
    system_profiler SPDisplaysDataType 2>/dev/null | sed 's/^/  /' || true
    system_profiler SPDisplaysDataType 2>&1 | evidence displays

    _json=$(json_result incomplete "display check" \
      "reason=no_control_on_macos" "os=macos" | redact)
    [ "$JSON" = "1" ] && printf '%s\n' "$_json"
    evidence_close
    exit 0
  fi

  _session=$(session_type)
  _connected=$(connected_external | tr '\n' ' ' | sed 's/ *$//')
  _count=$(connected_external | grep -c . || true)

  _rgb=unavailable
  _rgb_output=none
  if [ "$_session" = x11 ]; then
    _line=$(broadcast_rgb | head -1)
    if [ -n "$_line" ]; then
      _rgb_output=${_line%% *}
      _rgb=${_line#* }
    else
      _rgb=absent
    fi
  fi

  {
    printf 'session: %s\n\n' "$_session"
    printf 'connectors:\n'
    external_connectors | sed 's/^/  /'
    printf '\n'
    if [ "$_session" = x11 ] && have xrandr; then
      printf 'xrandr --props:\n'
      xrandr --props 2>&1
    fi
  } | evidence displays

  _status=ok
  [ "$_count" -eq 0 ] && _status=nothing-connected
  [ "$_session" = wayland ] && [ "$_count" -gt 0 ] && _status=unreachable
  [ "$_rgb" = absent ] && _status=unreachable

  # Built once, whoever asked for it. --json prints it, --report puts it in the
  # form, and both are the same observation so they cannot disagree.
  _json=$(json_result "$_status" "display check" \
    "session=$_session" "external_connected=$_count" "connectors=$_connected" \
    "broadcast_rgb=$_rgb" "broadcast_rgb_output=$_rgb_output" "os=$_os" | redact)

  if [ "$JSON" = "1" ]; then
    printf '%s\n' "$_json"
    evidence_close
    return 0
  fi

  log "Session:               ${_session}"
  log "External connectors:"
  external_connectors | sed 's/^/  /'
  if [ "$_rgb_output" = none ]; then
    log "Broadcast RGB:         ${_rgb}"
  else
    log "Broadcast RGB:         ${_rgb}  (${_rgb_output})"
  fi

  if [ "$_count" -eq 0 ]; then
    log ""
    log "Nothing external is connected, so there is no output to look at. Plug the"
    log "cable in and run this again."
  elif [ "$_session" = wayland ]; then
    log ""
    log "This is a Wayland session, and the setting the page describes cannot be"
    log "reached from one. An X session for the lecture is the reliable answer."
  elif [ "$_rgb" = absent ]; then
    log ""
    log "The output carries no Broadcast RGB property, so this driver offers no"
    log "user-facing control over the range. The page says this happens."
  elif [ "$_rgb" != Full ]; then
    log ""
    log "The range is not Full. That is the setting behind washed-out colours, and"
    log "the page has the command. Look at the projector afterwards: this can read"
    log "the setting and cannot see the wall."
  fi

  # After the advice, not instead of it: a report of what did not work is worth
  # filing too, and it is the report the page most needs.
  #
  # Never a prefilled outcome from a clean read: whether the picture is right is
  # something only the person looking at it can say (AGENTS.md rule 5).
  [ "$REPORT" = "1" ] && print_report "$REPORT_PAGE" "" "$_json"
  evidence_close
}


# Entry point. Guarded so tests can source this file and call individual
# functions; the glob also matches the standalone build, which is named
# <domain>-verify.sh.
case "${0##*/}" in
  *verify.sh) main "$@" ;;
esac
