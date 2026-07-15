# Spike findings: ScreenCaptureKit window capture (2026-07-15, macOS 26 / Darwin 25.5)

Question: can SCK enumerate + capture windows without bringing them to front?

## Results — all three scenarios PASS

| Scenario | Result |
|---|---|
| Occluded window (behind other windows) | Captured, full real pixels |
| Window on another Space/desktop | Captured, full real pixels (tested: 3440x1410 Chrome window → 6880x2820 retina PNG) |
| Minimized window (in Dock) | Captured, full real pixels, **not stale** (tested: Notes minimized via AppleScript, `isOnScreen=false`, content complete) |

Capture never focuses, raises, or switches Space. The picker's "preview = low-res real capture" design is fully viable.

## API notes

- Enumerate with `SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)` → includes occluded / other-Space / minimized windows.
- Capture with `SCContentFilter(desktopIndependentWindow:)` + `SCScreenshotManager.captureImage(contentFilter:configuration:)`.
- Set `SCStreamConfiguration.width/height = frame * 2` for retina; `captureResolution = .best`.

## Gotchas discovered

1. **`CGS_REQUIRE_INIT` crash in bare CLI**: `SCScreenshotManager` aborts (`Assertion failed: (did_initialize), CGInitialization.c`) in a process with no WindowServer connection. Fix: touch `NSApplication.shared` (MainActor) before capturing. Listing via `SCShareableContent` does NOT need this. Matters for the future lilshot CLI.
2. **`isOnScreen` is unreliable as a "which Space" signal**: the same window reported `false` in one fetch and `true` in a capture moments later. Treat it as a hint for sorting, not truth for UI badges; verifying Space membership needs another mechanism.
3. Windows < 40pt are mostly system noise (agents, overlays); filtering them keeps the list readable. App name comes from `owningApplication?.applicationName`; many legit windows have empty titles.
4. Screen Recording TCC gate: `CGPreflightScreenCaptureAccess()` / `CGRequestScreenCaptureAccess()` before any SCK call.

## Try it

```bash
swiftc -parse-as-library spikes/sck-window-capture/main.swift -o spikes/sck-window-capture/sck-spike
./spikes/sck-window-capture/sck-spike list                     # offscreen windows sorted first
./spikes/sck-window-capture/sck-spike capture <windowID> out.png
```
