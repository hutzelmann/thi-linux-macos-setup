---
title: Windows 11 Education in a virtual machine
description: Installing Windows 11 Education in a VM on Linux and macOS, in GNOME Boxes, virt-manager or UTM, keeping local administrator rights while joining the campus account.
os: [arch, debian, macos]
---

# Windows in a virtual machine

For the handful of programs with no version for your system. The goal is a VM where
**you** are the local administrator, that can still reach campus resources, the
[network shares](/en/shares/smb) and [printing](/en/printing/) among them, through your
university account.

## The mistake that costs you the machine

During Windows setup you are asked *"Let's set things up for your work or school"*.

**Do not enter your campus credentials there.** Doing so makes the VM a managed device
from the start and leaves you without a local administrator account, the one thing a VM
is for.

Instead choose **Sign-in options → Domain join** and create a local account with any name
and password that are not your campus credentials. Connect the campus account
afterwards, from inside Windows, once you already hold administrator rights.

## Get the image

1. [Azure Dev Tools for Teaching](${facts.official.service_url}softwareangebote/microsoft-imagine)
   ([direct](https://azureforeducation.microsoft.com/devtools)), sign in with campus
   credentials.
2. Search for "education" → **Azure Education | Overview** → *Free Software* → **Explore
   All** → search "Windows 11".
3. Download **Windows 11 Education**. Not the N edition; it ships without media codecs.
4. Note the licence key from the side panel; setup asks for it.

::: os macos

The catalogue image is x86-64, and an Apple Silicon Mac runs ARM64 Windows. Emulating the
x86-64 image is slow enough not to be worth doing, so on an M-series machine take the
ARM64 build instead: [CrystalFetch](https://github.com/TuringSoftware/CrystalFetch),
from UTM's authors, builds an ISO from Microsoft's own
[Windows 11 Arm64 download](https://www.microsoft.com/en-us/software-download/windows11arm64).

Whether the licence key from the education catalogue activates an ARM64 install is not
documented here. If you find out either way, please
[say so](https://github.com/${facts.project.repo}/issues/new?template=check-record.yml).

An Intel Mac takes the catalogue image as it is.

:::

## Prepare the VM

Reasonable starting size, whichever tool you use:

- 8–12 GB RAM
- 4 CPUs
- 128 GB storage

Windows 11 requires Secure Boot and a TPM. Setting both up properly is more work up
front, and it is what lets you connect the campus account later: the security policies do
not apply to a VM that bypassed the check.

::: os arch

GNOME Boxes for the short path, virt-manager when you want the firmware and the TPM under
your own hand:

```bash
sudo pacman -S gnome-boxes
# or
sudo pacman -S virt-manager qemu-full edk2-ovmf swtpm
```

[How to run Windows 11 in GNOME Boxes with UEFI and TPM2](https://www.ctrl.blog/entry/how-to-win11-in-gnome-boxes.html)
covers the firmware side. For a throwaway VM that never joins the campus account, the
faster route is registry keys during setup, then `setup.exe`:
[discussion and the exact keys](https://www.reddit.com/r/gnome/comments/q1wy49/install_windows_11_in_gnome_boxes/).

:::

::: os debian

GNOME Boxes for the short path, virt-manager when you want the firmware and the TPM under
your own hand:

```bash
sudo apt install gnome-boxes
# or
sudo apt install virt-manager qemu-system-x86 ovmf swtpm-tools
```

[How to run Windows 11 in GNOME Boxes with UEFI and TPM2](https://www.ctrl.blog/entry/how-to-win11-in-gnome-boxes.html)
covers the firmware side. For a throwaway VM that never joins the campus account, the
faster route is registry keys during setup, then `setup.exe`:
[discussion and the exact keys](https://www.reddit.com/r/gnome/comments/q1wy49/install_windows_11_in_gnome_boxes/).

:::

::: os macos

[UTM](https://docs.getutm.app/guides/windows/), which is free and open source. From
version 4.3 it switches on UEFI Secure Boot and a TPM 2.0 device for Windows guests
itself, so the firmware question above does not come up.

On Apple Silicon the guest is ARM64 Windows and runs virtualised rather than emulated,
which is the only combination fast enough to work with.

:::

## After installation

- Rename the machine to something meaningful, e.g. `<inventarnummer>-VM`.
- Run Windows Update before anything else.

Guest drivers, without which the VM is slow and the screen does not resize:

::: os arch

The [virtio drivers](https://github.com/virtio-win/virtio-win-pkg-scripts), installed
from inside Windows.

:::

::: os debian

The [virtio drivers](https://github.com/virtio-win/virtio-win-pkg-scripts), installed
from inside Windows.

:::

::: os macos

UTM's own [guest tools](https://docs.getutm.app/guest-support/windows/), which it can
mount into the running VM.

:::

## Connect the campus account

Only works if the VM satisfies the security requirements: Secure Boot and TPM
configured.

**Settings → Accounts → Add Work or School Account**, then your campus credentials. The
policies then apply, and several things happen in sequence:

- Windows Hello setup
- A password change
- BitLocker encryption, with a recovery key; save it outside the VM

Afterwards Microsoft applications can use the campus identity.

## Verify

Three things tell you the VM came out right:

1. **You are a local administrator.** `net localgroup administrators` in an elevated
   prompt lists your local account.
2. **Secure Boot and TPM are active**, if you plan to attach the campus account: run
   `msinfo32` and check *Secure Boot State: On*, and `tpm.msc` reports a ready TPM.
3. **The campus account attached cleanly.** Settings → Accounts shows it under *Access
   work or school*, and you still have your local administrator account alongside it.

If the third succeeded but the first now fails, the OOBE mistake above happened. The
fastest fix is reinstalling rather than unpicking it.

## Known quirks

**Setting up without a network connection** is sometimes needed to force a local account.
The Education image did not appear to require it, but if setup insists on a Microsoft
account, [the OOBE bypass](https://learn.microsoft.com/en-us/answers/questions/2350856/set-up-windows-11-without-internet-oobebypassnro)
is the usual route.

**BitLocker recovery keys must leave the VM.** A key stored only inside the machine it
unlocks is not a backup. Print it, or copy it to the host before you need it.

**Microsoft changes the setup flow often.** This page describes what worked at the time
of writing; if a step has moved, please
[report it](https://github.com/${facts.project.repo}/issues/new?template=check-record.yml).
