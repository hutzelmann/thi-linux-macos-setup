# Security

## Reporting a problem with this project

Open a normal issue, or use GitHub's private vulnerability reporting if it should not be
public at first.

This is a documentation site with no accounts, no user data and no server side. The
realistic risk is different from a typical application: **a page that documents an
insecure configuration**. That is treated as a serious bug here, not a wording problem.

An example of what qualifies: a Wi-Fi page that omits the server-certificate check would
lead readers to a configuration where an impersonating access point can collect their
campus password. Report that the same way you would report a vulnerability.

## Never post credentials

Do not put passwords, tokens or private keys in an issue, a pull request or a log
excerpt. If you already did, change the credential first — deleting the comment is not
enough, because the content is already distributed.

## Reporting a problem with THI systems

Not here. Write to support@thi.de. This project is not affiliated with university IT,
cannot act on their systems, and cannot forward anything on your behalf.
