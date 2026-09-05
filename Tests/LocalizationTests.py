#!/usr/bin/env python3

import json
from pathlib import Path

CATALOG = Path(__file__).resolve().parents[1] / "Rounder" / "Localizable.xcstrings"
LANGUAGES = ("en", "ja")

# Product-critical strings that must never disappear even if Xcode's extraction
# metadata changes. The second pass below also checks every manually maintained
# catalog entry.
REQUIRED_KEYS = (
    # Menu panel
    "enable_rounded_corners",
    "corner_radius",
    "corner_shape",
    "corner_color",
    "pane_corners",
    "super_gaming_mode",
    "settings_menu",
    "quit_menu",
    "top_left_corner",
    "top_right_corner",
    "bottom_left_corner",
    "bottom_right_corner",
    "rounded_corner",
    "squircle_corner",
    "polygon_cutout",
    "color_black",
    "color_white",
    "color_gray",
    "state_on",
    "state_off",
    # Onboarding
    "welcome_to_rounder",
    "app_description",
    "app_utility_description",
    "screen_corner_rounding",
    "customizable_radius_color",
    "run_in_background",
    "basic_settings",
    "custom_color",
    "about_settings",
    "settings_change_instructions",
    "setup_complete",
    "setup_complete_message",
    "rounder_description",
    "launch_at_login",
    "background_operation_description",
    "back",
    "next",
    "start_rounder",
)


def validate_translation(key: str, entry: dict, failures: list[str]) -> None:
    localizations = entry.get("localizations", {})
    for language in LANGUAGES:
        unit = localizations.get(language, {}).get("stringUnit", {})
        value = unit.get("value", "")
        state = unit.get("state")
        if state != "translated" or not value.strip():
            failures.append(f"{key}: missing translated {language}")


def main() -> None:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    strings = data.get("strings", {})
    failures: list[str] = []

    for key in REQUIRED_KEYS:
        entry = strings.get(key)
        if entry is None:
            failures.append(f"missing key: {key}")
            continue
        validate_translation(key, entry, failures)

    manual_keys = {
        key
        for key, entry in strings.items()
        if entry.get("extractionState") == "manual"
    }

    for key in sorted(manual_keys - set(REQUIRED_KEYS)):
        validate_translation(key, strings[key], failures)

    if failures:
        raise SystemExit("Localization QA failed:\n- " + "\n- ".join(failures))

    print(
        "Localization QA passed: "
        f"{len(REQUIRED_KEYS)} critical keys + "
        f"{len(manual_keys)} manually maintained keys across "
        f"{len(LANGUAGES)} languages"
    )


if __name__ == "__main__":
    main()
