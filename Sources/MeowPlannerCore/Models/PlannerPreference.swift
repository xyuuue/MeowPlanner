import Foundation
import SwiftData

public enum AppAppearancePreferencePlatform: String, CaseIterable, Identifiable, Sendable {
    case macOS
    case iOS

    public var id: String { rawValue }

    public static var current: AppAppearancePreferencePlatform {
        #if os(iOS)
        .iOS
        #else
        .macOS
        #endif
    }

    public var storageKey: String {
        switch self {
        case .macOS: "meowplanner.appearance.preference.macOS"
        case .iOS: "meowplanner.appearance.preference.iOS"
        }
    }

    public var updatedAtStorageKey: String {
        switch self {
        case .macOS: "meowplanner.appearance.preference.macOS.updatedAt"
        case .iOS: "meowplanner.appearance.preference.iOS.updatedAt"
        }
    }

    public var cloudIDField: String {
        switch self {
        case .macOS: "macOSAppearanceID"
        case .iOS: "iOSAppearanceID"
        }
    }

    public var cloudUpdatedAtField: String {
        switch self {
        case .macOS: "macOSAppearanceUpdatedAt"
        case .iOS: "iOSAppearanceUpdatedAt"
        }
    }
}

public enum AppAppearancePreference: String, CaseIterable, Identifiable, Sendable {
    public static let legacyStorageKey = "meowplanner.appearance.preference"
    public static let legacyUpdatedAtStorageKey = "meowplanner.appearance.preference.updatedAt"
    public static let legacyCloudIDField = "appearanceID"
    public static let legacyCloudUpdatedAtField = "appearanceUpdatedAt"

    public static var currentPlatform: AppAppearancePreferencePlatform {
        AppAppearancePreferencePlatform.current
    }

    public static var storageKey: String {
        currentPlatform.storageKey
    }

    public static var updatedAtStorageKey: String {
        currentPlatform.updatedAtStorageKey
    }

    case system
    case light
    case dark

    public var id: String { rawValue }

    public init(storedValue: String) {
        self = AppAppearancePreference(rawValue: storedValue) ?? .system
    }

    public static func migrateLegacyValueIfNeeded(in defaults: UserDefaults = .standard) {
        let platform = currentPlatform
        guard defaults.object(forKey: platform.storageKey) == nil,
              let legacyValue = defaults.string(forKey: legacyStorageKey) else {
            return
        }

        defaults.set(AppAppearancePreference(storedValue: legacyValue).rawValue, forKey: platform.storageKey)

        guard defaults.object(forKey: platform.updatedAtStorageKey) == nil,
              let legacyUpdatedAt = defaults.object(forKey: legacyUpdatedAtStorageKey) else {
            return
        }
        defaults.set(legacyUpdatedAt, forKey: platform.updatedAtStorageKey)
    }

    public func title(language: AppLanguage) -> String {
        switch self {
        case .system:
            switch language {
            case .english: "Follow System"
            case .chinese: "跟随系统"
            }
        case .light:
            switch language {
            case .english: "Light"
            case .chinese: "浅色"
            }
        case .dark:
            switch language {
            case .english: "Dark"
            case .chinese: "深色"
            }
        }
    }
}

public enum TimeDisplayPreference: String, CaseIterable, Identifiable, Sendable {
    case twentyFourHour = "24"
    case twelveHour = "12"

    public var id: String { rawValue }

    public func title(language: AppLanguage) -> String {
        switch self {
        case .twentyFourHour:
            switch language {
            case .english: "24-hour"
            case .chinese: "24 小时"
            }
        case .twelveHour:
            switch language {
            case .english: "12-hour"
            case .chinese: "12 小时"
            }
        }
    }
}

@Model
public final class PlannerPreference {
    @Attribute(.unique) public var id: String
    public var localeIdentifier: String
    public var defaultFocusMinutes: Int
    public var cloudKitContainerIdentifier: String
    public var showFuFuTheme: Bool
    public var notificationLeadMinutes: Int
    public var weekStartDayRawValue: Int = WeekStartPreference.sunday.rawValue
    public var localRemindersEnabled: Bool = true
    public var eventColorHexList: String = PlannerPreference.defaultEventColorHexes.joined(separator: ",")
    public var eventTagNameList: String = PlannerPreference.defaultEventTagNames.joined(separator: ",")
    public var defaultEventIsAllDay: Bool = false
    public var showCompletedSchedules: Bool = true
    public var completedSchedulesUseStrikethrough: Bool = true
    public var showChineseCalendar: Bool = true
    public var scheduleTimeCollapseEnabled: Bool = true
    public var scheduleCollapsedStartHour: Int = 0
    public var scheduleCollapsedEndHour: Int = 6
    public var timeDisplayRawValue: String = TimeDisplayPreference.twentyFourHour.rawValue
    public var updatedAt: Date = PlannerPreference.baselineUpdatedAt

