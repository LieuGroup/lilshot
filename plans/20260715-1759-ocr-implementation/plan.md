# OCR implementation plan

## Overview

- Goal: add ordered Vision OCR to Core/Mac, editor copy-text, region OCR hotkey, and CLI OCR without changing existing image-capture behavior.
- Architecture follows existing split: deterministic assembly in `LilshotCore`; Vision in `LilshotMac`; clipboard/UI orchestration in `LilshotApp`; thin ArgumentParser command in `lilshot`.
- Baseline verified 2026-07-15: `swift test` passes 121 tests; working tree already has unrelated untracked `docs/` and `qa/`, preserve them.

## Contract and architecture

- Add `TextRecognizing` in Core: `recognize(_ image: CGImage) async throws -> [(String, CGRect)]`.
- Add `OCRTextAssembler`: accept recognized text plus Vision normalized bottom-left boxes; group into lines when vertical overlap divided by the smaller box height is `> 0.5`; order lines by descending `midY`, items left-to-right; join items with spaces and lines with newlines.
- Compute median grouped-line height; insert one extra newline when the edge-to-edge vertical gap to the next line exceeds `1.5 * medianLineHeight`. Preserve recognized Unicode text exactly; empty input returns `""`.
- Add `VisionTextRecognizer` in Mac using `VNRecognizeTextRequest`: `.accurate`, `usesLanguageCorrection = true`, `recognitionLanguages = ["vi-VN", "en-US"]`; return top candidate text and observation bounding box.
- Editor OCR uses the controller's current base image after any applied crop, not annotation rendering. Region/CLI use native-scale captures (`relativeScale: 1.0`).

## Files

- Create: `Sources/LilshotCore/TextRecognizing.swift`, `Sources/LilshotCore/OCRTextAssembler.swift`, `Sources/LilshotMac/VisionTextRecognizer.swift`, `Sources/LilshotApp/ClipboardTextWriter.swift`, `Sources/lilshot/OCRCommand.swift`, `Tests/LilshotCoreTests/OCRTextAssemblerTests.swift`.
- Modify: `Package.swift` only if test/target wiring proves necessary; `Sources/LilshotApp/EditorToolbarView.swift`, `EditorWindowController.swift`, `EditorWindowKeyHandling.swift`, `AppDelegate.swift`, `HotkeyMonitor.swift`; `Sources/lilshot/Lilshot.swift`; `README.md`.
- Keep each code file near/below 200 lines; split `AppDelegate` or editor OCR coordination into a focused extension if additions would push it materially over the limit.

## Strict TDD implementation order

1. RED: add assembler tests first; run `swift test --filter OCRTextAssemblerTests` and record the expected compile/test failure before production code.
2. Cover empty input; one line ordered left-to-right with spaces; top-to-bottom offset columns; exactly-above/below 50% overlap behavior; paragraph gap threshold; Vietnamese diacritics passthrough. Use deliberately shuffled inputs to prove deterministic ordering.
3. GREEN: add the Core protocol/assembler only; rerun focused tests, then full `swift test`. REFACTOR only while green.
4. Add Vision adapter with the exact request configuration; compile immediately. Do not weaken deterministic Core assertions to accommodate Vision variability.
5. Add editor Copy Text button and `Cmd+Shift+T`: async-recognize the post-crop image, assemble, write plain text to pasteboard, play existing success/error sounds, and report failures to stderr. Prevent duplicate in-flight editor OCR.
6. Add a region-capture mode (`image`/`text`) through the existing overlay. Register `Option+Shift+O`; text mode captures the selected region, OCRs it, writes only text, gives feedback, and never writes an image or opens the editor.
7. Add `lilshot ocr <query|windowID>` using the same permission, noise-filter, query resolver, ambiguity exit behavior, and native capture path as `capture`; successful stdout contains assembled text only, all diagnostics/errors go to stderr.
8. Update README CLI/hotkey documentation, remove dead code, run all verification, then review the final diff for scope and regressions.

## Logical commits

1. `feat: add OCR text assembly and Vision recognition` — red-green Core tests plus Mac adapter.
2. `feat: copy recognized text from the editor` — toolbar, shortcut, text pasteboard, feedback.
3. `feat: add region OCR hotkey` — fifth independently registered hotkey and text-only overlay flow.
4. `feat: add OCR CLI command` — command registration, shared capture/query semantics, README updates.
- Never commit a red state; run focused and full tests before each commit; no plan/finding references or AI references in code, tests, or commit messages.

## Verification and acceptance

- Automated: focused assembler tests; `swift test`; `swift build -c release`; `bash scripts/make-app.sh`.
- CLI errors: missing/numeric/fuzzy/ambiguous query cases preserve stderr and exit semantics; pipe stdout to a file and confirm it contains OCR text only.
- Real OCR: in a Screen Recording-authorized interactive terminal, open a visible window containing two English lines and a Vietnamese-diacritic line, resolve its ID with `./.build/release/lilshot list --json`, then run `./.build/release/lilshot ocr <id> > /tmp/lilshot-ocr.txt`; compare ordering, paragraph breaks, and Unicode text to the visible window.
- GUI manual: editor Copy Text and `Cmd+Shift+T` after crop; `Option+Shift+O` region OCR; confirm text pasteboard, sounds, stderr failures, no editor for region OCR, and no PNG/image pasteboard flavor in text-only paths.
- Regression: existing picker, recapture, fullscreen, region image capture, editor image copy/save, and `lilshot capture` remain unchanged.

## Risks and unresolved questions

- Vision recognition is OS/runtime dependent, so deterministic layout belongs in Core tests and final confidence requires the real CLI check above.
- No unresolved product decisions; exact OCR languages, thresholds, shortcuts, and output channels are specified.
