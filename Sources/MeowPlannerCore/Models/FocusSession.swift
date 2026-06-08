import Foundation
import SwiftData

public enum FocusMode: String, CaseIterable, Identifiable, Sendable {
    case countdown
    case stopwatch

    public var id: String { rawValue }
}

@Model
public final class FocusTag {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var colorHex: String
    public var createdAt: Date
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#71B7ED",
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

@Model
public final class FocusSession {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var startedAt: Date
    public var endedAt: Date?
    public var plannedDurationSeconds: Int
    public var completedDurationSeconds: Int
    public var linkedTodoID: UUID?
    public var linkedHabitID: UUID?
    public var tagID: UUID?
    public var modeRawValue: String = FocusMode.countdown.rawValue

    public init(
        id: UUID = UUID(),
        title: String,
        startedAt: Date,
        endedAt: Date? = nil,
        plannedDurationSeconds: Int = 1_500,
        completedDurationSeconds: Int = 0,
        linkedTodoID: UUID? = nil,
        linkedHabitID: UUID? = nil,
        tagID: UUID? = nil,
        mode: FocusMode = .countdown
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedDurationSeconds = plannedDurationSeconds
        self.completedDurationSeconds = completedDurationSeconds
        self.linkedTodoID = linkedTodoID
        self.linkedHabitID = linkedHabitID
        self.tagID = tagID
        self.modeRawValue = mode.rawValue
    }

    public var mode: FocusMode {
        get {
            FocusMode(rawValue: modeRawValue) ?? .countdown
        }
        set {
            modeRawValue = newValue.rawValue
        }
    }
}

public enum FocusAnalytics {
    public enum Range: Equatable, Sendable {
        case day(containing: Date, calendar: Calendar)
        case week(containing: Date, calendar: Calendar)
        case month(containing: Date, calendar: Calendar)
        case year(containing: Date, calendar: Calendar)

