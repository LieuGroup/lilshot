# lilshot — Core + CLI (first buildable milestone)

Strategy: CLI-first. The CLI is dogfoodable immediately, is the agent-integration story, and forces
clean separation between pure logic (`LilshotCore`, fully tested) and thin OS adapters. The GUI
menu-bar app comes in a later milestone on top of the same core.

Validated by spike (`spikes/sck-window-capture/findings.md`): SCK captures occluded / other-Space /
minimized windows without focusing them. Gotchas: NSApplication.shared touch required before
SCScreenshotManager in CLI; `isOnScreen` unreliable; TCC gate via CGPreflightScreenCaptureAccess.

## Deliverables

1. Git repo initialized, `.gitignore` (`.build/`, `.DS_Store`, `spikes/**/sck-spike`, `spikes/**/*.png`).
2. Swift Package `lilshot`, platform macOS 14+:
   - `LilshotCore` (library, pure logic, zero OS deps, 100% unit-tested, TDD)
   - `lilshot` (executable, thin SCK/ImageIO adapters + CLI)
   - `LilshotCoreTests`
   - Single dependency allowed: `apple/swift-argument-parser`.
3. Conventional commits at each logical milestone; `swift test` must pass before every commit.

## LilshotCore spec (TDD — failing tests first)

### `WindowInfo` (model)
`id: UInt32, appName: String, title: String, width: Int, height: Int, isOnScreen: Bool` — plus
protocol `WindowProviding` (`func windows() async throws -> [WindowInfo]`) and
`WindowCapturing` (`func captureImage(windowID: UInt32) async throws -> CGImage`) so core logic
and CLI flow are testable with mocks.

### `FuzzyMatcher`
`rank(query: String, in: [WindowInfo]) -> [ScoredWindow]`
- Case-insensitive, diacritic-insensitive (Vietnamese input must match ASCII titles and vice versa).
- Subsequence match against `appName` and `title` separately; a window matches if either matches.
- Scoring: appName match outweighs title match; bonuses for prefix match, word-boundary hits,
  consecutive-run length; ties broken by shorter target then lower id (deterministic).
- Empty/whitespace query → all windows, input order, score 0.
- Non-matching windows excluded.
- Test cases must cover: "chr" → Chrome; "grok" matching a Chrome window by title; query with
  Vietnamese diacritics; tie-break determinism; empty query; no-match → empty.

### `WindowNoiseFilter`
- Drop windows with width or height < 40.
- Drop windows whose appName is empty.
- Sort: offscreen-first (picker candidates), then appName, then id. (Do not trust `isOnScreen`
  beyond sorting — see spike findings.)

### `CaptureQueryResolver`
Given a raw CLI query and a `[WindowInfo]`:
- All-digits query → exact windowID (error if not found).
- Otherwise fuzzy rank → if exactly one top match or a clear winner (top score strictly greater
  than runner-up), return it; if ambiguous, return the ranked candidates so the CLI can print
  them and exit non-zero.

## CLI spec (`lilshot` executable)

- `lilshot list [--json]` — TCC gate first; table: id, onScreen, app, title, WxH (noise-filtered,
  sorted). `--json` emits a stable JSON array (agents consume this).
- `lilshot capture <query> [-o <path>]` — resolve via `CaptureQueryResolver`; capture via SCK
  (`SCContentFilter(desktopIndependentWindow:)` + `SCScreenshotManager`, retina 2x,
  `captureResolution = .best`, `showsCursor = false`); write PNG. Default path:
  `~/Desktop/lilshot-<app-slug>-<yyyyMMdd-HHmmss>.png`. Print the written path on success.
  Ambiguous query → print candidates to stderr, exit 2.
- Adapters live in the executable target, stay thin (no logic worth testing), and MUST touch
  `NSApplication.shared` on the main actor before capturing (spike gotcha #1).
- Real error messages on failure paths; never swallow errors.

## Acceptance

- `swift test` green; `swift build -c release` clean.
- `swift run lilshot list` prints real windows (if TCC blocks in your shell, note it and leave
  runtime verification to the orchestrator).
- No dead code, no unused parameters/imports (final cleanup pass before last commit).
- Files follow Swift convention (PascalCase, one main type per file), each under ~200 lines.
- Code, comments, test names, and commit messages must NOT reference this plan, phase numbers,
  or finding codes — comments explain invariants, not origins.

## Out of scope (later milestones)

GUI menu-bar app, picker UI, edit overlay, clipboard copy, OCR, history, Homebrew formula.
