---
title: Windows in a virtual machine
description: Installing Windows 11 Education in a VM on Linux and keeping local administrator rights while joining the campus account.
status: imported
os: [arch, debian, macos]
---

# Windows in a virtual machine

For the handful of programs with no Linux equivalent. The goal is a VM where **you** are
the local administrator, that can still reach campus resources through your university
account.

## The mistake that costs you the machine

During Windows setup you are asked *"Let's set things up for your work or school"*.

**Do not enter your campus credentials there.** Doing so makes the VM a managed device
from the start and leaves you without a local administrator account — the one thing a VM
is for.

Instead choose **Sign-in options → Domain join** and create a local account with any name
and password that are not your campus credentials. Connect the campus account
afterwards, from inside Windows, once you already hold administrator rights.

## Get the image

1. [Azure Dev Tools for Teaching](https://www.thi.de/service/it-service/softwareangebote/microsoft-imagine)
   ([direct](https://azureforeducation.microsoft.com/devtools)), sign in with campus
   credentials.
2. Search for "education" → **Azure Education | Overview** → *Free Software* → **Explore
   All** → search "Windows 11".
3. Download **Windows 11 Education**. Not the N edition — it ships without media codecs.
4. Note the licence key from the side panel; setup asks for it.

## Prepare the VM

GNOME Boxes, virt-manager or UTM all work. Reasonable starting size:

- 8–12 GB RAM
- 4 CPUs
- 128 GB storage

Windows 11 requires Secure Boot and a TPM. Two routes:

**Configure TPM and Secure Boot properly.** More work up front, and required if you want
to connect the campus account later — the security policies will not apply otherwise.
[How to run Windows 11 in GNOME Boxes with UEFI and TPM2](https://www.ctrl.blog/entry/how-to-win11-in-gnome-boxes.html).

**Or bypass the check.** Faster, and fine for a throwaway VM: registry keys during setup,
then continue with `setup.exe`.
[Discussion and the exact keys](https://www.reddit.com/r/gnome/comments/q1wy49/install_windows_11_in_gnome_boxes/).

## After installation

- Install the [virtio drivers](https://github.com/virtio-win/virtio-win-pkg-scripts) for
  usable performance.
- Rename the machine to something meaningful, e.g. `<inventarnummer>-VM`.
- Run Windows Update before anything else.

## Connect the campus account

Only works if the VM satisfies the security requirements — Secure Boot and TPM
configured.

**Settings → Accounts → Add Work or School Account**, then your campus credentials. The
policies then apply, and several things happen in sequence:

- Windows Hello setup
- A password change
- BitLocker encryption, with a recovery key — save it outside the VM

Afterwards Microsoft applications can use the campus identity.

## Untested

Setting up [without a network
connection](https://learn.microsoft.com/en-us/answers/questions/2350856/set-up-windows-11-without-internet-oobebypassnro)
is sometimes needed to get a local account. The Education image did not appear to require
it.

---

::: info Imported notes
From personal notes, originally written in German and translated for this page. Not
re-checked against a current Windows 11 build; Microsoft changes the setup flow often.
:::
