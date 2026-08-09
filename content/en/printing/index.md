---
title: Printing on campus from Linux and macOS
description: Add the ${facts.printing.queue} or ${facts.printing.queue_students} queue to CUPS on Arch, Debian and macOS, with the lp recipes for duplex, punching and stapling.
os: [arch, debian, macos]
---

# Printing

Gets you printing to the colour queues in building MARB from Linux or macOS, through CUPS, including
double-sided, hole-punched and stapled output. Two queues live on the same print server:
`${facts.printing.queue}` for staff and `${facts.printing.queue_students}` for students.
Everything below applies to both; only the queue name changes.

Official documentation: [THI printing service](${facts.printing.official_url}) ·
[knowledge base: printing](${facts.official.kb_url}/8-drucken). Account or
quota problems belong there, not here.

## Two things to know first

**Jobs do not print until you release them at the device.** Send the job, walk to the
machine, authenticate with your campus card, then pick the job. A queue that looks
"finished" on your laptop is normal and does not mean the job was lost.

**You do not need a driver at all if you are in a hurry.** [${facts.printing.webprint_url}](${facts.printing.webprint_url})
takes a PDF in the browser and prints it. No CUPS, no PPD, no SMB. You lose the
finishing options (punch, staple, jog), which is the only reason the rest of this page
exists.

## Documented values

| Setting | Staff | Students |
|---|---|---|
| Print server | `${facts.printing.server}` | `${facts.printing.server}` |
| Queue | `${facts.printing.queue}` | `${facts.printing.queue_students}` |
| Device | ${facts.printing.model} | not documented here |
| SMB domain | `${facts.printing.smb_domain}` | `${facts.printing.smb_domain}` |
| Username | your campus login (`<kennung>`) | your campus login (`<kennung>`) |

The queue is reached over SMB, the same protocol and the same campus login as the
[campus network shares](/en/shares/smb).

The server was renamed from `${facts.printing.server_previous}`. Old notes and working
configurations still carry the previous name; it is the most common reason a setup that
worked last year stopped.

The device model behind `${facts.printing.queue_students}` is not documented here, so the
driver section below assumes the same model as the staff queue. If the verify step does
not list `Pnch` and `Stpl` on the student queue, that assumption is wrong for your queue
and the finishing recipes will be rejected.

## Install the driver

The vendor ships one tarball for all models, roughly 250 MB, from the
[Kyocera download page](${facts.printing.driver_url}). There is no stable direct link,
so the download is a manual step on Debian and macOS. On Arch the AUR package wraps it.

::: os arch

```bash
sudo pacman -S cups smbclient system-config-printer
sudo systemctl enable --now cups
```

The PPDs come from the AUR package
[`${facts.printing.driver_aur}`](${facts.printing.driver_aur_url}), which covers the
TASKalfa line the ${facts.printing.model} belongs to. With an AUR helper that is one
line:

```bash
yay -S ${facts.printing.driver_aur}
```

Without a helper, `git clone https://aur.archlinux.org/${facts.printing.driver_aur}.git`
and run `makepkg -si` in it. Either way it is worth reading the PKGBUILD first, since
that is where it is decided whether the vendor archive is fetched during the build or
has to be placed beside it.