    public init(
        id: String = "default",
        localeIdentifier: String = "en",
        defaultFocusMinutes: Int = 25,
        cloudKitContainerIdentifier: String = ModelContainerFactory.cloudKitContainerIdentifier,
        showFuFuTheme: Bool = true,
        notificationLeadMinutes: Int = 10,
        weekStartPreference: WeekStartPreference = .sunday,
        localRemindersEnabled: Bool = true,
        eventColorHexes: [String] = PlannerPreference.defaultEventColorHexes,
        eventTagNames: [String] = PlannerPreference.defaultEventTagNames,
        defaultEventIsAllDay: Bool = false,
        showCompletedSchedules: Bool = true,
        completedSchedulesUseStrikethrough: Bool = true,
        showChineseCalendar: Bool = true,
        scheduleTimeCollapseEnabled: Bool = true,
        scheduleCollapsedStartHour: Int = 0,
        scheduleCollapsedEndHour: Int = 6,
        timeDisplayPreference: TimeDisplayPreference = .twentyFourHour,
        updatedAt: Date = PlannerPreference.baselineUpdatedAt
    ) {
        self.id = id
        self.localeIdentifier = localeIdentifier
        self.defaultFocusMinutes = defaultFocusMinutes
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
        self.showFuFuTheme = showFuFuTheme
        self.notificationLeadMinutes = notificationLeadMinutes
        self.weekStartDayRawValue = weekStartPreference.rawValue
        self.localRemindersEnabled = localRemindersEnabled
        self.eventColorHexList = PlannerPreference.normalizedEventColorHexes(eventColorHexes).joined(separator: ",")
        self.eventTagNameList = PlannerPreference.normalizedEventTagNames(eventTagNames).joined(separator: ",")
        self.defaultEventIsAllDay = defaultEventIsAllDay
        self.showCompletedSchedules = showCompletedSchedules
        self.completedSchedulesUseStrikethrough = completedSchedulesUseStrikethrough
        self.showChineseCalendar = showChineseCalendar
        self.scheduleTimeCollapseEnabled = scheduleTimeCollapseEnabled
        let collapsedRange = PlannerPreference.normalizedCollapsedHourRange(start: scheduleCollapsedStartHour, end: scheduleCollapsedEndHour)
        self.scheduleCollapsedStartHour = collapsedRange.start
        self.scheduleCollapsedEndHour = collapsedRange.end
        self.timeDisplayRawValue = timeDisplayPreference.rawValue
        self.updatedAt = updatedAt
    }

    public static let defaultEventColorHexes = [
        "#F57C6E",
        "#F2B56F",
        "#FAE69E",
        "#84C3B7",
        "#88D8DB",
        "#71B7ED",
        "#B8AEEB",
        "#F2A7DA"
    ]

    public static let defaultEventTagNames = [
        "工作",
        "生活",
        "旅行",
        "学习",
        "作业"
    ]

    public static let baselineUpdatedAt = Date(timeIntervalSince1970: 0)

    public static var defaults: PlannerPreference {
        PlannerPreference()
    }

    public var weekStartPreference: WeekStartPreference {
        get {
            WeekStartPreference(rawValue: weekStartDayRawValue) ?? .sunday
        }
        set {
            weekStartDayRawValue = newValue.rawValue
        }
    }

    public var eventColorHexes: [String] {
        get {
            let colors = eventColorHexList
                .split(separator: ",")
                .compactMap { PlannerPreference.normalizedHex(String($0)) }
            return colors.isEmpty ? PlannerPreference.defaultEventColorHexes : colors
        }
        set {
            eventColorHexList = PlannerPreference.normalizedEventColorHexes(newValue).joined(separator: ",")
        }
    }

    public var eventTagNames: [String] {
        get {
            let tags = eventTagNameList
                .split(separator: ",")
                .map { String($0) }
                .map(Self.normalizedTagName)
                .filter { !$0.isEmpty }
            return tags.isEmpty ? PlannerPreference.defaultEventTagNames : tags
        }
        set {
            eventTagNameList = PlannerPreference.normalizedEventTagNames(newValue).joined(separator: ",")
        }
    }

    public var timeDisplayPreference: TimeDisplayPreference {
        get {
            TimeDisplayPreference(rawValue: timeDisplayRawValue) ?? .twentyFourHour
        }
        set {
            timeDisplayRawValue = newValue.rawValue
        }
    }

    public static func normalizedEventColorHexes(_ values: [String]) -> [String] {
        let colors = values.reduce(into: [String]()) { result, value in
            guard let normalized = normalizedHex(value), !result.contains(normalized) else {
                return
            }
            result.append(normalized)
        }
        return colors.isEmpty ? defaultEventColorHexes : colors
    }

    public static func normalizedEventTagNames(_ values: [String]) -> [String] {
        let tags = values.reduce(into: [String]()) { result, value in
            let normalized = normalizedTagName(value)
            guard !normalized.isEmpty, !result.contains(normalized) else {
                return
            }
            result.append(normalized)
        }
        return tags.isEmpty ? defaultEventTagNames : tags
    }

    public static func eventTagOptions(configuredTags: [String], assignedTagNames: [String]) -> [String] {
        normalizedEventTagNames(configuredTags + assignedTagNames)
    }

    public func markUpdated(at date: Date = Date()) {
        updatedAt = date
    }

    public static func normalizedCollapsedHourRange(start: Int, end: Int) -> (start: Int, end: Int) {
        let normalizedStart = min(max(start, 0), 22)
        let normalizedEnd = min(max(end, normalizedStart + 1), 23)
        return (normalizedStart, normalizedEnd)
    }

    public static func normalizedTagName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedHex(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutHash = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard withoutHash.count == 6,
              withoutHash.allSatisfy({ $0.isHexDigit }) else {
            return nil
        }
        return "#\(withoutHash.uppercased())"
    }
}
