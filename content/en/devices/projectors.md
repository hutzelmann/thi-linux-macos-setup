---
title: Projectors and external screens
description: Fixing washed-out colours over HDMI in lecture halls, and what to check before a lecture.
status: structured
os: [arch, debian, macos]
---

# Projectors and external screens

Covers the failure that shows up five minutes before a lecture: the projector works, but
everything looks wrong.

## Washed-out colours over HDMI

Colours look faded, blacks look grey, and the laptop's own screen is fine. It often looks
correct at a lower resolution, which sends people hunting for a resolution problem.

It is not a resolution problem. The graphics driver is sending a **limited RGB range**
(16–235, the television convention) while the projector expects **full range** (0–255), so
the whole picture loses contrast.

::: os arch

```bash
xrandr --output HDMI1 --set "Broadcast RGB" "Full"
```

Get the real output name from `xrandr` on its own — it varies (`HDMI1`, `HDMI-1`,
`HDMI-A-0`). If nothing changes, unplug and replug the cable: the setting applies at the
next link training.

**On Wayland this does not work.** `xrandr` cannot reach the setting. On Intel graphics
the equivalent is the kernel parameter
`video=HDMI-A-1:D` combined with driver-specific options; on other drivers there may be no
user-facing control at all. Switching to an X session for the lecture is the reliable
answer, unsatisfying as it is.

:::

::: os debian

```bash
xrandr --output HDMI-1 --set "Broadcast RGB" "Full"
```

Get the real output name from `xrandr` on its own — it varies (`HDMI1`, `HDMI-1`,
`HDMI-A-0`). If nothing changes, unplug and replug the cable.

On Wayland sessions the setting is not reachable this way; an X session is the reliable
workaround.

:::

::: os macos

macOS negotiates the range itself and usually gets it right. When it does not, the control
is not exposed in System Settings — a display override profile is the usual workaround,
and it is fiddly enough that borrowing a different cable or adapter first is worth trying.

:::

Background: [the askubuntu answer describing the same
fix](https://askubuntu.com/a/640153).

## Verify

Show something with a large black area and a large white area — a terminal on one side, a
white document on the other. Correct full-range output gives you an actual black, not
dark grey.

## Known quirks

**USB-C docks add their own failure.** Some docks negotiate a lower link rate and silently
drop to a lower refresh or resolution. If the picture is fine over plain HDMI and wrong
through the dock, the dock is the variable.

**Mirroring vs extending changes the negotiated mode.** A resolution that works extended
may not be offered mirrored, and lecture halls generally want mirrored.

**Room-specific behaviour is not documented here.** AV equipment differs between buildings
and this page has one fix in it. If you work out what a particular room needs, that is
worth adding.
