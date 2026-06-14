import Foundation
import SwiftData

#if canImport(Darwin)
import Darwin
#endif

public enum WeekStartPreference: Int, CaseIterable, Codable, Identifiable, Sendable {
    case sunday = 1
    case monday = 2

    public var id: Int { rawValue }

    public var calendarFirstWeekday: Int { rawValue }

    public var titleEnglish: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        }
    }

    public var titleChinese: String {
        switch self {
        case .sunday: "周日"
        case .monday: "周一"
        }
    }

    public func title(language: AppLanguage) -> String {
        switch language {
        case .english: titleEnglish
        case .chinese: titleChinese
        }
    }

    public var configuredCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = calendarFirstWeekday
        return calendar
    }

    public func orderedVeryShortWeekdaySymbols(calendar: Calendar) -> [String] {
        orderedSymbols(calendar.veryShortWeekdaySymbols)
    }

    public func orderedShortWeekdaySymbols(calendar: Calendar) -> [String] {
        orderedSymbols(calendar.shortWeekdaySymbols)
    }

    private func orderedSymbols(_ symbols: [String]) -> [String] {
        guard symbols.count == 7 else {
            return symbols
        }

        let startIndex = max(0, min(6, calendarFirstWeekday - 1))
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }
}

public enum WidgetPlannerPreferenceStore {
    public static let suiteName = "group.com.yuelingqiu.MeowPlanner"
    public static let weekStartPreferenceKey = "weekStartPreference"
    public static let showChineseCalendarKey = "showChineseCalendar"

    public static var weekStartPreference: WeekStartPreference {
        get {
            let rawValue = defaults.integer(forKey: weekStartPreferenceKey)
            return WeekStartPreference(rawValue: rawValue) ?? .sunday
        }
        set {
            defaults.set(newValue.rawValue, forKey: weekStartPreferenceKey)
        }
    }

    public static var showChineseCalendar: Bool {
        get {
            defaults.object(forKey: showChineseCalendarKey) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: showChineseCalendarKey)
        }
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetPlannerPreferenceStore.suiteName) ?? .standard
    }
}

public struct WidgetPlannerSnapshot: Codable, Equatable, Sendable {
    public struct Event: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let startDate: Date
        public let endDate: Date?
        public let isAllDay: Bool
        public let notes: String
        public let isCompleted: Bool
        public let completedAt: Date?
        public let reminderOffsetMinutes: Int?
        public let repeatRule: RepeatRule
        public let tagName: String
        public let colorHex: String
        public let createdAt: Date
        public let updatedAt: Date

        public init(event: PlannerEvent) {
            id = event.id
            title = event.title
            startDate = event.startDate
            endDate = event.endDate
            isAllDay = event.isAllDay
            notes = event.notes
            isCompleted = event.isCompleted
            completedAt = event.completedAt
            reminderOffsetMinutes = event.reminderOffsetMinutes
            repeatRule = event.repeatRule
            tagName = event.tagName
            colorHex = event.colorHex
            createdAt = event.createdAt
            updatedAt = event.updatedAt
        }

