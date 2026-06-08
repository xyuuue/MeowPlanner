import MeowPlannerCore
import SwiftUI
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

enum AppSection: String, CaseIterable, Identifiable {
    case calendar
    case todo
    case schedule
    case timetable
    case focus
    case settings

    var id: String { rawValue }

    static let defaultSidebarOrder: [AppSection] = [
        .calendar,
        .todo,
        .schedule,
        .timetable,
        .focus,
        .settings
    ]

    static let defaultSidebarOrderStorageValue = sidebarStorageValue(for: defaultSidebarOrder)

    static func sidebarStorageValue(for sections: [AppSection]) -> String {
        sections.map(\.rawValue).joined(separator: ",")
    }

    static func orderedSections(from storageValue: String) -> [AppSection] {
        var orderedSections = [AppSection]()

        for rawValue in storageValue.split(separator: ",") {
            guard let section = AppSection(rawValue: String(rawValue)),
                  !orderedSections.contains(section)
            else {
                continue
            }
            orderedSections.append(section)
        }

        for section in defaultSidebarOrder where !orderedSections.contains(section) {
            orderedSections.append(section)
        }

        return orderedSections
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .calendar: PlannerCopy.text(.calendar, language: language)
        case .todo: PlannerCopy.text(.todo, language: language)
        case .schedule: PlannerCopy.text(.schedule, language: language)
        case .timetable: PlannerCopy.text(.timetable, language: language)
        case .focus: PlannerCopy.text(.focus, language: language)
        case .settings: PlannerCopy.text(.settings, language: language)
        }
    }

    var systemImage: String {
        switch self {
        case .calendar: "calendar"
        case .todo: "checklist"
        case .schedule: "calendar.badge.clock"
        case .timetable: "tablecells"
        case .focus: "timer"
        case .settings: "gearshape"
        }
    }
}

extension Notification.Name {
    static let meowPlannerOpenSection = Notification.Name("meowplanner.openSection")
    static let meowPlannerRestoreMainWindow = Notification.Name("meowplanner.restoreMainWindow")
    static let meowPlannerExternalOpenURL = Notification.Name("meowplanner.externalOpenURL")
}

enum AppNavigationRequest {
    static func open(_ section: AppSection) {
        NotificationCenter.default.post(name: .meowPlannerOpenSection, object: section.rawValue)
    }

    static func openCalendar() {
        AppNavigationRequest.open(.calendar)
    }

    static func openFocus() {
        AppNavigationRequest.open(.focus)
    }

    static func openSettings() {
        AppNavigationRequest.open(.settings)
    }
}
