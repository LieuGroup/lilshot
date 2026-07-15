import Foundation

/// Pure picker state: query, ranked rows, and wrapped selection.
public struct PickerViewModel: Equatable, Sendable {
    private let baseWindows: [WindowInfo]

    public private(set) var query: String
    public private(set) var rows: [WindowInfo]
    public private(set) var selectedIndex: Int

    public init(windows: [WindowInfo]) {
        let filtered = WindowNoiseFilter.apply(to: windows)
        self.baseWindows = filtered
        self.query = ""
        self.rows = filtered
        self.selectedIndex = 0
    }

    public var selectedWindow: WindowInfo? {
        guard !rows.isEmpty, selectedIndex >= 0, selectedIndex < rows.count else {
            return nil
        }
        return rows[selectedIndex]
    }

    public mutating func setQuery(_ newQuery: String) {
        let previousID = selectedWindow?.id
        query = newQuery
        rows = FuzzyMatcher.rank(query: newQuery, in: baseWindows).map(\.window)

        guard !rows.isEmpty else {
            selectedIndex = 0
            return
        }

        if let previousID, let idx = rows.firstIndex(where: { $0.id == previousID }) {
            selectedIndex = idx
        } else {
            selectedIndex = 0
        }
    }

    public mutating func moveSelection(_ delta: Int) {
        guard !rows.isEmpty else { return }
        let count = rows.count
        // Positive modulo so negative deltas wrap cleanly.
        selectedIndex = ((selectedIndex + delta) % count + count) % count
    }
}
