---
title: Projectors and external screens
description: Fixing washed-out colours over HDMI in lecture halls.
status: imported
os: [arch, debian, macos]
---

# Projectors and external screens

## Washed-out colours over HDMI

Colours look faded and blacks look grey on the projector, while the laptop screen is
fine. Often works correctly at a lower resolution, which makes it look like a resolution
problem. It is not.

The cause is the RGB range: the graphics driver sends a limited range (16–235) while the
projector expects full range (0–255), so the picture loses contrast.

::: os arch

```bash
xrandr --output HDMI1 --set "Broadcast RGB" "Full"
```

Replace `HDMI1` with the output name from `xrandr` on its own. If nothing changes,
unplug and replug the HDMI cable — the setting applies on the next link training.

Wayland sessions do not expose this through `xrandr`. On Intel graphics the equivalent
is a kernel parameter; on others there may be no user-facing control.

:::

::: os debian

```bash
xrandr --output HDMI-1 --set "Broadcast RGB" "Full"
```

Replace `HDMI-1` with the output name from `xrandr` on its own. If nothing changes,
unplug and replug the HDMI cable.

:::

::: os macos

macOS negotiates the range automatically and usually gets it right. When it does not,
the setting is not exposed in System Settings; a display-override profile is the usual
workaround.

:::

Background: [askubuntu answer describing the same fix](https://askubuntu.com/a/640153).

---

::: info Imported notes
A single fix carried over from personal notes. Lecture-hall AV varies by building and
nothing else here is documented yet — room-specific findings are welcome.
:::
