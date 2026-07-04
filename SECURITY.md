# Security Policy

## Supported Versions

Security fixes are handled on the latest release only.

## Reporting a Vulnerability

Please do not open a public issue for a security report.

Email the maintainer at the address listed on the GitHub profile, or open a private security advisory from the repository's Security tab if it is available.

Include:

- A concise description of the issue
- Steps to reproduce
- The affected macOS version
- The affected Rounder version
- Any logs, screenshots, or proof-of-concept details that help confirm the problem

## App Permissions

Rounder does not request Accessibility, Screen Recording, Automation, Contacts, Location, Microphone, Camera, or network permissions. It draws local overlay windows and stores settings locally in `UserDefaults`.

Release builds are currently unsigned with a paid Developer ID. macOS may show a Gatekeeper warning on first launch.

