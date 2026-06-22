# Handoff

## 2026-06-20

### Built

- Added `scripts/release.sh` for shipping a friend-testable macOS build.
- The script builds a signed Release app, submits a zip to Apple's notary service, staples the app, creates a DMG, notarizes/staples the DMG, and runs Gatekeeper checks.

### Decisions

- `make ship` uses a Keychain notary profile named `SupremeShot` by default.
- The script does not store Apple credentials or secrets in the repo.
- The current Debug artifact is correctly Developer ID signed and hardened, but rejected by Gatekeeper because it is not notarized and carries Debug-only `get-task-allow`.

### Open Questions

- Create the local `notarytool` Keychain profile before running `make ship`.

### Next Slice

- Store Apple notary credentials, run `make ship`, then test the resulting DMG on a clean macOS account or friend's machine.

## 2026-06-20

### Built

- Replaced `Resources/Assets.xcassets/AppIcon.appiconset` PNGs with resized outputs from the new Icon Composer `1024x1024` export.
- Generated the required macOS app icon sizes: 16, 32, 64, 128, 256, 512, and 1024.

### Decisions

- Used the exported `Supreme Shot Icon-iOS-Default-1024@1x.png` as the source image because the `.icon` package is the editable Icon Composer source document, not the current app catalog format.
- Kept the existing `Contents.json` because it already maps the generated PNG sizes to the macOS app icon slots.

### Open Questions

- Confirm whether we should later migrate to a newer Icon Composer-native catalog format if this project moves fully to the latest Xcode/icon pipeline.

### Next Slice

- Build and relaunch, then verify the new icon in Settings > About, Finder, Dock, and the app switcher.

## 2026-06-20

### Built

- Updated the About tab credits from Kartik Labhshetwar to Court Kizer.
- Changed the About tab X link label to `Follow @bdoma on X` and its destination to `https://x.com/bdoma`.

### Decisions

- Left GitHub and updater repository URLs unchanged; this request only covered the visible credits and X profile link.

### Open Questions

- Confirm later whether repository/updater ownership should move away from `KartikLabhshetwar/better-shot`.

### Next Slice

- Reopen Settings > About after relaunch and verify the visible credit/link text.

## 2026-06-20

### Built

- Removed the leading icon from `Quit SupremeShot` in the menu bar popover.
- Added the supplied `2x` chevron PNG as `MenuIconChevron` and rendered it on the Recents row at `12.5x7pt`.
- Tightened the menu divider section height from 22pt to 17pt.
- Changed filled gray row hover from an opacity fade to a 20% darker fill.

### Decisions

- Kept the existing menu row icons untouched.
- Tinted the Recents chevron with the same 40% `#202020` treatment used by shortcut text.

### Open Questions

- Visually confirm whether 20% darker hover is too strong on the real menu panel.

### Next Slice

- Open the relaunched menu and compare Quit, Recents, divider spacing, and hover states against the latest reference.

## 2026-06-20

### Built

- Fixed intermittent 1x paste sizing when starting region capture from the global shortcut on Retina displays.
- The shortcut event tap now resolves the screen from the CGEvent mouse location before dispatching capture.
- `CaptureOrchestrator` now falls back to the current screen when no explicit screen is passed.
- Region pasteboard sizing now falls back to the main Retina display scale instead of treating cropped images as 1x when exact screen-size inference is impossible.

### Decisions

- Kept saved files full-resolution; this only affects the pasteboard image's logical display size.
- Menu-click captures and shortcut captures now use the same screen-aware scale path.

### Open Questions

- Verify on an actual non-Retina external display that unknown-screen captures still paste at the expected physical size.

### Next Slice

- Test `Command-Shift-4` repeatedly on the 16-inch Retina display and paste into Figma to confirm every region capture lands at 2x logical scale.

## 2026-06-20

### Built

- Renamed the native app identity to SupremeShot.
- Updated the Xcode project container to `SupremeShot.xcodeproj`, target/scheme/product names to `SupremeShot`, and Debug product to `SupremeShot Dev.app`.
- Updated bundle identifiers to `com.supremeshot.app` and `com.supremeshot.app.dev`.
- Renamed app entry files/types and entitlements to `SupremeShotApp`, `SupremeShotDelegate`, and `Resources/SupremeShot.entitlements`.
- Updated user-facing native app strings, logs, support directory names, temp update paths, and generated capture filename prefixes.

