import Foundation

/// Priority order for lazily loading window previews.
public enum PreviewLoadOrder {
    /// Selected row first, then neighbors inside `visibleRange` expanding outward,
    /// then any remaining rows (also expanding outward from the selection).
    public static func indices(
        rowCount: Int,
        selectedIndex: Int,
        visibleRange: Range<Int>
    ) -> [Int] {
        guard rowCount > 0 else { return [] }

        let selected = min(max(0, selectedIndex), rowCount - 1)
        let lower = max(0, visibleRange.lowerBound)
        let upper = min(rowCount, max(lower, visibleRange.upperBound))
        let visible = lower..<upper

        var result: [Int] = []
        var seen = Set<Int>()

        func append(_ index: Int) {
            guard index >= 0, index < rowCount, !seen.contains(index) else { return }
            seen.insert(index)
            result.append(index)
        }

        append(selected)

        var distance = 1
        while true {
            let left = selected - distance
            let right = selected + distance
            let leftVisible = visible.contains(left)
            let rightVisible = visible.contains(right)
            if !leftVisible && !rightVisible {
                let pastLeft = left < visible.lowerBound
                let pastRight = right >= visible.upperBound
                if pastLeft && pastRight { break }
            }
            if leftVisible { append(left) }
            if rightVisible { append(right) }
            distance += 1
            if distance > rowCount { break }
        }

        distance = 1
        while result.count < rowCount {
            append(selected - distance)
            append(selected + distance)
            distance += 1
            if distance > rowCount { break }
        }

        return result
    }
}
