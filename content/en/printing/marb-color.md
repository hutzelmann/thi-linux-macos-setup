---
title: Printing on ${facts.printing.queue}
description: Set up the ${facts.printing.model} colour queue on Arch, Debian and macOS, and the lp recipes for duplex, punching, stapling and labels.
status: structured
os: [arch, debian, macos]
---

# Printing on ${facts.printing.queue}

Gets you printing to the ${facts.printing.model} in building MARB from Linux or
macOS, including double-sided, hole-punched and stapled output.

Official documentation: [THI printing service](${facts.printing.official_url}) ·
[knowledge base: printing](${facts.official.kb_url}/8-drucken). Account or
quota problems belong there, not here.

## Two things that surprise everyone

**Jobs do not print until you release them at the device.** Send the job, walk to the
machine, authenticate with your campus card, then pick the job. A queue that looks
"finished" on your laptop is normal and does not mean the job was lost.

**You do not need a driver at all if you are in a hurry.** [${facts.printing.webprint_url}](${facts.printing.webprint_url})
takes a PDF in the browser and prints it. No CUPS, no PPD, no SMB. You lose the
finishing options (punch, staple, jog), which is the only reason the rest of this page
exists.

## Documented values

| | |
|---|---|
| Print server | `${facts.printing.server}` |
| Queue | `${facts.printing.queue}` |
| Device | ${facts.printing.model} |
| SMB domain | `${facts.printing.smb_domain}` |
| Username | your campus login (`<kennung>`) |

The server was renamed from `${facts.printing.server_previous}`. Old notes and working
configurations still carry the previous name; it is the most common reason a setup that
worked last year stopped.

## Install the driver

The vendor ships one tarball for all models, roughly 250 MB, from the
[Kyocera download page](${facts.printing.driver_url}). There is no stable direct link,
so this step is manual on every OS.

::: os arch

```bash
sudo pacman -S cups smbclient system-config-printer
sudo systemctl enable --now cups
```

The PPD comes from the AUR package
[`kyocera-cups`](https://aur.archlinux.org/packages/kyocera-cups), or from the vendor
tarball if you prefer not to build from the AUR. Background:
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

Enter the server as `smb://${facts.printing.server}/${facts.printing.queue}` and select
the ${facts.printing.model} driver rather than "Generic PostScript".

:::

## Add the queue

::: os arch

```bash
sudo lpadmin -p ${facts.printing.queue} -E \
  -v "smb://${facts.printing.server}/${facts.printing.queue}" \
  -m "${facts.printing.ppd_model}"
```

:::

::: os debian

```bash
sudo lpadmin -p ${facts.printing.queue} -E \
  -v "smb://${facts.printing.server}/${facts.printing.queue}" \
  -m "${facts.printing.ppd_path}"
```

If that is rejected, use the CUPS model name instead of the absolute path. Which form
works varies between CUPS builds:

```bash
sudo lpadmin -p ${facts.printing.queue} -E \
  -v "smb://${facts.printing.server}/${facts.printing.queue}" \
  -m "${facts.printing.ppd_model}"
```

:::

::: os macos

Adding the printer in System Settings does this for you. To script it:

```bash
sudo lpadmin -p ${facts.printing.queue} -E \
  -v "smb://${facts.printing.server}/${facts.printing.queue}" \
  -m "${facts.printing.ppd_model}"
```

:::

Or run the script, which carries the values above and falls back between the two PPD
forms automatically:

<ScriptDownload file="printing-install.sh" does="Adds the queue to CUPS, trying both PPD forms" sudo />

At the first print job CUPS asks for credentials. Username is your campus login, domain
is `${facts.printing.smb_domain}`. If the dialogue has no separate domain field, combine
them: `${facts.printing.smb_domain}\<kennung>`.

## Verify

```bash
lpstat -p ${facts.printing.queue}
lpoptions -p ${facts.printing.queue} -l
```

The second command must list `Pnch` and `Stpl`. If it does not, the vendor PPD is not
in use and every finishing option below will be rejected.

The device is fitted with an inserter and a punch unit. A folding unit may or may not
be installed. If an option is missing from `lpoptions`, the corresponding hardware is
not configured on the device or not present in the PPD.

<ScriptDownload file="printing-verify.sh" does="Checks the queue, the server and the finishing options" />

## Recipes

Plain A4, single and double sided:

```bash
lp -d ${facts.printing.queue} -o media=A4 file.pdf
lp -d ${facts.printing.queue} -o media=A4 -o sides=two-sided-long-edge file.pdf
```

Hole-punched, and the exam-printing combination (double sided, punched, stapled at the
rear, 25 copies):

```bash
lp -d ${facts.printing.queue} -o media=A4 -o Pnch=2HoleEUR file.pdf

lp -d ${facts.printing.queue} -n 25 -o media=A4 -o sides=two-sided-long-edge \
   -o Pnch=2HoleEUR -o Stpl=Rear exam.pdf
```

`Stpl=Rear` is the usual position. `Stpl=Front` staples at the bottom of the page.

A4 content scaled onto A3:

```bash
lp -d ${facts.printing.queue} -o media=A3 -o fit-to-page \
   -o sides=two-sided-long-edge -o Pnch=2HoleEUR -o Stpl=Front p001.pdf
```

Labels, fed from the manual tray on the right with the labels facing down:

```bash
lp -d ${facts.printing.queue} -o media=A4 -o InputSlot=MF1 -o MediaType=Labels labels.pdf
```

Many documents at once, each offset in the output tray so you can separate them:

```bash
for p in *.pdf; do
  lp -d ${facts.printing.queue} -o media=A4 -o sides=two-sided-long-edge \
     -o Pnch=2HoleEUR -o Sep="Jog" "$p"
  sleep 1
done
```

Higher-quality halftoning for documents with barcodes or fine line art:

```bash
lp -d ${facts.printing.queue} -o media=A4 -o KSCREENMODE="Resolution" scan.pdf
```

Run `lpoptions -p ${facts.printing.queue} -l` for the full option list. The PPD exposes
trapping, overprint, colour model, gloss mode and resolution beyond what is shown here.

## Known quirks

**A glob does not work as a batch.** `lp -d ${facts.printing.queue} ... *.pdf` silently
does not do what it looks like. Use a `for` loop.

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
job with your card. Jobs expire after a while unreleased.
