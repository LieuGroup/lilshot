# lilshot — App identity + capture surface (third milestone)

Two rounds. Assets already exist (do NOT regenerate): `brand/appicon/lilshot.icns`,
`assets/menubar-icon.png` + `assets/menubar-icon@2x.png` (black + alpha, for template rendering),
`brand/logo/logo-lilshot.svg`.

## Round A — identity + re-capture-last

1. **Menu bar icon**: replace the SF Symbol placeholder with the bundled template image
   (`menubar-icon.png`/`@2x`). Declare `assets/` as SwiftPM resources for the `LilshotApp` target,
   load via `Bundle.module`, set `isTemplate = true` (adapts to light/dark menu bar and highlight).
2. **App bundle script** `scripts/make-app.sh` (bash, executable, set -euo pipefail):
   `swift build -c release` → assemble `dist/lilshot.app` (Contents/MacOS/lilshot-app binary,
   Contents/Resources/lilshot.icns + asset PNGs, Info.plist) → `codesign --force --deep -s -`
   (ad-hoc). Info.plist keys: CFBundleIdentifier `com.lilgroup.lilshot`, CFBundleName lilshot,
   CFBundleShortVersionString 0.1.0, CFBundleIconFile lilshot.icns, LSUIElement true,
   LSMinimumSystemVersion 14.0, NSHighResolutionCapable true. The app must still work via plain
   `swift run LilshotApp` (Bundle.module resource loading must not depend on the .app bundle).
3. **Re-capture-last hotkey ⌥⇧R**: after any successful picker capture, remember the windowID +
   app name. ⌥⇧R re-captures that window straight to the clipboard (no picker). If the window no
   longer exists, show nothing fancy — post a user notification-free fallback: just re-open the
   picker. Core logic (LastCaptureStore or equivalent: set/get/clear, survives only in-memory) is
   TDD'd; hotkey wiring mirrors HotkeyMonitor's existing pattern.

## Round B — capture surface (after A ships)

- Fullscreen capture hotkey (all displays' main display for now) → clipboard.
- Region capture ⌥⇧A: full-screen transparent overlay window, crosshair drag to select rect,
  Esc cancels; capture the region at 2x → clipboard. Overlay per-display can start main-display-only.
- Both reuse WindowCapturing/SCK adapters (SCContentFilter display-based) — extend protocols in
  core with TDD where logic exists (rect normalization, display mapping decisions).

## Acceptance (both rounds)

- swift test green, release build clean, `bash scripts/make-app.sh` produces a launchable
  `dist/lilshot.app` (verify: `open dist/lilshot.app` runs, menu bar icon shows the Lil Lil
  silhouette, Finder shows the dog app icon).
- `dist/` gitignored. Conventional commits, no AI refs, dead-code cleanup, files < ~200 lines.
- No plan references in code/comments/tests/commits.