        public var plannerEvent: PlannerEvent {
            PlannerEvent(
                id: id,
                title: title,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                notes: notes,
                isCompleted: isCompleted,
                completedAt: completedAt,
                reminderOffsetMinutes: reminderOffsetMinutes,
                repeatRule: repeatRule,
                tagName: tagName,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }

    public struct Todo: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let notes: String
        public let dueDate: Date?
        public let groupID: UUID?
        public let sortOrder: Int?
        public let isCompleted: Bool
        public let completedAt: Date?
        public let reminderDate: Date?
        public let createdAt: Date
        public let updatedAt: Date

        public init(todo: TodoItem) {
            id = todo.id
            title = todo.title
            notes = todo.notes
            dueDate = todo.dueDate
            groupID = todo.groupID
            sortOrder = todo.sortOrder
            isCompleted = todo.isCompleted
            completedAt = todo.completedAt
            reminderDate = todo.reminderDate
            createdAt = todo.createdAt
            updatedAt = todo.updatedAt
        }

        public var todoItem: TodoItem {
            TodoItem(
                id: id,
                title: title,
                notes: notes,
                dueDate: dueDate,
                groupID: groupID,
                sortOrder: sortOrder,
                isCompleted: isCompleted,
                completedAt: completedAt,
                reminderDate: reminderDate,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }

    public let events: [Event]
    public let todos: [Todo]
    public let habitCount: Int
    public let weekStartPreference: WeekStartPreference
    public let showChineseCalendar: Bool
    public let showCompletedSchedules: Bool
    public let completedSchedulesUseStrikethrough: Bool
    public let updatedAt: Date

    public init(
        events: [PlannerEvent],
        todos: [TodoItem],
        habitCount: Int,
        weekStartPreference: WeekStartPreference,
        showChineseCalendar: Bool,
        showCompletedSchedules: Bool = true,
        completedSchedulesUseStrikethrough: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.events = events.map(Event.init)
        self.todos = todos.map(Todo.init)
        self.habitCount = habitCount
        self.weekStartPreference = weekStartPreference
        self.showChineseCalendar = showChineseCalendar
        self.showCompletedSchedules = showCompletedSchedules
        self.completedSchedulesUseStrikethrough = completedSchedulesUseStrikethrough
        self.updatedAt = updatedAt
    }

    public var plannerEvents: [PlannerEvent] {
        events.map(\.plannerEvent)
    }

    public var todoItems: [TodoItem] {
        todos.map(\.todoItem)
    }

    private enum CodingKeys: String, CodingKey {
        case events
        case todos
        case habitCount
        case weekStartPreference
        case showChineseCalendar
        case showCompletedSchedules
        case completedSchedulesUseStrikethrough
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        events = try container.decode([Event].self, forKey: .events)
        todos = try container.decode([Todo].self, forKey: .todos)
        habitCount = try container.decode(Int.self, forKey: .habitCount)
        weekStartPreference = try container.decode(WeekStartPreference.self, forKey: .weekStartPreference)
        showChineseCalendar = try container.decodeIfPresent(Bool.self, forKey: .showChineseCalendar) ?? true
        showCompletedSchedules = try container.decodeIfPresent(Bool.self, forKey: .showCompletedSchedules) ?? true
        completedSchedulesUseStrikethrough = try container.decodeIfPresent(
            Bool.self,
            forKey: .completedSchedulesUseStrikethrough
        ) ?? true
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(events, forKey: .events)
        try container.encode(todos, forKey: .todos)
        try container.encode(habitCount, forKey: .habitCount)
        try container.encode(weekStartPreference, forKey: .weekStartPreference)
        try container.encode(showChineseCalendar, forKey: .showChineseCalendar)
        try container.encode(showCompletedSchedules, forKey: .showCompletedSchedules)
        try container.encode(completedSchedulesUseStrikethrough, forKey: .completedSchedulesUseStrikethrough)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

public enum WidgetPlannerSnapshotStore {
    public static let snapshotKey = "widgetPlannerSnapshot"
    public static let snapshotFilename = "widget-planner-snapshot.json"
    private static let widgetExtensionContainerIdentifier = "com.yuelingqiu.MeowPlanner.MeowPlannerWidget"

    public static func load() -> WidgetPlannerSnapshot? {
        load(defaults: defaults, fileURLs: snapshotFileURLs)
    }

    public static func loadFromFiles() -> WidgetPlannerSnapshot? {
        load(defaults: defaults, fileURLs: snapshotFileURLs)
    }

    public static func load(defaults: UserDefaults) -> WidgetPlannerSnapshot? {
        load(defaults: defaults, fileURLs: [])
    }

    public static func load(defaults: UserDefaults, fileURL: URL?) -> WidgetPlannerSnapshot? {
        load(defaults: defaults, fileURLs: fileURL.map { [$0] } ?? [])
    }

    public static func load(defaults: UserDefaults, fileURLs: [URL]) -> WidgetPlannerSnapshot? {
        var snapshots = fileURLs.compactMap { load(fileURL: $0) }
        if let defaultsSnapshot = loadFromSharedDefaults(defaults: defaults) {
            snapshots.append(defaultsSnapshot)
        }

        return snapshots.max { $0.updatedAt < $1.updatedAt }
    }

    private static func loadFromSharedDefaults(defaults: UserDefaults = defaults) -> WidgetPlannerSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetPlannerSnapshot.self, from: data)
    }

    private static func load(fileURL: URL) -> WidgetPlannerSnapshot? {
        guard
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(WidgetPlannerSnapshot.self, from: data)
        else {
            return nil
        }

        return snapshot
    }

    public static func save(_ snapshot: WidgetPlannerSnapshot) {
        save(snapshot, defaults: defaults, fileURLs: snapshotFileURLs)
    }

    @discardableResult
    public static func refreshSharedSnapshotForWidgetExtension() -> WidgetPlannerSnapshot? {
        refreshSharedSnapshotForWidgetExtension(
            defaults: defaults,
            standardDefaults: .standard,
            fileURLs: snapshotFileURLs
        )
    }

    @discardableResult
    static func refreshSharedSnapshotForWidgetExtension(
        defaults: UserDefaults,
        standardDefaults: UserDefaults,
        fileURLs: [URL]
    ) -> WidgetPlannerSnapshot? {
        guard let snapshot = load(defaults: defaults, fileURLs: fileURLs) else {
            return nil
        }

        save(snapshot, defaults: defaults, fileURLs: fileURLs)
        save(snapshot, defaults: standardDefaults, fileURLs: [])
        return snapshot
    }

    public static func save(
        _ snapshot: WidgetPlannerSnapshot,
        defaults: UserDefaults
    ) {
        save(snapshot, defaults: defaults, fileURL: nil)
    }

    public static func save(
        _ snapshot: WidgetPlannerSnapshot,
        defaults: UserDefaults,
        fileURL: URL?
    ) {
        save(snapshot, defaults: defaults, fileURLs: fileURL.map { [$0] } ?? [])
    }

    public static func save(
        _ snapshot: WidgetPlannerSnapshot,
        defaults: UserDefaults,
        fileURLs: [URL]
    ) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        for fileURL in fileURLs {
            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? FileManager.default.removeItem(at: fileURL)
            try? data.write(to: fileURL, options: .atomic)
        }

        defaults.set(data, forKey: snapshotKey)
        defaults.synchronize()
    }

    public static func clear() {
        clear(defaults: defaults, fileURLs: snapshotFileURLs)
    }

    public static func clear(defaults: UserDefaults, fileURL: URL?) {
        clear(defaults: defaults, fileURLs: fileURL.map { [$0] } ?? [])
    }

    public static func clear(defaults: UserDefaults, fileURLs: [URL]) {
        for fileURL in fileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }

        defaults.removeObject(forKey: snapshotKey)
        defaults.synchronize()
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetPlannerPreferenceStore.suiteName) ?? .standard
    }

    private static var snapshotFileURLs: [URL] {
        snapshotFileURLs(
            appGroupContainerURL: FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: WidgetPlannerPreferenceStore.suiteName
            ),
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
            accountHomeDirectory: accountHomeDirectory
        )
    }

    static func snapshotFileURLs(
        appGroupContainerURL: URL?,
        homeDirectory: URL,
        accountHomeDirectory: URL?
    ) -> [URL] {
        var urls: [URL] = []

        let homeSnapshotURL = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
            .appendingPathComponent(snapshotFilename)
        let isWidgetSandboxHome = homeDirectory.path.contains(
            "/Library/Containers/\(widgetExtensionContainerIdentifier)/Data"
        )

        if isWidgetSandboxHome {
            urls.append(homeSnapshotURL)
        }

        if let containerURL = appGroupContainerURL {
            urls.append(containerURL.appendingPathComponent(snapshotFilename))
        }

        if let accountHomeDirectory {
            let accountGroupSnapshotURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
                .appendingPathComponent(snapshotFilename)
            let widgetSandboxMirrorSnapshotURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Containers")
                .appendingPathComponent(widgetExtensionContainerIdentifier)
                .appendingPathComponent("Data")
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
                .appendingPathComponent(snapshotFilename)

            urls.append(accountGroupSnapshotURL)
            urls.append(widgetSandboxMirrorSnapshotURL)
        }

        if !isWidgetSandboxHome {
            urls.append(homeSnapshotURL)
        }

        if accountHomeDirectory == nil, let userHome = NSHomeDirectoryForUser(NSUserName()) {
            urls.append(
                URL(fileURLWithPath: userHome)
                    .appendingPathComponent("Library")
                    .appendingPathComponent("Group Containers")
                    .appendingPathComponent(WidgetPlannerPreferenceStore.suiteName)
                    .appendingPathComponent(snapshotFilename)
            )
        }

        return urls.reduce(into: []) { uniqueURLs, url in
            guard !uniqueURLs.contains(url) else {
                return
            }
            uniqueURLs.append(url)
        }
    }

    private static var snapshotFileURL: URL? {
        snapshotFileURLs.first
    }

    private static var accountHomeDirectory: URL? {
        #if canImport(Darwin)
        guard
            let passwd = getpwuid(getuid()),
            let homePath = passwd.pointee.pw_dir
        else {
            return nil
        }
        return URL(fileURLWithPath: String(cString: homePath))
        #else
        return nil
        #endif
    }
}

public enum WidgetPlannerSnapshotBuilder {
    public static func makeSnapshot(using modelContext: ModelContext) throws -> WidgetPlannerSnapshot {
        if modelContext.hasChanges {
            try modelContext.save()
        }

        let events = try modelContext.fetch(
            FetchDescriptor<PlannerEvent>(sortBy: [SortDescriptor(\.startDate)])
        )
        let todos = try modelContext.fetch(
            FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.createdAt)])
        )
        let habits = try modelContext.fetch(
            FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        )
        let preference = try modelContext.fetch(
            FetchDescriptor<PlannerPreference>()
        ).first ?? PlannerPreference.defaults

        return WidgetPlannerSnapshot(
            events: events,
            todos: todos,
            habitCount: habits.filter { $0.archivedAt == nil }.count,
            weekStartPreference: preference.weekStartPreference,
            showChineseCalendar: preference.showChineseCalendar,
            showCompletedSchedules: preference.showCompletedSchedules,
            completedSchedulesUseStrikethrough: preference.completedSchedulesUseStrikethrough
        )
    }
}
