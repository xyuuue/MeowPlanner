import AppIntents
import Foundation
import WidgetKit

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerCoreAppIntentsPackage: AppIntentsPackage {}

public enum WidgetScheduleDisplayRule: String, AppEnum, CaseIterable, Codable, Sendable {
    case nextSevenDays
    case calendarWeek

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "显示规则")

    public static var caseDisplayRepresentations: [WidgetScheduleDisplayRule: DisplayRepresentation] {
        [
            .nextSevenDays: DisplayRepresentation(title: "未来七天"),
            .calendarWeek: DisplayRepresentation(title: "自然周")
        ]
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerWidgetConfigurationIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "MeowPlanner Widget"
    public static let description = IntentDescription("Configure what the MeowPlanner widget shows.")

    @Parameter(title: "显示规则", default: WidgetScheduleDisplayRule.nextSevenDays)
    public var scheduleDisplayRule: WidgetScheduleDisplayRule

    public init() {
        scheduleDisplayRule = .nextSevenDays
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct ChangeWidgetMonthIntent: AppIntent {
    public static let title: LocalizedStringResource = "Change MeowPlanner Widget Month"
    public static let isDiscoverable = false
    public static let openAppWhenRun = false

    @Parameter(title: "Month Delta")
    public var monthDelta: Int

    public init() {
        monthDelta = 0
    }

    public init(monthDelta: Int) {
        self.monthDelta = monthDelta
    }

    public func perform() async throws -> some IntentResult {
        WidgetMonthSelectionStore.adjustMonthOffset(by: monthDelta)
        #if os(iOS)
        WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension()
        await WidgetIntentTimelineReloader.reloadAllTimelinesRepeatedly()
        #else
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
        #endif
        return .result()
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct ChangeWidgetWeekIntent: AppIntent {
    public static let title: LocalizedStringResource = "Change MeowPlanner Widget Week"
    public static let isDiscoverable = false
    public static let openAppWhenRun = false

    @Parameter(title: "Week Delta")
    public var weekDelta: Int

    public init() {
        weekDelta = 0
    }

    public init(weekDelta: Int) {
        self.weekDelta = weekDelta
    }

    public func perform() async throws -> some IntentResult {
        WidgetWeekSelectionStore.adjustWeekOffset(by: weekDelta)
        #if os(iOS)
        WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension()
        await WidgetIntentTimelineReloader.reloadAllTimelinesRepeatedly()
        #else
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
        #endif
        return .result()
    }
}

#if os(iOS)
private enum WidgetIntentTimelineReloader {
    private static let refreshPauses: [UInt64] = [
        0,
        120_000_000,
        250_000_000,
        500_000_000,
        900_000_000,
        1_500_000_000,
        2_500_000_000
    ]

    static func reloadAllTimelinesRepeatedly() async {
        for pause in refreshPauses {
            if pause > 0 {
                try? await Task.sleep(nanoseconds: pause)
            }

            WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
#endif

@available(iOS 17.0, macOS 14.0, *)
public struct RefreshWidgetTimelineIntent: AppIntent {
    public static let title: LocalizedStringResource = "Refresh MeowPlanner Widget"
    public static let isDiscoverable = false
    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension()

        #if os(iOS)
        await WidgetIntentTimelineReloader.reloadAllTimelinesRepeatedly()
        #else
        // WidgetKit often needs a short post-editing sync window before the newest snapshot
        // is available across processes, so we use a retry loop to guarantee a fresh timeline.
        let refreshPauses: [UInt64] = [0, 120_000_000, 250_000_000, 500_000_000, 900_000_000, 1_500_000_000, 2_500_000_000]

        for pause in refreshPauses {
            if pause > 0 {
                try? await Task.sleep(nanoseconds: pause)
            }

            WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif

        return .result()
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct ReturnWidgetToTodayIntent: AppIntent {
    public static let title: LocalizedStringResource = "Return MeowPlanner Widget to Today"
    public static let isDiscoverable = false
    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        WidgetWeekSelectionStore.resetWeekOffset()
        WidgetMonthSelectionStore.resetMonthOffset()
        WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension()

        #if os(iOS)
        await WidgetIntentTimelineReloader.reloadAllTimelinesRepeatedly()
        #else
        let refreshPauses: [UInt64] = [0, 120_000_000, 250_000_000, 500_000_000, 900_000_000, 1_500_000_000, 2_500_000_000]

        for pause in refreshPauses {
            if pause > 0 {
                try? await Task.sleep(nanoseconds: pause)
            }

            WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif

        return .result()
    }
}

public enum WidgetWeekSelectionStore {
    private static let widgetWeekOffsetKey = WidgetConstants.widgetWeekOffsetKey

    public static var currentWeekOffset: Int {
        currentWeekOffset(platform: .current)
    }

    static func currentWeekOffset(platform: WidgetPreferencePlatform) -> Int {
        WidgetDateOffsetStore.currentOffset(forKey: widgetWeekOffsetKey, platform: platform)
    }

    public static func adjustWeekOffset(by delta: Int) {
        adjustWeekOffset(by: delta, platform: .current)
    }

    static func adjustWeekOffset(by delta: Int, platform: WidgetPreferencePlatform) {
        let nextValue = max(-260, min(260, currentWeekOffset(platform: platform) + delta))
        WidgetDateOffsetStore.setOffset(nextValue, forKey: widgetWeekOffsetKey, platform: platform)
    }

    public static func resetWeekOffset() {
        resetWeekOffset(platform: .current)
    }

    static func resetWeekOffset(platform: WidgetPreferencePlatform) {
        WidgetDateOffsetStore.setOffset(0, forKey: widgetWeekOffsetKey, platform: platform)
    }
}

public enum WidgetMonthSelectionStore {
    private static let widgetMonthOffsetKey = WidgetConstants.widgetMonthOffsetKey

    public static var currentMonthOffset: Int {
        currentMonthOffset(platform: .current)
    }

    static func currentMonthOffset(platform: WidgetPreferencePlatform) -> Int {
        WidgetDateOffsetStore.currentOffset(forKey: widgetMonthOffsetKey, platform: platform)
    }

    public static func adjustMonthOffset(by delta: Int) {
        adjustMonthOffset(by: delta, platform: .current)
    }

    static func adjustMonthOffset(by delta: Int, platform: WidgetPreferencePlatform) {
        let nextValue = max(-24, min(24, currentMonthOffset(platform: platform) + delta))
        WidgetDateOffsetStore.setOffset(nextValue, forKey: widgetMonthOffsetKey, platform: platform)
    }

    public static func resetMonthOffset() {
        resetMonthOffset(platform: .current)
    }

    static func resetMonthOffset(platform: WidgetPreferencePlatform) {
        WidgetDateOffsetStore.setOffset(0, forKey: widgetMonthOffsetKey, platform: platform)
    }
}

private enum WidgetDateOffsetStore {
    static func currentOffset(forKey key: String, platform: WidgetPreferencePlatform) -> Int {
        currentOffset(
            forKey: key,
            sharedDefaults: defaults(for: platform),
            legacyDefaults: .standard
        )
    }

    static func setOffset(_ value: Int, forKey key: String, platform: WidgetPreferencePlatform) {
        setOffset(value, forKey: key, sharedDefaults: defaults(for: platform))
    }

    private static func currentOffset(
        forKey key: String,
        sharedDefaults: UserDefaults,
        legacyDefaults: UserDefaults
    ) -> Int {
        if sharedDefaults.object(forKey: key) != nil {
            return sharedDefaults.integer(forKey: key)
        }

        guard legacyDefaults.object(forKey: key) != nil else {
            return 0
        }

        let migratedValue = legacyDefaults.integer(forKey: key)
        setOffset(migratedValue, forKey: key, sharedDefaults: sharedDefaults)
        return migratedValue
    }

    private static func setOffset(_ value: Int, forKey key: String, sharedDefaults: UserDefaults) {
        sharedDefaults.set(value, forKey: key)
        sharedDefaults.synchronize()
    }

    private static func defaults(for platform: WidgetPreferencePlatform) -> UserDefaults {
        switch platform {
        case .iOS:
            UserDefaults(suiteName: WidgetConstants.appGroupName) ?? .standard
        case .macOS:
            .standard
        }
    }
}
