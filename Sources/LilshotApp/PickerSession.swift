import Foundation
import LilshotCore

/// Thin ObservableObject bridge so SwiftUI stays free of ranking/selection logic.
@MainActor
final class PickerSession: ObservableObject {
    @Published private(set) var rows: [WindowInfo] = []
    @Published private(set) var selectedIndex: Int = 0
    @Published var query: String = "" {
        didSet {
            guard query != model.query else { return }
            model.setQuery(query)
            publish()
            refreshPreviews()
        }
    }

    private var model: PickerViewModel
    private let provider: any WindowProviding
    let previewStore: PreviewStore
    private var livePreviewTask: Task<Void, Never>?

    var selectedWindow: WindowInfo? { model.selectedWindow }

    init(provider: any WindowProviding, capturer: any WindowCapturing) {
        self.provider = provider
        self.previewStore = PreviewStore(capturer: capturer)
        self.model = PickerViewModel(windows: [])
        publish()
    }

    func reload() async {
        do {
            let windows = try await provider.windows()
            model = PickerViewModel(windows: windows)
            model.setQuery(query)
            publish()
            refreshPreviews()
        } catch {
            fputs("window list failed: \(error.localizedDescription)\n", stderr)
            model = PickerViewModel(windows: [])
            publish()
        }
    }

    func moveSelection(_ delta: Int) {
        model.moveSelection(delta)
        publish()
        refreshPreviews()
    }

    func selectIndex(_ index: Int) {
        guard index >= 0, index < rows.count else { return }
        let delta = index - selectedIndex
        guard delta != 0 else { return }
        model.moveSelection(delta)
        publish()
        refreshPreviews()
    }

    func resetForClose() {
        stopLivePreviewRefresh()
        model.setQuery("")
        query = ""
        publish()
        previewStore.clear()
    }

    /// 1 Hz refresh of the selected window's big preview while the panel is visible.
    func startLivePreviewRefresh() {
        stopLivePreviewRefresh()
        livePreviewTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self?.refreshSelectedPreview()
                }
            }
        }
    }

    func stopLivePreviewRefresh() {
        livePreviewTask?.cancel()
        livePreviewTask = nil
    }

    func refreshPreviews(visibleRange: Range<Int>? = nil) {
        let range = visibleRange ?? visibleFallbackRange()
        let order = PreviewLoadOrder.indices(
            rowCount: rows.count,
            selectedIndex: selectedIndex,
            visibleRange: range
        )
        let ids = order.map { rows[$0].id }
        previewStore.enqueue(windowIDs: ids)
    }

    private func refreshSelectedPreview() {
        guard let id = selectedWindow?.id else { return }
        previewStore.refresh(windowID: id)
    }

    private func visibleFallbackRange() -> Range<Int> {
        guard !rows.isEmpty else { return 0..<0 }
        let start = max(0, selectedIndex - 4)
        let end = min(rows.count, selectedIndex + 5)
        return start..<end
    }

    private func publish() {
        rows = model.rows
        selectedIndex = model.selectedIndex
    }
}
