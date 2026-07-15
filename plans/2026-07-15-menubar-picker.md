# lilshot — Menu bar app + window picker (second milestone)

Builds on `LilshotCore` + CLI (done: fuzzy matcher, noise filter, query resolver, SCK adapters).
Killer feature: pick any window from a searchable list with a large live preview and capture it
WITHOUT bringing it forward — validated in `spikes/sck-window-capture/findings.md`.

## Deliverables

1. New executable target `LilshotApp` in Package.swift (AppKit + SwiftUI hybrid is fine; runs as
   bare executable via `swift run LilshotApp` with `NSApp.setActivationPolicy(.accessory)` — real
   .app bundling is a later milestone).
2. Status bar item (SF Symbol placeholder e.g. `camera.viewfinder`) with a small menu:
   "Pick window" (opens picker), "Quit".
3. Global hotkey ⌥⇧S (Carbon `RegisterEventHotKey`, hand-rolled, ~60 lines, no new deps) →
   toggles the picker panel.
4. Picker panel (floating NSPanel, centered, ~720x420):
   - Search field on top; typing re-ranks via `FuzzyMatcher` (empty query = all windows,
     noise-filtered, offscreen-first).
   - Left: window list (app name + title + size); ↑/↓ moves selection, wraps at ends.
   - Right: large preview of the SELECTED window, loaded lazily/async at ~0.5x scale; show a
     spinner/placeholder until loaded; cache previews by windowID for the panel's lifetime.
   - Enter: capture selected window full-res (2x retina) → write PNG to clipboard
     (`NSPasteboard`, PNG + TIFF representations) → close panel.
   - Esc: close panel without capturing.
5. Reuse `WindowProviding`/`WindowCapturing` protocols; the app must not talk to SCK directly
   outside the existing adapter types (move/share adapters so CLI and app reuse them —
   restructuring into a small `LilshotMac` target for shared adapters is acceptable if it keeps
   things lean).

## New core logic — TDD mandatory (LilshotCore, mock providers)

- `PickerViewModel`: holds query, filtered+ranked rows, selected index; operations:
  `setQuery`, `moveSelection(+1/-1)` (wrapping), `selectedWindow`. Pure, no AppKit imports.
- `PreviewLoadOrder`: given row order + selected index, yields load priority (selected first,
  then visible-range neighbors outward). Pure function, tested.
- UI layer stays thin; anything with a branch worth testing lives in core.

## Acceptance

- `swift test` green (existing 25 + new viewmodel tests); `swift build -c release` clean.
- `swift run LilshotApp` launches without crash; hotkey opens panel; typing filters; Enter puts
  a real PNG on the clipboard. (GUI runtime behavior that can't be verified headless: note it
  for the orchestrator instead of claiming it.)
- Dead-code cleanup pass before final commit; files < ~200 lines; conventional commits.
- No references to this plan in code/comments/tests/commits.

## Out of scope

Edit overlay/annotations, custom app icon, .app bundle + Info.plist, settings UI, configurable
hotkey, OCR, history, re-capture-last hotkey (next milestones).
