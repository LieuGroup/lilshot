import XCTest
@testable import LilshotCore

final class PreviewAdmissionQueueTests: XCTestCase {
    func testEnqueuePutsNewIdsAtFrontInGivenOrder() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [10, 20, 30])
        XCTAssertEqual(queue.next(), 10)
        queue.markStarted(10)
        XCTAssertEqual(queue.next(), 20)
        queue.markStarted(20)
        // At concurrency limit — no more admissions
        XCTAssertNil(queue.next())
    }

    func testReEnqueueMovesPendingIdToFront() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [1, 2, 3])
        // Re-select 3 → it should become next
        queue.enqueue(ids: [3])
        XCTAssertEqual(queue.next(), 3)
        queue.markStarted(3)
        XCTAssertEqual(queue.next(), 1)
        queue.markStarted(1)
    }

    func testEnqueuePrependsBatchAheadOfExistingPending() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 1)
        queue.enqueue(ids: [10, 20])
        queue.enqueue(ids: [30, 40])
        // New batch at front in given order, then old pending
        XCTAssertEqual(drainAll(&queue), [30, 40, 10, 20])
    }

    func testDedupSkipsInFlightAndDone() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [1, 2])
        _ = queue.next()
        queue.markStarted(1)
        queue.markCached(2)

        queue.enqueue(ids: [1, 2, 3])
        // 1 in-flight and 2 done → only 3 is new
        XCTAssertEqual(queue.next(), 3)
        queue.markStarted(3)
        XCTAssertNil(queue.next())
    }

    func testConcurrencyLimitBlocksAdmission() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [1, 2, 3])
        XCTAssertEqual(queue.next(), 1)
        queue.markStarted(1)
        XCTAssertEqual(queue.next(), 2)
        queue.markStarted(2)
        XCTAssertNil(queue.next())
        XCTAssertEqual(queue.inFlightCount, 2)
    }

    func testFinishAdmitsNext() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [1, 2, 3])
        _ = queue.next(); queue.markStarted(1)
        _ = queue.next(); queue.markStarted(2)
        XCTAssertNil(queue.next())

        queue.markFinished(1)
        XCTAssertEqual(queue.next(), 3)
        queue.markStarted(3)
        XCTAssertNil(queue.next())
    }

    func testMarkCachedRemovesFromPendingAndBlocksReEnqueue() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [5, 6])
        queue.markCached(5)
        XCTAssertEqual(queue.next(), 6)
        queue.markStarted(6)
        queue.markFinished(6)
        queue.markCached(6)

        queue.enqueue(ids: [5, 6, 7])
        // 5 and 6 are done — only 7 admits
        XCTAssertEqual(queue.next(), 7)
    }

    func testResetClearsPendingInFlightAndDone() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [1, 2, 3])
        _ = queue.next()
        queue.markStarted(1)
        queue.markCached(2)
        queue.reset()

        XCTAssertEqual(queue.inFlightCount, 0)
        XCTAssertNil(queue.next())
        queue.enqueue(ids: [2, 1])
        XCTAssertEqual(queue.next(), 2)
    }

    func testDefaultMaxConcurrentIsTwo() {
        var queue = PreviewAdmissionQueue()
        queue.enqueue(ids: [1, 2, 3])
        _ = queue.next(); queue.markStarted(1)
        _ = queue.next(); queue.markStarted(2)
        XCTAssertNil(queue.next())
    }

    func testInvalidateAllowsReEnqueueToFront() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [1, 2])
        queue.markCached(1)
        queue.enqueue(ids: [1])
        XCTAssertEqual(queue.next(), 2) // 1 still done — skipped

        queue.invalidate(1)
        queue.enqueue(ids: [1])
        XCTAssertEqual(queue.next(), 1)
    }

    func testInvalidateOfInFlightIsNoOp() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [1, 2])
        _ = queue.next()
        queue.markStarted(1)

        queue.invalidate(1)
        queue.enqueue(ids: [1])
        // Still in-flight — cannot re-enqueue; next is 2
        XCTAssertEqual(queue.next(), 2)
        queue.markStarted(2)
        XCTAssertNil(queue.next())
    }

    func testInvalidateOfUnknownIdIsSafe() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.invalidate(99)
        queue.enqueue(ids: [1])
        XCTAssertEqual(queue.next(), 1)
    }

    func testInvalidateRemovesPendingId() {
        var queue = PreviewAdmissionQueue(maxConcurrent: 2)
        queue.enqueue(ids: [1, 2, 3])
        queue.invalidate(2)
        XCTAssertEqual(drainAll(&queue), [1, 3])
    }

    /// Drain by repeatedly admitting and finishing one at a time (serial).
    private func drainAll(_ queue: inout PreviewAdmissionQueue) -> [UInt32] {
        var result: [UInt32] = []
        while let id = queue.next() {
            result.append(id)
            queue.markStarted(id)
            queue.markFinished(id)
        }
        return result
    }
}
