import Foundation
import SwiftData
import Testing
@testable import MeowPlannerCore

@Suite("Focus analytics")
struct FocusAnalyticsTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test("focus tags and session mode persist in SwiftData")
    func focusTagsAndSessionModePersistInSwiftData() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let tagID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let tag = FocusTag(id: tagID, name: "Reading", colorHex: "#71B7ED")
        let session = FocusSession(
            title: "Article notes",
            startedAt: try date("2026-04-06 09:00"),
            endedAt: try date("2026-04-06 09:25"),
            plannedDurationSeconds: 0,
            completedDurationSeconds: 1_500,
            tagID: tagID,
            mode: .stopwatch
        )

        context.insert(tag)
        context.insert(session)
        try context.save()

        let savedTags = try context.fetch(FetchDescriptor<FocusTag>())
        let savedSessions = try context.fetch(FetchDescriptor<FocusSession>())

        #expect(savedTags.first?.name == "Reading")
        #expect(savedTags.first?.colorHex == "#71B7ED")
        #expect(savedSessions.first?.tagID == tagID)
        #expect(savedSessions.first?.mode == .stopwatch)
    }

    @Test("focus analytics summarizes selected day by tag")
    func focusAnalyticsSummarizesSelectedDayByTag() throws {
        let readingID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let vocabID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let sessions = [
            try focusSession("Reading", tagID: readingID, "2026-04-06 09:08", minutes: 14),
            try focusSession("Words", tagID: vocabID, "2026-04-06 09:22", minutes: 13),
            try focusSession("Reading", tagID: readingID, "2026-04-06 11:04", minutes: 48),
            try focusSession("Tomorrow", tagID: readingID, "2026-04-07 08:00", minutes: 60)
        ]
        let tags = [
            FocusTag(id: readingID, name: "Reading", colorHex: "#71B7ED"),
            FocusTag(id: vocabID, name: "Vocabulary", colorHex: "#F2A7DA")
        ]

        let summary = FocusAnalytics.summary(
            sessions: sessions,
            tags: tags,
            range: .day(containing: try date("2026-04-06 12:00"), calendar: calendar),
            calendar: calendar
        )

        #expect(summary.totalSeconds == 4_500)
        #expect(summary.sessionCount == 3)
        #expect(summary.averageSeconds == 1_500)
        #expect(summary.activeDayCount == 1)
        #expect(summary.longestSeconds == 2_880)
        #expect(summary.tagBreakdown.map(\.name) == ["Reading", "Vocabulary"])
        #expect(summary.tagBreakdown.map(\.totalSeconds) == [3_720, 780])
        #expect(summary.hourDistribution.first { $0.hour == 9 }?.totalSeconds == 1_620)
        #expect(summary.hourDistribution.first { $0.hour == 11 }?.totalSeconds == 2_880)
    }

    @Test("focus timeline orders sessions and inserts long gaps")
    func focusTimelineOrdersSessionsAndInsertsLongGaps() throws {
        let sessions = [
            try focusSession("Lunch", tagID: nil, "2026-04-06 12:18", minutes: 30),
            try focusSession("Vocabulary", tagID: nil, "2026-04-06 09:22", minutes: 13),
            try focusSession("Reading", tagID: nil, "2026-04-06 09:36", minutes: 27)
        ]

        let entries = FocusAnalytics.timelineEntries(
            for: try date("2026-04-06 10:00"),
            sessions: sessions,
            calendar: calendar,
            minimumGapSeconds: 5 * 60
        )

        #expect(entries.map(\.kind) == [.session, .session, .gap, .session])
        #expect(entries.compactMap(\.session?.title) == ["Vocabulary", "Reading", "Lunch"])
        #expect(entries.first { $0.kind == .gap }?.gapSeconds == 8_100)
    }

    private func focusSession(
        _ title: String,
        tagID: UUID?,
        _ start: String,
        minutes: Int,
        mode: FocusMode = .countdown
    ) throws -> FocusSession {
        let startedAt = try date(start)
        return FocusSession(
            title: title,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(TimeInterval(minutes * 60)),
            plannedDurationSeconds: mode == .countdown ? minutes * 60 : 0,
            completedDurationSeconds: minutes * 60,
            tagID: tagID,
            mode: mode
        )
    }

    private func date(_ string: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try #require(formatter.date(from: string))
    }
}