### Decisions

- Kept repository/download URLs that still point to `better-shot` because changing those without a repo/release migration would break updater and docs links.
- Kept `bettershot-landing` directory name because it is a separate web project folder, not the native app identity.

### Open Questions

- Confirm whether the GitHub repo slug, Homebrew cask, and landing site domain are also being renamed to SupremeShot.

### Next Slice

- Verify macOS permissions after the bundle ID change, because `com.supremeshot.app.dev` will be treated as a different app by Privacy & Security.

## 2026-06-20

### Built

- Redesigned the menu bar popover from column grids into a vertical row list matching the supplied Figma node.
- Added the seven Figma SVG menu icons to `Resources/Assets.xcassets` as template vector images.
- Preserved native actions for region/window capture, full-screen capture, OCR, recording submenu, recents submenu, settings, and quit.
- Updated the menu to the later Figma node with filled capture rows, a divider, and transparent Recents/Settings/Quit rows.

### Decisions

- Region and Window are represented by the single `Region or Window` row because region capture now supports Space-to-window selection.
- The Figma node had placeholder-looking repeated shortcuts for lower rows, so the implementation keeps SupremeShot's existing real shortcuts where applicable.
- Pick Color is no longer a top-level row because it is not present in the supplied Figma menu.

### Open Questions

- Confirm whether color picker should return as a row or stay shortcut/settings-only.

### Next Slice

- Relaunch `SupremeShot Dev.app` and visually compare the menu against the Figma reference on the target display.

## 2026-06-20

### Built

- Added display-aware Retina paste sizing for screenshot clipboard writes.
- Added a General > Capture toggle, `Paste screenshots at Retina size`, enabled by default.
- Centralized screenshot image pasteboard writes through `ScreenshotPasteboard`.

### Decisions

- Saved/exported image files stay full-resolution; only `NSImage` pasteboard logical size changes.
- Captures with a known originating `NSScreen` use that screen's backing scale.
- Unknown captures only infer 2x on exact screen-size matches; otherwise they preserve 1x to avoid shrinking non-Retina external screenshots.

### Open Questions

- Manual verification still needed on an actual 1x external display.

### Next Slice

- Paste a Retina capture and a non-Retina external-display capture into Figma to verify expected visual dimensions.

## 2026-06-20

### Built

- Updated the SupremeShot marketing version from 0.3.7 to 0.4.0 across release metadata and Xcode build settings.
- Replaced the menu bar status icon with the supplied `menu-icon.png` and `menu-icon@2x.png` assets.
- Fixed `make run` so it launches the Debug product, `SupremeShot Dev.app`.

### Decisions

- Left the build number at 10 because the request was only to change the displayed semantic version.

### Open Questions

- Decide whether the next release should also increment `CURRENT_PROJECT_VERSION`.

### Next Slice

- Rebuild the app and confirm the menu bar dropdown shows `Version 0.4.0`.
- Visually confirm the new camera icon in the macOS menu bar at both 1x and 2x display scales.

## 2026-06-19

### Built

- Region screenshots now use native interactive capture so Space toggles from area selection into window selection.
- Debug builds now launch as `SupremeShot Dev` with bundle ID `com.supremeshot.app.dev` and stable Developer ID signing.
- The menu bar popover no longer uses a top arrow, has room for its shadow, clamps to the screen edge, and highlights the status item while open.

### Decisions

- Kept the explicit Window menu item even though Region can now toggle into window capture.
- Kept OCR on the strict region-only capture path.
- Used the signed Debug app identity to reduce macOS permission churn while keeping it separate from the installed personal SupremeShot app.

### Open Questions

- Add a first-run permissions onboarding flow for Accessibility and Screen & System Audio Recording.
- Tune the menu bar popover shadow after visual review on the actual display.

### Next Slice

- Verify Region, Space-to-window, Window button, OCR, and the menu popover appearance in the relaunched `SupremeShot Dev.app`.
