import Foundation
import MeowPlannerCore
import SwiftData

@MainActor
final class AccountScopedModelContainerStore: ObservableObject {
    static let shared = AccountScopedModelContainerStore()

    @Published private(set) var modelContainer: ModelContainer?
    @Published private(set) var signedOutModelContainer: ModelContainer?
    @Published private(set) var signedOutWorkspaceID = UUID()
    @Published private(set) var activeUserID: String?
    @Published private(set) var loadError: Error?

    private static let legacyMigrationUserDefaultsKey = "meowplanner.account.legacyDataMigratedUserID"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        prepareSignedOutContainer()
    }

    func prepareContainer(for profile: AccountProfile?, legacyModelContainer: ModelContainer) {
        guard let userID = profile?.remoteUserID else {
            unloadAccountContainer()
            prepareSignedOutContainer()
            return
        }

        guard activeUserID != userID || modelContainer == nil else {
            return
        }

        do {
            let accountContainer = try ModelContainerFactory.makeAccountScoped(for: userID)
            try migrateLegacyLocalDataIfNeeded(
                from: legacyModelContainer,
                to: accountContainer,
                userID: userID
            )
            activeUserID = userID
            modelContainer = accountContainer
            loadError = nil
        } catch {
            activeUserID = nil
            modelContainer = nil
            loadError = error
        }
    }

    func prepareSignedOutContainer() {
        guard signedOutModelContainer == nil else {
            return
        }

        resetSignedOutContainer()
    }

    func unload() {
        unloadAccountContainer()
        resetSignedOutContainer()
    }

    private func unloadAccountContainer() {
        activeUserID = nil
        modelContainer = nil
        loadError = nil
    }

    private func resetSignedOutContainer() {
        do {
            signedOutModelContainer = try ModelContainerFactory.makeSignedOutWorkspace()
            signedOutWorkspaceID = UUID()
            loadError = nil
        } catch {
            signedOutModelContainer = nil
            loadError = error
        }
    }

    private func migrateLegacyLocalDataIfNeeded(
        from legacyContainer: ModelContainer,
        to accountContainer: ModelContainer,
        userID: String
    ) throws {
        guard defaults.string(forKey: Self.legacyMigrationUserDefaultsKey) == nil else {
            return
        }

        let legacyContext = ModelContext(legacyContainer)
        let accountContext = ModelContext(accountContainer)

        guard try !accountContextContainsPlannerData(accountContext) else {
            defaults.set(userID, forKey: Self.legacyMigrationUserDefaultsKey)
            return
        }

        try copyLegacyPlannerData(from: legacyContext, to: accountContext)
        if accountContext.hasChanges {
            try accountContext.save()
        }
        defaults.set(userID, forKey: Self.legacyMigrationUserDefaultsKey)
    }

    private func accountContextContainsPlannerData(_ modelContext: ModelContext) throws -> Bool {
        try contains(PlannerEvent.self, in: modelContext)
            || contains(TodoItem.self, in: modelContext)
            || contains(TodoGroup.self, in: modelContext)
            || contains(Habit.self, in: modelContext)
            || contains(HabitCheckIn.self, in: modelContext)
            || contains(FocusTag.self, in: modelContext)
            || contains(FocusSession.self, in: modelContext)
            || contains(PlannerPreference.self, in: modelContext)
            || contains(CourseTimetable.self, in: modelContext)
            || contains(CoursePeriod.self, in: modelContext)
            || contains(Course.self, in: modelContext)
            || contains(CourseSession.self, in: modelContext)
    }

    private func contains<T: PersistentModel>(_ type: T.Type, in modelContext: ModelContext) throws -> Bool {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        return try !modelContext.fetch(descriptor).isEmpty
    }

    private func copyLegacyPlannerData(from legacyContext: ModelContext, to accountContext: ModelContext) throws {
        for event in try fetch(PlannerEvent.self, in: legacyContext) {
            accountContext.insert(PlannerEvent(
                id: event.id,
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                notes: event.notes,
                isCompleted: event.isCompleted,
                completedAt: event.completedAt,
                reminderOffsetMinutes: event.reminderOffsetMinutes,
                repeatRule: event.repeatRule,
                tagName: event.tagName,
                colorHex: event.colorHex,
                createdAt: event.createdAt,
                updatedAt: event.updatedAt
            ))
        }

        for group in try fetch(TodoGroup.self, in: legacyContext) {
            accountContext.insert(TodoGroup(
                id: group.id,
                name: group.name,
                colorHex: group.colorHex,
                createdAt: group.createdAt,
                updatedAt: group.updatedAt
            ))
        }

        for todo in try fetch(TodoItem.self, in: legacyContext) {
            accountContext.insert(TodoItem(
                id: todo.id,
                title: todo.title,
                notes: todo.notes,
                dueDate: todo.dueDate,
                groupID: todo.groupID,
                sortOrder: todo.sortOrder,
                isCompleted: todo.isCompleted,
                completedAt: todo.completedAt,
                reminderDate: todo.reminderDate,
                createdAt: todo.createdAt,
                updatedAt: todo.updatedAt
            ))
        }

        for habit in try fetch(Habit.self, in: legacyContext) {
            accountContext.insert(Habit(
                id: habit.id,
                title: habit.title,
                symbolName: habit.symbolName,
                colorHex: habit.colorHex,
                reminderDate: habit.reminderDate,
                createdAt: habit.createdAt,
                archivedAt: habit.archivedAt
            ))
        }

        for checkIn in try fetch(HabitCheckIn.self, in: legacyContext) {
            accountContext.insert(HabitCheckIn(
                id: checkIn.id,
                habitID: checkIn.habitID,
                date: checkIn.date,
                note: checkIn.note,
                createdAt: checkIn.createdAt
            ))
        }

        for tag in try fetch(FocusTag.self, in: legacyContext) {
            accountContext.insert(FocusTag(
                id: tag.id,
                name: tag.name,
                colorHex: tag.colorHex,
                createdAt: tag.createdAt,
                sortOrder: tag.sortOrder
            ))
        }

        for session in try fetch(FocusSession.self, in: legacyContext) {
            accountContext.insert(FocusSession(
                id: session.id,
                title: session.title,
                startedAt: session.startedAt,
                endedAt: session.endedAt,
                plannedDurationSeconds: session.plannedDurationSeconds,
                completedDurationSeconds: session.completedDurationSeconds,
                linkedTodoID: session.linkedTodoID,
                linkedHabitID: session.linkedHabitID,
                tagID: session.tagID,
                mode: session.mode
            ))
        }

        for preference in try fetch(PlannerPreference.self, in: legacyContext) {
            accountContext.insert(PlannerPreference(
                id: preference.id,
                localeIdentifier: preference.localeIdentifier,
                defaultFocusMinutes: preference.defaultFocusMinutes,
                cloudKitContainerIdentifier: preference.cloudKitContainerIdentifier,
                showFuFuTheme: preference.showFuFuTheme,
                notificationLeadMinutes: preference.notificationLeadMinutes,
                weekStartPreference: preference.weekStartPreference,
                localRemindersEnabled: preference.localRemindersEnabled,
                eventColorHexes: preference.eventColorHexes,
                eventTagNames: preference.eventTagNames,
                defaultEventIsAllDay: preference.defaultEventIsAllDay,
                showCompletedSchedules: preference.showCompletedSchedules,
                completedSchedulesUseStrikethrough: preference.completedSchedulesUseStrikethrough,
                showChineseCalendar: preference.showChineseCalendar,
                scheduleTimeCollapseEnabled: preference.scheduleTimeCollapseEnabled,
                scheduleCollapsedStartHour: preference.scheduleCollapsedStartHour,
                scheduleCollapsedEndHour: preference.scheduleCollapsedEndHour,
                timeDisplayPreference: preference.timeDisplayPreference
            ))
        }

        for timetable in try fetch(CourseTimetable.self, in: legacyContext) {
            accountContext.insert(CourseTimetable(
                id: timetable.id,
                name: timetable.name,
                semesterStartDate: timetable.semesterStartDate,
                semesterWeeks: timetable.semesterWeeks,
                periodsPerDay: timetable.periodsPerDay,
                lessonDurationMinutes: timetable.lessonDurationMinutes,
                breakDurationMinutes: timetable.breakDurationMinutes,
                skipHolidays: timetable.skipHolidays,
                createdAt: timetable.createdAt,
                updatedAt: timetable.updatedAt
            ))
        }

        for period in try fetch(CoursePeriod.self, in: legacyContext) {
            accountContext.insert(CoursePeriod(
                id: period.id,
                timetableID: period.timetableID,
                index: period.index,
                startMinutesFromMidnight: period.startMinutesFromMidnight,
                endMinutesFromMidnight: period.endMinutesFromMidnight
            ))
        }

        for course in try fetch(Course.self, in: legacyContext) {
            accountContext.insert(Course(
                id: course.id,
                timetableID: course.timetableID,
                name: course.name,
                colorHex: course.colorHex,
                teacherName: course.teacherName,
                location: course.location,
                createdAt: course.createdAt,
                updatedAt: course.updatedAt
            ))
        }

        for session in try fetch(CourseSession.self, in: legacyContext) {
            accountContext.insert(CourseSession(
                id: session.id,
                courseID: session.courseID,
                weekday: session.weekday,
                startPeriodIndex: session.startPeriodIndex,
                endPeriodIndex: session.endPeriodIndex,
                startWeek: session.startWeek,
                endWeek: session.endWeek
            ))
        }
    }

    private func fetch<T: PersistentModel>(_ type: T.Type, in modelContext: ModelContext) throws -> [T] {
        try modelContext.fetch(FetchDescriptor<T>())
    }
}
