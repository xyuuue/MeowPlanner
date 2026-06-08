import AppIntents
import Foundation
import WidgetKit

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerCoreAppIntentsPackage: AppIntentsPackage {}

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
