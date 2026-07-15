import CoreGraphics

public enum OCRTextAssembler {
    public static func assemble(_ observations: [(String, CGRect)]) -> String {
        guard !observations.isEmpty else { return "" }

        let sorted = observations.sorted { lhs, rhs in
            if lhs.1.midY != rhs.1.midY { return lhs.1.midY > rhs.1.midY }
            return lhs.1.minX < rhs.1.minX
        }
        var lines: [Line] = []

        for observation in sorted {
            if let index = lines.firstIndex(where: {
                verticalOverlapRatio($0.bounds, observation.1) > 0.5
            }) {
                lines[index].append(observation)
            } else {
                lines.append(Line(observation: observation))
            }
        }

        lines.sort {
            if $0.bounds.midY != $1.bounds.midY { return $0.bounds.midY > $1.bounds.midY }
            return $0.bounds.minX < $1.bounds.minX
        }
        let medianHeight = median(lines.map(\.bounds.height))
        var result = ""

        for index in lines.indices {
            if index > 0 {
                let gap = lines[index - 1].bounds.minY - lines[index].bounds.maxY
                result += gap > 1.5 * medianHeight ? "\n\n" : "\n"
            }
            result += lines[index].text
        }
        return result
    }

    private static func verticalOverlapRatio(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let smallerHeight = min(lhs.height, rhs.height)
        guard smallerHeight > 0 else { return 0 }
        let overlap = max(0, min(lhs.maxY, rhs.maxY) - max(lhs.minY, rhs.minY))
        return overlap / smallerHeight
    }

    private static func median(_ values: [CGFloat]) -> CGFloat {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }

    private struct Line {
        private(set) var observations: [(String, CGRect)]
        private(set) var bounds: CGRect

        init(observation: (String, CGRect)) {
            observations = [observation]
            bounds = observation.1
        }

        mutating func append(_ observation: (String, CGRect)) {
            observations.append(observation)
            bounds = bounds.union(observation.1)
        }

        var text: String {
            observations.sorted { $0.1.minX < $1.1.minX }.map(\.0).joined(separator: " ")
        }
    }
}
