# Changelog

All notable changes to Rounder are tracked here.

## v2.2.0

- Replaced the classic status-item menu with an interactive SwiftUI control panel hosted inside a real `NSMenu`.
- Added live menu-bar controls for corner radius, Rounded / Squircle / Polygon shape, quick colors, individual corners, and Super Duper Gaming Mode.
- Added colored shape previews generated from the same corner geometry used by the real overlay.
- Fixed the rounded preview so off-window circle geometry is correctly clipped in the menu panel.
- Added lightweight in-place Radius / Shape updates so corner windows no longer need to be destroyed and recreated during slider/shape adjustments.
- Added shared `CornerGeometry` / `ScreenCorner` logic for initial creation, live resizing, menu previews, corner orientation, and Gaming hue mapping.
- Preserved Settings / Quit keyboard shortcuts and safe AppKit menu-tracking behavior.
- Added standalone CornerGeometry regression tests covering 0/20/40 px radii, Squircle 1.8× sizing, negative display coordinates, stable corner anchors, shape switching, and bounded rounded previews.
- Updated the release workflow to run CornerGeometry regression tests before packaging a release.

## v2.1.4

- Added tag-driven CI versioning so release builds match the pushed tag.
- Improved Space transition handling so overlays stay attached during desktop and fullscreen changes.
- Added unsigned release packaging through GitHub Actions.
- Added safer preset serialization and compatibility coverage for gaming glow settings.
- Improved preset deletion confirmation and unsaved-settings feedback.
- Fixed gaming-mode corner rendering so the cutouts glow with the screen edges.

## v2.1.3

- Fixed an issue where rounded corners could appear on only one side during Space transition animations.

## v2.1.2

- Improved overlay recovery when entering fullscreen Spaces.

## v2.1.1

- Version maintenance release.

