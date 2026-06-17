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
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
        return .result()
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct ChangeWidgetWeekIntent: AppIntent {
    public static let title: LocalizedStringResource = "Change MeowPlanner Widget Week"
    public static let isDiscoverable = false

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
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
        return .result()
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct RefreshWidgetTimelineIntent: AppIntent {
    public static let title: LocalizedStringResource = "Refresh MeowPlanner Widget"
    public static let isDiscoverable = false
    public static let openAppWhenRun = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        WidgetPlannerSnapshotStore.refreshSharedSnapshotForWidgetExtension()

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

        return .result()
    }
}

public enum WidgetWeekSelectionStore {
    private static let widgetWeekOffsetKey = WidgetConstants.widgetWeekOffsetKey

    public static var currentWeekOffset: Int {
        defaults.integer(forKey: widgetWeekOffsetKey)
    }

    public static func adjustWeekOffset(by delta: Int) {
        let nextValue = max(-260, min(260, currentWeekOffset + delta))
        defaults.set(nextValue, forKey: widgetWeekOffsetKey)
    }

    private static var defaults: UserDefaults {
        .standard
    }
}

public enum WidgetMonthSelectionStore {
    private static let widgetMonthOffsetKey = WidgetConstants.widgetMonthOffsetKey

    public static var currentMonthOffset: Int {
        defaults.integer(forKey: widgetMonthOffsetKey)
    }

    public static func adjustMonthOffset(by delta: Int) {
        let nextValue = max(-24, min(24, currentMonthOffset + delta))
        defaults.set(nextValue, forKey: widgetMonthOffsetKey)
    }

    private static var defaults: UserDefaults {
        .standard
    }
}
