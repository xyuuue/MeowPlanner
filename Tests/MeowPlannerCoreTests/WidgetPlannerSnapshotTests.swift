import Foundation
import SwiftData
import Testing
@testable import MeowPlannerCore

@Suite("Widget planner snapshot")
struct WidgetPlannerSnapshotTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("snapshot stores visible planner data for widget timelines")
    func snapshotStoresVisiblePlannerDataForWidgetTimelines() throws {
        let event = PlannerEvent(
            title: "Study session",
            startDate: try date("2026-06-03 09:00"),
            endDate: try date("2026-06-03 10:00"),
            notes: "METCS",
            repeatRule: .weekly(interval: 1, weekdays: [4]),
            tagName: "学习",
            colorHex: "#71B7ED"
        )
        let todo = TodoItem(
            title: "Submit homework",
            dueDate: try date("2026-06-03 22:00"),
            createdAt: try date("2026-06-02 12:00")
        )
        let snapshot = WidgetPlannerSnapshot(
            events: [event],
            todos: [todo],
            habitCount: 2,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-02 13:00")
        )

        let restoredEvent = try #require(snapshot.plannerEvents.first)
        let restoredTodo = try #require(snapshot.todoItems.first)

        #expect(snapshot.habitCount == 2)
        #expect(snapshot.weekStartPreference == .monday)
        #expect(snapshot.showChineseCalendar)
        #expect(restoredEvent.title == "Study session")
        #expect(restoredEvent.repeatRule == .weekly(interval: 1, weekdays: [4]))
        #expect(restoredEvent.tagName == "学习")
        #expect(restoredEvent.colorHex == "#71B7ED")
        let expectedDueDate = try date("2026-06-03 22:00")
        #expect(restoredTodo.title == "Submit homework")
        #expect(restoredTodo.dueDate == expectedDueDate)
    }

    @Test("snapshot stores completed schedule display preferences")
    func snapshotStoresCompletedScheduleDisplayPreferences() throws {
        let snapshot = WidgetPlannerSnapshot(
            events: [],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            showCompletedSchedules: false,
            completedSchedulesUseStrikethrough: false,
            updatedAt: try date("2026-06-02 13:00")
        )

        let data = try JSONEncoder().encode(snapshot)
        let restored = try JSONDecoder().decode(WidgetPlannerSnapshot.self, from: data)

        #expect(restored.showCompletedSchedules == false)
        #expect(restored.completedSchedulesUseStrikethrough == false)
    }

    @Test("snapshot decodes older payloads with completed schedule display defaults")
    func snapshotDecodesOlderPayloadsWithCompletedScheduleDisplayDefaults() throws {
        let legacyPayload = """
        {
          "events": [],
          "todos": [],
          "habitCount": 0,
          "weekStartPreference": 1,
          "showChineseCalendar": true,
          "updatedAt": 0
        }
        """.data(using: .utf8)!

        let restored = try JSONDecoder().decode(WidgetPlannerSnapshot.self, from: legacyPayload)

        #expect(restored.showCompletedSchedules)
        #expect(restored.completedSchedulesUseStrikethrough)
    }

    @Test("snapshot store round trips through user defaults")
    func snapshotStoreRoundTripsThroughUserDefaults() throws {
        let suiteName = "MeowPlannerWidgetSnapshotTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let snapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Dentist", startDate: try date("2026-06-04 14:00"))],
            todos: [TodoItem(title: "Pack bag", dueDate: try date("2026-06-04 20:00"))],
            habitCount: 1,
            weekStartPreference: .sunday,
            showChineseCalendar: false,
            updatedAt: try date("2026-06-02 13:00")
        )

        WidgetPlannerSnapshotStore.save(snapshot, defaults: defaults)
        let restored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults))

        #expect(restored.plannerEvents.first?.title == "Dentist")
        #expect(restored.todoItems.first?.title == "Pack bag")
        #expect(restored.habitCount == 1)
        #expect(restored.weekStartPreference == .sunday)
        #expect(restored.showChineseCalendar == false)
    }

    @Test("snapshot store prefers app group file for cross process widget reads")
    func snapshotStorePrefersAppGroupFileForCrossProcessWidgetReads() throws {
        let suiteName = "MeowPlannerWidgetSnapshotFileTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshot-\(UUID().uuidString).json")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        let defaultsSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Old defaults event", startDate: try date("2026-06-02 10:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-02 13:00")
        )
        let fileSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh file event", startDate: try date("2026-06-03 20:00"))],
            todos: [TodoItem(title: "Fresh file todo", dueDate: try date("2026-06-03 21:00"))],
            habitCount: 2,
            weekStartPreference: .monday,
            showChineseCalendar: false,
            updatedAt: try date("2026-06-03 13:00")
        )

        WidgetPlannerSnapshotStore.save(defaultsSnapshot, defaults: defaults)
        WidgetPlannerSnapshotStore.save(fileSnapshot, defaults: defaults, fileURL: fileURL)
        let restored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURL: fileURL))

        #expect(restored.plannerEvents.first?.title == "Fresh file event")
        #expect(restored.todoItems.first?.title == "Fresh file todo")
        #expect(restored.habitCount == 2)
        #expect(restored.weekStartPreference == .monday)
        #expect(restored.showChineseCalendar == false)
    }

    @Test("snapshot store can be cleared on sign out")
    func snapshotStoreCanBeClearedOnSignOut() throws {
        let suiteName = "MeowPlannerWidgetSnapshotClearTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotClear-\(UUID().uuidString).json")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        let snapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Private account event", startDate: try date("2026-06-05 09:00"))],
            todos: [TodoItem(title: "Private account todo", dueDate: try date("2026-06-05 10:00"))],
            habitCount: 1,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-05 08:00")
        )

        WidgetPlannerSnapshotStore.save(snapshot, defaults: defaults, fileURL: fileURL)
        #expect(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURL: fileURL) != nil)

        WidgetPlannerSnapshotStore.clear(defaults: defaults, fileURLs: [fileURL])

        #expect(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURL: fileURL) == nil)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("snapshot store searches multiple app group file candidates")
    func snapshotStoreSearchesMultipleAppGroupFileCandidates() throws {
        let suiteName = "MeowPlannerWidgetSnapshotCandidateTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let missingFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).json")
        let fallbackFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("fallback-\(UUID().uuidString).json")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fallbackFileURL)
        }
        let snapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Candidate file event", startDate: try date("2026-06-03 20:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-03 13:00")
        )

        WidgetPlannerSnapshotStore.save(snapshot, defaults: defaults, fileURL: fallbackFileURL)
        let restored = try #require(
            WidgetPlannerSnapshotStore.load(defaults: defaults, fileURLs: [missingFileURL, fallbackFileURL])
        )

        #expect(restored.plannerEvents.first?.title == "Candidate file event")
    }

    @Test("snapshot file candidates prefer widget sandbox when sandbox home differs")
    func snapshotFileCandidatesPreferWidgetSandboxWhenSandboxHomeDiffers() throws {
        let sandboxHome = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data")
        let accountHome = URL(fileURLWithPath: "/Users/xyue")
        let widgetSandboxSnapshotURL = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")
        let accountGroupSnapshotURL = URL(fileURLWithPath: "/Users/xyue/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: nil,
            homeDirectory: sandboxHome,
            accountHomeDirectory: accountHome
        )

        #expect(urls.first == widgetSandboxSnapshotURL)
        #expect(urls.contains(accountGroupSnapshotURL))
        #expect(urls.firstIndex(of: widgetSandboxSnapshotURL)! < urls.firstIndex(of: accountGroupSnapshotURL)!)
    }

    @Test("snapshot file candidates include widget sandbox when app home differs")
    func snapshotFileCandidatesIncludeWidgetSandboxWhenAppHomeDiffers() throws {
        let appHome = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner/Data")
        let accountHome = URL(fileURLWithPath: "/Users/xyue")

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: nil,
            homeDirectory: appHome,
            accountHomeDirectory: accountHome
        )

        #expect(urls.contains(URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")))
    }

    @Test("snapshot builder reads newly saved schedules from model context")
    func snapshotBuilderReadsNewlySavedSchedulesFromModelContext() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let event = PlannerEvent(title: "Fresh widget class", startDate: try date("2026-06-03 12:00"))

        context.insert(event)
        try context.save()

        let snapshot = try WidgetPlannerSnapshotBuilder.makeSnapshot(using: context)

        #expect(snapshot.plannerEvents.map(\.title).contains("Fresh widget class"))
    }

    @Test("snapshot builder reads completed schedule display preferences")
    func snapshotBuilderReadsCompletedScheduleDisplayPreferences() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let preference = PlannerPreference(
            showCompletedSchedules: false,
            completedSchedulesUseStrikethrough: false
        )

        context.insert(preference)
        try context.save()

        let snapshot = try WidgetPlannerSnapshotBuilder.makeSnapshot(using: context)

        #expect(snapshot.showCompletedSchedules == false)
        #expect(snapshot.completedSchedulesUseStrikethrough == false)
    }

    private func date(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try #require(formatter.date(from: value))
    }

}
