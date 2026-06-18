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

    @Test("widget background preference stores style and custom image data")
    func widgetBackgroundPreferenceStoresStyleAndCustomImageData() throws {
        let suiteName = "MeowPlannerWidgetBackgroundTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetBackground-\(UUID().uuidString).image")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: fileURL)
        }

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults) == .defaultArtwork)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.transparent, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults) == .defaultArtwork)

        let data = Data([0x4d, 0x65, 0x6f, 0x77])
        try WidgetPlannerPreferenceStore.saveCustomBackgroundImageData(data, fileURL: fileURL)

        #expect(try Data(contentsOf: fileURL) == data)

        WidgetPlannerPreferenceStore.clearCustomBackgroundImage(fileURL: fileURL)

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("widget appearance preference overrides system appearance when requested")
    func widgetAppearancePreferenceOverridesSystemAppearanceWhenRequested() throws {
        let suiteName = "MeowPlannerWidgetAppearanceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(defaults: defaults) == .system)
        #expect(WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: true, defaults: defaults))
        #expect(!WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: false, defaults: defaults))

        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.dark, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(defaults: defaults) == .dark)
        #expect(WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: false, defaults: defaults))

        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.light, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(defaults: defaults) == .light)
        #expect(!WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: true, defaults: defaults))
    }

    @Test("widget visual preferences stay separate between macOS and iOS")
    func widgetVisualPreferencesStaySeparateBetweenMacOSAndIOS() throws {
        let suiteName = "MeowPlannerWidgetPlatformPreferenceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set(WidgetBackgroundStyle.defaultArtwork.rawValue, forKey: WidgetPlannerPreferenceStore.widgetBackgroundStyleKey)
        defaults.set(AppAppearancePreference.dark.rawValue, forKey: WidgetPlannerPreferenceStore.widgetAppearancePreferenceKey)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .iOS, defaults: defaults) == .dark)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .macOS, defaults: defaults) == .system)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.customPhoto, platform: .iOS, defaults: defaults)
        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.light, platform: .iOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .customPhoto)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .iOS, defaults: defaults) == .light)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .macOS, defaults: defaults) == .system)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.defaultArtwork, platform: .macOS, defaults: defaults)
        WidgetPlannerPreferenceStore.setWidgetAppearancePreference(.dark, platform: .macOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .customPhoto)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .iOS, defaults: defaults) == .light)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetAppearancePreference(platform: .macOS, defaults: defaults) == .dark)
    }

    @Test("widget background preference falls back to mirrored style file")
    func widgetBackgroundPreferenceFallsBackToMirroredStyleFile() throws {
        let suiteName = "MeowPlannerWidgetBackgroundFallbackTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let styleFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetBackgroundStyle-\(UUID().uuidString).txt")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: styleFileURL)
        }

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults, styleFileURLs: [styleFileURL]) == .defaultArtwork)

        try "defaultArtwork".write(to: styleFileURL, atomically: true, encoding: .utf8)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults, styleFileURLs: [styleFileURL]) == .defaultArtwork)

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.customPhoto, defaults: defaults, styleFileURLs: [styleFileURL])

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults, styleFileURLs: [styleFileURL]) == .customPhoto)
        #expect(try String(contentsOf: styleFileURL, encoding: .utf8) == "customPhoto")

        try? FileManager.default.removeItem(at: styleFileURL)
        defaults.set(WidgetBackgroundStyle.defaultArtwork.rawValue, forKey: WidgetPreferencePlatform.macOS.widgetBackgroundStyleKey)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(defaults: defaults, styleFileURLs: [styleFileURL]) == .defaultArtwork)
        #expect(try String(contentsOf: styleFileURL, encoding: .utf8) == "defaultArtwork")
    }

    @Test("macOS widget background does not use transparent style")
    func macOSWidgetBackgroundDoesNotUseTransparentStyle() throws {
        let suiteName = "MeowPlannerWidgetMacOSSolidBackgroundTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let styleFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerMacOSWidgetBackgroundStyle-\(UUID().uuidString).txt")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: styleFileURL)
        }

        #expect(WidgetPreferencePlatform.macOS.defaultWidgetBackgroundStyle == .defaultArtwork)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)

        defaults.set(
            WidgetBackgroundStyle.transparent.rawValue,
            forKey: WidgetPreferencePlatform.macOS.widgetBackgroundStyleKey
        )

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)

        defaults.removeObject(forKey: WidgetPreferencePlatform.macOS.widgetBackgroundStyleKey)
        try WidgetBackgroundStyle.transparent.rawValue.write(to: styleFileURL, atomically: true, encoding: .utf8)

        #expect(
            WidgetPlannerPreferenceStore.widgetBackgroundStyle(
                platform: .macOS,
                defaults: defaults,
                styleFileURLs: [styleFileURL]
            ) == .defaultArtwork
        )

        WidgetPlannerPreferenceStore.setWidgetBackgroundStyle(.transparent, platform: .iOS, defaults: defaults)

        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .iOS, defaults: defaults) == .transparent)
        #expect(WidgetPlannerPreferenceStore.widgetBackgroundStyle(platform: .macOS, defaults: defaults) == .defaultArtwork)
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

    @Test("weekly schedule planner uses next seven days and filters completed schedules")
    func weeklySchedulePlannerUsesNextSevenDaysAndFiltersCompletedSchedules() throws {
        let visibleEvent = PlannerEvent(
            title: "Studio review",
            startDate: try date("2026-06-16 09:00"),
            endDate: try date("2026-06-16 10:00")
        )
        let completedEvent = PlannerEvent(
            title: "Completed meeting",
            startDate: try date("2026-06-17 11:00"),
            isCompleted: true,
            completedAt: try date("2026-06-17 12:00")
        )
        let outsideEvent = PlannerEvent(
            title: "Outside range",
            startDate: try date("2026-06-23 09:00")
        )

        let days = WidgetWeeklySchedulePlanner.days(
            anchorDate: try date("2026-06-16 08:00"),
            displayRule: WidgetScheduleDisplayRule.nextSevenDays,
            events: [visibleEvent, completedEvent, outsideEvent].map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: WeekStartPreference.monday,
            showCompletedSchedules: false,
            calendar: calendar
        )
        let expectedStart = try date("2026-06-16 00:00")

        #expect(days.map { calendar.startOfDay(for: $0.date) } == (0..<7).map {
            calendar.date(byAdding: .day, value: $0, to: expectedStart)!
        })
        #expect(days.flatMap(\.events).map(\.title) == ["Studio review"])
    }

    @Test("weekly schedule planner uses configured week start for natural week")
    func weeklySchedulePlannerUsesConfiguredWeekStartForNaturalWeek() throws {
        let sundayEvent = PlannerEvent(
            title: "Sunday planning",
            startDate: try date("2026-06-14 10:00")
        )
        let mondayEvent = PlannerEvent(
            title: "Monday class",
            startDate: try date("2026-06-15 10:00")
        )

        let days = WidgetWeeklySchedulePlanner.days(
            anchorDate: try date("2026-06-18 12:00"),
            displayRule: WidgetScheduleDisplayRule.calendarWeek,
            events: [sundayEvent, mondayEvent].map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: WeekStartPreference.monday,
            showCompletedSchedules: true,
            calendar: calendar
        )
        let expectedWeekStart = try date("2026-06-15 00:00")
        let expectedWeekEnd = try date("2026-06-21 00:00")

        #expect(calendar.startOfDay(for: days[0].date) == expectedWeekStart)
        #expect(calendar.startOfDay(for: days[6].date) == expectedWeekEnd)
        #expect(days.flatMap(\.events).map(\.title) == ["Monday class"])
    }

    @Test("weekly schedule planner applies week offset to both display rules")
    func weeklySchedulePlannerAppliesWeekOffsetToBothDisplayRules() throws {
        let nextWeekEvent = PlannerEvent(
            title: "Next week review",
            startDate: try date("2026-06-23 09:00")
        )
        let previousNaturalWeekEvent = PlannerEvent(
            title: "Previous week planning",
            startDate: try date("2026-06-09 10:00")
        )

        let shiftedNextSevenDays = WidgetWeeklySchedulePlanner.days(
            anchorDate: try date("2026-06-16 08:00"),
            displayRule: WidgetScheduleDisplayRule.nextSevenDays,
            events: [nextWeekEvent].map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: WeekStartPreference.monday,
            showCompletedSchedules: true,
            weekOffset: 1,
            calendar: calendar
        )
        let shiftedNaturalWeek = WidgetWeeklySchedulePlanner.days(
            anchorDate: try date("2026-06-18 12:00"),
            displayRule: WidgetScheduleDisplayRule.calendarWeek,
            events: [previousNaturalWeekEvent].map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: WeekStartPreference.monday,
            showCompletedSchedules: true,
            weekOffset: -1,
            calendar: calendar
        )
        let expectedNextSevenDaysStart = try date("2026-06-23 00:00")
        let expectedNaturalWeekStart = try date("2026-06-08 00:00")

        #expect(calendar.startOfDay(for: shiftedNextSevenDays[0].date) == expectedNextSevenDaysStart)
        #expect(shiftedNextSevenDays.flatMap(\.events).map(\.title) == ["Next week review"])
        #expect(calendar.startOfDay(for: shiftedNaturalWeek[0].date) == expectedNaturalWeekStart)
        #expect(shiftedNaturalWeek.flatMap(\.events).map(\.title) == ["Previous week planning"])
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

    @Test("snapshot refresh mirrors newest snapshot into every widget file candidate")
    func snapshotRefreshMirrorsNewestSnapshotIntoEveryWidgetFileCandidate() throws {
        let suiteName = "MeowPlannerWidgetSnapshotRefreshTests-\(UUID().uuidString)"
        let standardSuiteName = "MeowPlannerWidgetSnapshotStandardRefreshTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let standardDefaults = try #require(UserDefaults(suiteName: standardSuiteName))
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotRefresh-\(UUID().uuidString)")
        let staleMirrorURL = temporaryRoot
            .appendingPathComponent("WidgetSandbox")
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        let freshSharedURL = temporaryRoot
            .appendingPathComponent("SharedAppGroup")
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            standardDefaults.removePersistentDomain(forName: standardSuiteName)
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        let staleSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Old mirrored event", startDate: try date("2026-06-03 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-03 13:00")
        )
        let freshSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh mirrored event", startDate: try date("2026-06-14 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-14 13:00")
        )

        WidgetPlannerSnapshotStore.save(staleSnapshot, defaults: defaults, fileURL: staleMirrorURL)
        WidgetPlannerSnapshotStore.save(freshSnapshot, defaults: defaults, fileURL: freshSharedURL)

        let refreshed = try #require(WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension(
            defaults: defaults,
            standardDefaults: standardDefaults,
            fileURLs: [staleMirrorURL, freshSharedURL]
        ))
        let mirrored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURL: staleMirrorURL))
        let standardSnapshot = try #require(WidgetPlannerSnapshotStore.load(defaults: standardDefaults))

        #expect(refreshed.plannerEvents.first?.title == "Fresh mirrored event")
        #expect(mirrored.plannerEvents.first?.title == "Fresh mirrored event")
        #expect(standardSnapshot.plannerEvents.first?.title == "Fresh mirrored event")
    }

    @Test("snapshot loading chooses newest snapshot when widget sandbox mirror is stale")
    func snapshotLoadingChoosesNewestSnapshotWhenWidgetSandboxMirrorIsStale() throws {
        let suiteName = "MeowPlannerWidgetSnapshotStaleSandboxTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotStaleSandbox-\(UUID().uuidString)")
        let accountHome = temporaryRoot.appendingPathComponent("AccountHome")
        let widgetSandboxHome = accountHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent("com.yuelingqiu.MeowPlanner.MeowPlannerWidget")
            .appendingPathComponent("Data")
        let sharedSnapshotURL = accountHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        let staleWidgetSandboxSnapshotURL = widgetSandboxHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        let staleSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Stale widget sandbox event", startDate: try date("2026-06-03 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-03 13:00")
        )
        let freshSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh shared app group event", startDate: try date("2026-06-13 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-13 13:00")
        )

        WidgetPlannerSnapshotStore.save(staleSnapshot, defaults: defaults, fileURL: staleWidgetSandboxSnapshotURL)
        WidgetPlannerSnapshotStore.save(freshSnapshot, defaults: defaults, fileURL: sharedSnapshotURL)

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: nil,
            homeDirectory: widgetSandboxHome,
            accountHomeDirectory: accountHome
        )
        let restored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURLs: urls))

        #expect(restored.plannerEvents.first?.title == "Fresh shared app group event")
        #expect(urls.contains(staleWidgetSandboxSnapshotURL))
    }

    @Test("snapshot loading chooses newest snapshot when widget sandbox container is stale")
    func snapshotLoadingChoosesNewestSnapshotWhenWidgetSandboxContainerIsStale() throws {
        let suiteName = "MeowPlannerWidgetSnapshotSandboxContainerURLTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowPlannerWidgetSnapshotSandboxContainerURL-\(UUID().uuidString)")
        let accountHome = temporaryRoot.appendingPathComponent("AccountHome")
        let widgetSandboxHome = accountHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent("com.yuelingqiu.MeowPlanner.MeowPlannerWidget")
            .appendingPathComponent("Data")
        let widgetSandboxContainerURL = widgetSandboxHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
        let staleWidgetSandboxSnapshotURL = widgetSandboxContainerURL
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        let sharedSnapshotURL = accountHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(WidgetPlannerSnapshotStore.snapshotFilename)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: temporaryRoot)
        }
        let staleSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Sandbox container stale event", startDate: try date("2026-06-03 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .sunday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-03 13:00")
        )
        let freshSnapshot = WidgetPlannerSnapshot(
            events: [PlannerEvent(title: "Fresh account app group event", startDate: try date("2026-06-14 09:00"))],
            todos: [],
            habitCount: 0,
            weekStartPreference: .monday,
            showChineseCalendar: true,
            updatedAt: try date("2026-06-14 13:00")
        )

        WidgetPlannerSnapshotStore.save(staleSnapshot, defaults: defaults, fileURL: staleWidgetSandboxSnapshotURL)
        WidgetPlannerSnapshotStore.save(freshSnapshot, defaults: defaults, fileURL: sharedSnapshotURL)

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: widgetSandboxContainerURL,
            homeDirectory: widgetSandboxHome,
            accountHomeDirectory: accountHome
        )
        let restored = try #require(WidgetPlannerSnapshotStore.load(defaults: defaults, fileURLs: urls))

        #expect(restored.plannerEvents.first?.title == "Fresh account app group event")
        #expect(urls.contains(sharedSnapshotURL))
        #expect(urls.contains(staleWidgetSandboxSnapshotURL))
    }

    @Test("snapshot file candidates include shared app group and widget sandbox mirror")
    func snapshotFileCandidatesIncludeSharedAppGroupAndWidgetSandboxMirror() throws {
        let sandboxHome = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data")
        let accountHome = URL(fileURLWithPath: "/Users/xyue")
        let widgetSandboxSnapshotURL = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")
        let accountGroupSnapshotURL = URL(fileURLWithPath: "/Users/xyue/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: nil,
            homeDirectory: sandboxHome,
            accountHomeDirectory: accountHome
        )

        #expect(urls.contains(accountGroupSnapshotURL))
        #expect(urls.contains(widgetSandboxSnapshotURL))
    }

    @Test("snapshot file candidates include widget sandbox mirror when app home differs")
    func snapshotFileCandidatesIncludeWidgetSandboxMirrorWhenAppHomeDiffers() throws {
        let appHome = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner/Data")
        let accountHome = URL(fileURLWithPath: "/Users/xyue")
        let widgetSandboxSnapshotURL = URL(fileURLWithPath: "/Users/xyue/Library/Containers/com.yuelingqiu.MeowPlanner.MeowPlannerWidget/Data/Library/Group Containers/group.com.yuelingqiu.MeowPlanner/widget-planner-snapshot.json")

        let urls = WidgetPlannerSnapshotStore.snapshotFileURLs(
            appGroupContainerURL: nil,
            homeDirectory: appHome,
            accountHomeDirectory: accountHome
        )

        #expect(urls.contains(widgetSandboxSnapshotURL))
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
