# Security Policy

## Supported versions

Security fixes are handled on the latest release only.

## Reporting a vulnerability

Please do not open a public issue for a security report.

Email the maintainer at the address listed on the GitHub profile, or open a private security advisory from the repository's Security tab if it is available.

Include:

- A concise description of the issue
- Steps to reproduce
- The affected macOS version
- The affected Rounder version
- Any logs, screenshots, or proof-of-concept details that help confirm the problem

## App permissions

Rounder does not request Accessibility, Screen Recording, Automation, Contacts, Location, Microphone, Camera, or network permissions. It draws local overlay windows, reads local display and window metadata, and stores settings in `UserDefaults`. It does not capture screen images.

Release builds are ad-hoc signed for packaging, but they are not Developer ID signed or notarized. macOS may therefore show a Gatekeeper warning on first launch.