Unpacking the vendor tarball by hand works too, and is the route to take if you would
rather not build from the AUR. Background:
[ArchWiki: CUPS](https://wiki.archlinux.org/title/CUPS).

:::

::: os debian

```bash
sudo apt update
sudo apt install cups smbclient printer-driver-all system-config-printer
```

Then unpack the vendor tarball and install the EU variant. It carries the European
finishing options, including 2-hole punching:

```bash
tar -xzf KyoceraLinuxPackages-*.tar.gz
sudo dpkg -i KyoceraLinuxPackages-*/${facts.printing.driver_deb}
sudo apt -f install
```

This puts the PPD at `${facts.printing.ppd_path}`.

:::

::: os macos

Install the Kyocera macOS driver from the
[vendor download page](${facts.printing.driver_url}), then add the printer through
**System Settings → Printers & Scanners → Add Printer**. Choose the **Windows** tab (SMB)
rather than IP, since the queue is served over SMB.

Enter the server as `smb://${facts.printing.server}/` followed by your queue from the
table above, and select the ${facts.printing.model} driver rather than
"Generic PostScript".

:::

## Pick your queue

Every command from here on reads the queue from a shell variable, so the same recipe
works for staff and students. Set it once per terminal session:

```bash
# Staff
QUEUE=${facts.printing.queue}

# Students
QUEUE=${facts.printing.queue_students}
```

A new terminal starts without it. If a command reports an empty queue name, set `QUEUE`
again.

## Add the queue

::: os arch

```bash
sudo lpadmin -p "$QUEUE" -E \
  -v "smb://${facts.printing.server}/$QUEUE" \
  -m "${facts.printing.ppd_model}"
```

:::

::: os debian

```bash
sudo lpadmin -p "$QUEUE" -E \
  -v "smb://${facts.printing.server}/$QUEUE" \
  -m "${facts.printing.ppd_path}"
```

If that is rejected, use the CUPS model name instead of the absolute path. Which form
works varies between CUPS builds:

```bash
sudo lpadmin -p "$QUEUE" -E \
  -v "smb://${facts.printing.server}/$QUEUE" \
  -m "${facts.printing.ppd_model}"
```

:::

::: os macos

Adding the printer in System Settings does this for you. To script it:

```bash
sudo lpadmin -p "$QUEUE" -E \
  -v "smb://${facts.printing.server}/$QUEUE" \
  -m "${facts.printing.ppd_model}"
```

:::

Or run the script, which carries the values above and falls back between the two PPD
forms automatically. Without arguments it adds the staff queue; `--students` adds the
student queue instead:

<ScriptDownload file="printing-install.sh" does="Adds the staff queue to CUPS, or the student queue with --students, trying both PPD forms" sudo />

At the first print job CUPS asks for credentials. Username is your campus login, domain
is `${facts.printing.smb_domain}`. If the dialogue has no separate domain field, combine
them: `${facts.printing.smb_domain}\<kennung>`.

## Verify

```bash
lpstat -p "$QUEUE"
lpoptions -p "$QUEUE" -l
```

The second command must list `Pnch` and `Stpl`. If it does not, the vendor PPD is not
in use and every finishing option below will be rejected.

The device behind the staff queue is fitted with an inserter and a punch unit. A folding
unit may or may not be installed. If an option is missing from `lpoptions`, the
corresponding hardware is not configured on the device or not present in the PPD.

<ScriptDownload file="printing-verify.sh" does="Checks the queue, the server and the finishing options; pass --students for the student queue" />

## Recipes

Plain A4, single and double sided:

```bash
lp -d "$QUEUE" -o media=A4 file.pdf
lp -d "$QUEUE" -o media=A4 -o sides=two-sided-long-edge file.pdf
```

`-o KSCREENMODE="Resolution"` selects the finer halftone screen, which is what light grey
area fills and fine line art need (the grey grid behind an exam sheet, for example) to
come out as an even tone rather than a coarse pattern. It costs nothing on pages that do
not need it, so it is carried through every recipe below and can be dropped from any of
them.

Hole-punched:

```bash
lp -d "$QUEUE" -o media=A4 -o Pnch=2HoleEUR -o KSCREENMODE="Resolution" file.pdf
```

The exam-printing combination, double sided, punched, stapled at the rear, 25 copies:

```bash
lp -d "$QUEUE" -n 25 -o media=A4 -o sides=two-sided-long-edge \
   -o Pnch=2HoleEUR -o Stpl=Rear -o KSCREENMODE="Resolution" file.pdf
```

`Stpl=Rear` is the usual position. `Stpl=Front` staples at the bottom of the page.

A4 content scaled onto A3:

```bash
lp -d "$QUEUE" -o media=A3 -o fit-to-page -o sides=two-sided-long-edge \
   -o Pnch=2HoleEUR -o Stpl=Front -o KSCREENMODE="Resolution" file.pdf
```

Labels, fed from the manual tray on the right with the labels facing down:

```bash
lp -d "$QUEUE" -o media=A4 -o InputSlot=MF1 -o MediaType=Labels \
   -o KSCREENMODE="Resolution" file.pdf
```

Many documents at once, each offset in the output tray so you can separate them:

```bash
for p in *.pdf; do
  lp -d "$QUEUE" -o media=A4 -o sides=two-sided-long-edge \
     -o Pnch=2HoleEUR -o Sep="Jog" -o KSCREENMODE="Resolution" "$p"
  sleep 1
done
```

Run `lpoptions -p "$QUEUE" -l` for the full option list. The PPD exposes trapping,
overprint, colour model, gloss mode and resolution beyond what is shown here.

## Remove it again

Removing the queue is one command, and it is reversible: rerun the add step to get the
queue back.

```bash
sudo lpadmin -x "$QUEUE"
```

If you added both queues, remove them by name:

```bash
sudo lpadmin -x ${facts.printing.queue}
sudo lpadmin -x ${facts.printing.queue_students}
```

That also deletes the PPD copy CUPS made for the queue under `/etc/cups/ppd/`. Check
nothing is left:

```bash
lpstat -p    # the queue is no longer listed
lpstat -v    # no smb:// device points at the print server
```

The password you typed at the first job is not held by CUPS. It sits in your desktop
keyring (GNOME Keyring, KWallet) or, on macOS, in the login keychain, filed under the
print server name. Remove it there if you want it gone.

Then the driver, which is separate from the queue and is worth keeping if you print
elsewhere on the same model.

::: os arch

```bash
sudo pacman -Rns ${facts.printing.driver_aur}
```

Removing CUPS as well stops all printing on the machine, not only campus printing:

```bash
sudo systemctl disable --now cups
sudo pacman -Rns cups smbclient system-config-printer
```

:::

::: os debian

The package name depends on which variant of the vendor tarball you installed, so ask
`dpkg` which package owns the PPD rather than guessing:

```bash
dpkg -S ${facts.printing.ppd_path}
sudo apt purge <the package name from the line above>
```

If the PPD file is already gone and the package is not, `dpkg -l | grep -i kyo` finds it.
CUPS and the SMB client are ordinary Debian packages, and removing them takes all printing
with them:

```bash
sudo apt purge cups smbclient system-config-printer
```

:::

::: os macos

Remove the printer in **System Settings → Printers & Scanners**: select it, then use the
minus button. That is the same operation as the `lpadmin -x` above.

The driver installs under `/Library/Printers/`. Look before deleting, since printers you
set up yourself live in the same place:

```bash
ls /Library/Printers/
```

The vendor download ships an uninstaller. If you still have the disk image, that is the
vendor's own route and it removes the parts an `rm` would miss.

:::

An empty `/etc/samba/smb.conf`, if the install step created one, can stay. Other SMB
tooling expects the file to exist.

## Known quirks

**A glob does not work as a batch.** `lp -d "$QUEUE" ... *.pdf` silently does not do what
it looks like. Use a `for` loop.

**Rapid loops hit authentication delays.** Jobs submitted back-to-back can stall in SMB
authentication. A `sleep 1` between jobs avoids it. If jobs seem stuck, refresh the queue
in `system-config-printer` and retry.

**CUPS may need restarting twice** after adding the queue before the first job goes
through. Reported on Debian with KDE; harmless, if baffling.

**On KDE, the first job may need explicit authentication.** If it sits in the queue, open
the print queue, right-click the job and choose *Authentifizieren* (Authenticate).

**Missing `/etc/samba/smb.conf` breaks the SMB backend** on some systems. An empty file
is enough:

```bash
sudo mkdir -p /etc/samba && sudo touch /etc/samba/smb.conf
```

**Nothing comes out and the queue is empty.** Expected. Go to the device and release the
job with your card. Unreleased jobs expire after ${facts.printing.job_retention}.
