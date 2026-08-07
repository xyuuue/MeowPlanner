import AppIntents
import MeowPlannerCore
import WidgetKit

@available(iOS 17.0, macOS 14.0, *)
struct MeowPlannerWidgetIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        #if os(iOS)
        []
        #else
        [MeowPlannerCoreAppIntentsPackage.self]
        #endif
    }
}

#if os(iOS)
@available(iOS 17.0, *)
public enum MeowPlannerWidgetScheduleDisplayRule: String, AppEnum, CaseIterable, Codable, Sendable {
    case nextSevenDays
    case calendarWeek

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "显示规则")

    public static var caseDisplayRepresentations: [MeowPlannerWidgetScheduleDisplayRule: DisplayRepresentation] {
        [
            .nextSevenDays: DisplayRepresentation(title: "未来七天"),
            .calendarWeek: DisplayRepresentation(title: "自然周")
        ]
    }
}

@available(iOS 17.0, *)
public struct MeowPlannerWidgetLocalConfigurationIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "MeowPlanner Widget"
    public static let description = IntentDescription("Configure what the MeowPlanner widget shows.")

    @Parameter(title: "显示规则", default: MeowPlannerWidgetScheduleDisplayRule.nextSevenDays)
    public var scheduleDisplayRule: MeowPlannerWidgetScheduleDisplayRule

    public init() {
        scheduleDisplayRule = .nextSevenDays
    }
}
#endif
