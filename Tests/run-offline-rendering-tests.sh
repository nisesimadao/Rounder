#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
task_dir="$(mktemp -d "${TMPDIR:-/tmp}/rounder-offline-tests.XXXXXX")"
trap 'rm -rf "$task_dir"' EXIT
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
xcrun --sdk macosx swiftc -sdk "$sdk_path" -target "$(uname -m)-apple-macosx14.6" \
  Tests/OfflineRenderingTests.swift \
  Rounder/OverlayFrameClock.swift \
  Rounder/MenuBarBackgroundAppearance.swift \
  Rounder/FullscreenMenuTracking.swift \
  Rounder/OverlayAttachmentRestoration.swift \
  Rounder/FullscreenMenuCorners.swift \
  Rounder/DesktopTopCorners.swift \
  Rounder/DesktopSpaceMembership.swift \
  Rounder/NSScreen+DisplayInfo.swift \
  Rounder/CornerGeometry.swift \
  Rounder/CornerOverlayWindow.swift \
  Rounder/GamingGlow.swift \
  -o "$task_dir/rendering-tests"
"$task_dir/rendering-tests"
