import Foundation

/// Bounded admission for preview captures: pending IDs in priority order with a concurrency cap.
public struct PreviewAdmissionQueue: Sendable {
    public let maxConcurrent: Int

    private var pending: [UInt32] = []
    private var inFlight: Set<UInt32> = []
    private var done: Set<UInt32> = []

    public var inFlightCount: Int { inFlight.count }

    public init(maxConcurrent: Int = 2) {
        self.maxConcurrent = max(1, maxConcurrent)
    }

    /// New IDs go to the front in the given order. Dedups against pending, in-flight, and done;
    /// re-enqueue of a pending ID moves it to the front.
    public mutating func enqueue(ids: [UInt32]) {
        var toFront: [UInt32] = []
        var seenInBatch = Set<UInt32>()
        for id in ids {
            guard !seenInBatch.contains(id) else { continue }
            seenInBatch.insert(id)
            if done.contains(id) || inFlight.contains(id) { continue }
            if let index = pending.firstIndex(of: id) {
                pending.remove(at: index)
            }
            toFront.append(id)
        }
        pending = toFront + pending
    }

    /// Next ID to admit, or nil when at the concurrency limit or nothing is pending.
    public func next() -> UInt32? {
        guard inFlight.count < maxConcurrent else { return nil }
        return pending.first
    }

    public mutating func markStarted(_ id: UInt32) {
        if let index = pending.firstIndex(of: id) {
            pending.remove(at: index)
        }
        inFlight.insert(id)
        done.remove(id)
    }

    public mutating func markFinished(_ id: UInt32) {
        inFlight.remove(id)
    }

    public mutating func markCached(_ id: UInt32) {
        if let index = pending.firstIndex(of: id) {
            pending.remove(at: index)
        }
        inFlight.remove(id)
        done.insert(id)
    }

    public mutating func reset() {
        pending.removeAll()
        inFlight.removeAll()
        done.removeAll()
    }
}
