# Contributing

Thanks for improving Rounder.

## Development Setup

Requirements:

- macOS 14.6 or later
- Xcode

Build from the command line:

```bash
xcodebuild -project Rounder.xcodeproj -scheme Rounder -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

Run the lightweight preset compatibility test:

```bash
swift Tests/PresetTests.swift
```

Validate localizations:

```bash
jq empty Rounder/Localizable.xcstrings
```

## Pull Requests

Before opening a PR:

- Keep changes focused.
- Include screenshots or a short screen recording for UI changes.
- Run the build command above.
- Run `swift Tests/PresetTests.swift` if preset serialization changed.
- Avoid committing local artifacts such as `tmp/`, DerivedData, `.DS_Store`, or exported PDFs.

## Release Notes

User-facing changes should update `CHANGELOG.md`.
