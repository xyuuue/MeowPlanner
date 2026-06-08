import Foundation

public struct FocusTimerState: Equatable, Sendable {
    public var durationSeconds: Int
    public private(set) var startedAt: Date?
    public private(set) var lastResumedAt: Date?
    public private(set) var accumulatedActiveSeconds: Int
    public private(set) var isRunning: Bool

    public init(
        durationSeconds: Int,
        startedAt: Date? = nil,
        lastResumedAt: Date? = nil,
        accumulatedActiveSeconds: Int = 0,
        isRunning: Bool = false
    ) {
        self.durationSeconds = max(1, durationSeconds)
        self.startedAt = startedAt
        self.lastResumedAt = lastResumedAt
        self.accumulatedActiveSeconds = max(0, accumulatedActiveSeconds)
        self.isRunning = isRunning
    }

    public mutating func start(at date: Date = Date()) {
        startedAt = date
        lastResumedAt = date
        accumulatedActiveSeconds = 0
        isRunning = true
    }

    public mutating func pause(at date: Date = Date()) {
        guard isRunning, let lastResumedAt else {
            return
        }

        accumulatedActiveSeconds += max(0, Int(date.timeIntervalSince(lastResumedAt)))
        self.lastResumedAt = nil
        isRunning = false
    }

    public mutating func resume(at date: Date = Date()) {
        guard !isRunning else {
            return
        }

        if startedAt == nil {
            startedAt = date
        }

        lastResumedAt = date
        isRunning = true
    }

    public func elapsedSeconds(at date: Date = Date()) -> Int {
        guard isRunning, let lastResumedAt else {
            return accumulatedActiveSeconds
        }

        return accumulatedActiveSeconds + max(0, Int(date.timeIntervalSince(lastResumedAt)))
    }

    public func remainingSeconds(at date: Date = Date()) -> Int {
        max(0, durationSeconds - elapsedSeconds(at: date))
    }
}