        public var interval: DateInterval {
            switch self {
            case let .day(date, calendar):
                return calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 86_400)
            case let .week(date, calendar):
                return calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 86_400)
            case let .month(date, calendar):
                return calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 30 * 86_400)
            case let .year(date, calendar):
                return calendar.dateInterval(of: .year, for: date) ?? DateInterval(start: date, duration: 365 * 86_400)
            }
        }
    }

    public struct Summary: Equatable, Sendable {
        public var totalSeconds: Int
        public var sessionCount: Int
        public var averageSeconds: Int
        public var activeDayCount: Int
        public var longestSeconds: Int
        public var tagBreakdown: [TagBreakdown]
        public var hourDistribution: [HourDistribution]
        public var dayDistribution: [DayDistribution]
    }

    public struct TagBreakdown: Identifiable, Equatable, Sendable {
        public var id: UUID?
        public var name: String
        public var colorHex: String
        public var totalSeconds: Int
        public var sessionCount: Int
    }

    public struct HourDistribution: Identifiable, Equatable, Sendable {
        public var hour: Int
        public var totalSeconds: Int
        public var id: Int { hour }
    }

    public struct DayDistribution: Identifiable, Equatable, Sendable {
        public var date: Date
        public var totalSeconds: Int
        public var id: Date { date }
    }

    public enum TimelineEntryKind: Equatable, Sendable {
        case session
        case gap
    }

    public struct TimelineEntry: Identifiable {
        public var id: String
        public var kind: TimelineEntryKind
        public var session: FocusSession?
        public var gapSeconds: Int?
    }

    public static func summary(
        sessions: [FocusSession],
        tags: [FocusTag],
        range: Range,
        calendar: Calendar = .current,
        uncategorizedName: String = "Uncategorized",
        uncategorizedColorHex: String = "#F2B56F"
    ) -> Summary {
        let interval = range.interval
        let visibleSessions = sessions.filter { session in
            interval.contains(session.startedAt)
        }
        let totalSeconds = visibleSessions.reduce(0) { $0 + max(0, $1.completedDurationSeconds) }
        let sessionCount = visibleSessions.count
        let averageSeconds = sessionCount == 0 ? 0 : totalSeconds / sessionCount
        let longestSeconds = visibleSessions.map(\.completedDurationSeconds).max() ?? 0
        let activeDays = Set(visibleSessions.map { calendar.startOfDay(for: $0.startedAt) })

        return Summary(
            totalSeconds: totalSeconds,
            sessionCount: sessionCount,
            averageSeconds: averageSeconds,
            activeDayCount: activeDays.count,
            longestSeconds: longestSeconds,
            tagBreakdown: tagBreakdown(
                for: visibleSessions,
                tags: tags,
                uncategorizedName: uncategorizedName,
                uncategorizedColorHex: uncategorizedColorHex
            ),
            hourDistribution: hourDistribution(for: visibleSessions, calendar: calendar),
            dayDistribution: dayDistribution(for: visibleSessions, interval: interval, calendar: calendar)
        )
    }

    public static func timelineEntries(
        for date: Date,
        sessions: [FocusSession],
        calendar: Calendar = .current,
        minimumGapSeconds: Int = 5 * 60
    ) -> [TimelineEntry] {
        let dayInterval = calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 86_400)
        let daySessions = sessions
            .filter { dayInterval.contains($0.startedAt) }
            .sorted { $0.startedAt < $1.startedAt }

        var entries: [TimelineEntry] = []
        var previousEnd: Date?
        for session in daySessions {
            if let previousEnd {
                let gapSeconds = Int(session.startedAt.timeIntervalSince(previousEnd))
                if gapSeconds > minimumGapSeconds {
                    entries.append(TimelineEntry(
                        id: "gap-\(previousEnd.timeIntervalSince1970)-\(session.startedAt.timeIntervalSince1970)",
                        kind: .gap,
                        session: nil,
                        gapSeconds: gapSeconds
                    ))
                }
            }

            entries.append(TimelineEntry(
                id: "session-\(session.id.uuidString)",
                kind: .session,
                session: session,
                gapSeconds: nil
            ))
            previousEnd = session.endedAt ?? session.startedAt.addingTimeInterval(TimeInterval(max(0, session.completedDurationSeconds)))
        }

        return entries
    }

    private static func tagBreakdown(
        for sessions: [FocusSession],
        tags: [FocusTag],
        uncategorizedName: String,
        uncategorizedColorHex: String
    ) -> [TagBreakdown] {
        let tagByID = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })
        let grouped = Dictionary(grouping: sessions) { session in
            session.tagID
        }

        return grouped.map { tagID, sessions in
            let tag = tagID.flatMap { tagByID[$0] }
            return TagBreakdown(
                id: tagID,
                name: tag?.name.isEmpty == false ? tag?.name ?? uncategorizedName : uncategorizedName,
                colorHex: tag?.colorHex ?? uncategorizedColorHex,
                totalSeconds: sessions.reduce(0) { $0 + max(0, $1.completedDurationSeconds) },
                sessionCount: sessions.count
            )
        }
        .sorted {
            if $0.totalSeconds != $1.totalSeconds {
                return $0.totalSeconds > $1.totalSeconds
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func hourDistribution(for sessions: [FocusSession], calendar: Calendar) -> [HourDistribution] {
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.component(.hour, from: session.startedAt)
        }
        return (0..<24).map { hour in
            HourDistribution(
                hour: hour,
                totalSeconds: grouped[hour, default: []].reduce(0) { $0 + max(0, $1.completedDurationSeconds) }
            )
        }
    }

    private static func dayDistribution(
        for sessions: [FocusSession],
        interval: DateInterval,
        calendar: Calendar
    ) -> [DayDistribution] {
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }
        var result: [DayDistribution] = []
        var cursor = calendar.startOfDay(for: interval.start)
        while cursor < interval.end {
            result.append(DayDistribution(
                date: cursor,
                totalSeconds: grouped[cursor, default: []].reduce(0) { $0 + max(0, $1.completedDurationSeconds) }
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }
        return result
    }
}
