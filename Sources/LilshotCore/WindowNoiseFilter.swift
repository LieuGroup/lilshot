import Foundation

public enum WindowNoiseFilter {
    private static let minimumDimension = 40

    public static func apply(to windows: [WindowInfo]) -> [WindowInfo] {
        windows
            .filter { window in
                window.width >= minimumDimension
                    && window.height >= minimumDimension
                    && !window.appName.isEmpty
            }
            .sorted { lhs, rhs in
                if lhs.isOnScreen != rhs.isOnScreen {
                    return !lhs.isOnScreen && rhs.isOnScreen
                }
                if lhs.appName != rhs.appName {
                    return lhs.appName.localizedStandardCompare(rhs.appName) == .orderedAscending
                }
                return lhs.id < rhs.id
            }
    }
}
