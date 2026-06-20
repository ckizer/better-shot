# Handoff

## 2026-06-19

### Built

- Region screenshots now use native interactive capture so Space toggles from area selection into window selection.
- Debug builds now launch as `BetterShot Dev` with bundle ID `com.bettershot.app.dev` and stable Developer ID signing.
- The menu bar popover no longer uses a top arrow, has room for its shadow, clamps to the screen edge, and highlights the status item while open.

### Decisions

- Kept the explicit Window menu item even though Region can now toggle into window capture.
- Kept OCR on the strict region-only capture path.
- Used the signed Debug app identity to reduce macOS permission churn while keeping it separate from the installed personal BetterShot app.

### Open Questions

- Add a first-run permissions onboarding flow for Accessibility and Screen & System Audio Recording.
- Tune the menu bar popover shadow after visual review on the actual display.

### Next Slice

- Verify Region, Space-to-window, Window button, OCR, and the menu popover appearance in the relaunched `BetterShot Dev.app`.
