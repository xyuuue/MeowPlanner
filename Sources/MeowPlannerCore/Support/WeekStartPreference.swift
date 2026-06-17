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

public enum WidgetBackgroundStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case defaultArtwork
    case customPhoto
    case transparent

    public var id: String { rawValue }

    public func title(language: AppLanguage) -> String {
        switch self {
        case .defaultArtwork:
            switch language {
            case .english: "Default"
            case .chinese: "默认背景"
            }
        case .customPhoto:
            switch language {
            case .english: "Photo"
            case .chinese: "相册图片"
            }
        case .transparent:
            switch language {
            case .english: "Transparent"
            case .chinese: "透明"
            }
        }
    }
}

public enum WidgetPlannerPreferenceStore {
    public static let suiteName = "group.com.yuelingqiu.MeowPlanner"
    public static let weekStartPreferenceKey = "weekStartPreference"
    public static let showChineseCalendarKey = "showChineseCalendar"
    public static let widgetAppearancePreferenceKey = "widgetAppearancePreference"
    public static let widgetBackgroundStyleKey = "widgetBackgroundStyle"
    public static let widgetBackgroundStyleFilename = "widget-background-style.txt"
    public static let customBackgroundImageFilename = "widget-custom-background.image"
    private static let widgetExtensionContainerIdentifier = "com.yuelingqiu.MeowPlanner.MeowPlannerWidget"

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

    public static var widgetBackgroundStyle: WidgetBackgroundStyle {
        get {
            widgetBackgroundStyle(defaults: defaults, styleFileURLs: widgetBackgroundStyleFileURLs)
        }
        set {
            setWidgetBackgroundStyle(newValue, defaults: defaults, styleFileURLs: widgetBackgroundStyleFileURLs)
        }
    }

    public static var widgetAppearancePreference: AppAppearancePreference {
        get {
            widgetAppearancePreference(defaults: defaults)
        }
        set {
            setWidgetAppearancePreference(newValue, defaults: defaults)
        }
    }

    public static var customBackgroundImageURL: URL? {
        customBackgroundImageURL()
    }

    public static func widgetAppearancePreference(defaults: UserDefaults) -> AppAppearancePreference {
        guard let rawValue = defaults.string(forKey: widgetAppearancePreferenceKey) else {
            return .system
        }

        return AppAppearancePreference(storedValue: rawValue)
    }

    public static func setWidgetAppearancePreference(_ preference: AppAppearancePreference, defaults: UserDefaults) {
        defaults.set(preference.rawValue, forKey: widgetAppearancePreferenceKey)
        defaults.synchronize()
    }

    public static func isDarkWidgetAppearance(systemIsDark: Bool) -> Bool {
        isDarkWidgetAppearance(systemIsDark: systemIsDark, defaults: defaults)
    }

    public static func isDarkWidgetAppearance(systemIsDark: Bool, defaults: UserDefaults) -> Bool {
        switch widgetAppearancePreference(defaults: defaults) {
        case .system:
            systemIsDark
        case .light:
            false
        case .dark:
            true
        }
    }

    public static func widgetBackgroundStyle(defaults: UserDefaults) -> WidgetBackgroundStyle {
        widgetBackgroundStyle(defaults: defaults, styleFileURLs: [])
    }

    public static func widgetBackgroundStyle(defaults: UserDefaults, styleFileURLs: [URL]) -> WidgetBackgroundStyle {
        guard let rawValue = defaults.string(forKey: widgetBackgroundStyleKey) else {
            return widgetBackgroundStyle(styleFileURLs: styleFileURLs) ?? .defaultArtwork
        }

        if let style = WidgetBackgroundStyle(rawValue: rawValue) {
            saveWidgetBackgroundStyle(style, styleFileURLs: styleFileURLs)
            return style
        }

        return widgetBackgroundStyle(styleFileURLs: styleFileURLs) ?? .defaultArtwork
    }

    public static func setWidgetBackgroundStyle(_ style: WidgetBackgroundStyle, defaults: UserDefaults) {
        setWidgetBackgroundStyle(style, defaults: defaults, styleFileURLs: [])
    }

    public static func setWidgetBackgroundStyle(_ style: WidgetBackgroundStyle, defaults: UserDefaults, styleFileURLs: [URL]) {
        defaults.set(style.rawValue, forKey: widgetBackgroundStyleKey)
        defaults.synchronize()
        saveWidgetBackgroundStyle(style, styleFileURLs: styleFileURLs)
    }

    private static func widgetBackgroundStyle(styleFileURLs: [URL]) -> WidgetBackgroundStyle? {
        for fileURL in styleFileURLs {
            guard let rawValue = try? String(contentsOf: fileURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
                let style = WidgetBackgroundStyle(rawValue: rawValue)
            else {
                continue
            }

            return style
        }

        return nil
    }

    private static func saveWidgetBackgroundStyle(_ style: WidgetBackgroundStyle, styleFileURLs: [URL]) {
        for fileURL in styleFileURLs {
            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? style.rawValue.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    private static var widgetBackgroundStyleFileURLs: [URL] {
        widgetBackgroundStyleFileURLs(
            appGroupContainerURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName),
            homeDirectory: currentHomeDirectory,
            accountHomeDirectory: accountHomeDirectory
        )
    }

    static func widgetBackgroundStyleFileURLs(
        appGroupContainerURL: URL?,
        homeDirectory: URL,
        accountHomeDirectory: URL?
    ) -> [URL] {
        var urls: [URL] = []
        let homeStyleURL = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Group Containers")
            .appendingPathComponent(suiteName)
            .appendingPathComponent(widgetBackgroundStyleFilename)
        let isWidgetSandboxHome = homeDirectory.path.contains(
            "/Library/Containers/\(widgetExtensionContainerIdentifier)/Data"
        )

        if isWidgetSandboxHome {
            urls.append(homeStyleURL)
        }

        if let appGroupContainerURL {
            urls.append(appGroupContainerURL.appendingPathComponent(widgetBackgroundStyleFilename))
        }

        if let accountHomeDirectory {
            let accountGroupStyleURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(suiteName)
                .appendingPathComponent(widgetBackgroundStyleFilename)
            let widgetSandboxMirrorStyleURL = accountHomeDirectory
                .appendingPathComponent("Library")
                .appendingPathComponent("Containers")
                .appendingPathComponent(widgetExtensionContainerIdentifier)
                .appendingPathComponent("Data")
                .appendingPathComponent("Library")
                .appendingPathComponent("Group Containers")
                .appendingPathComponent(suiteName)
                .appendingPathComponent(widgetBackgroundStyleFilename)

            urls.append(accountGroupStyleURL)
            urls.append(widgetSandboxMirrorStyleURL)
        }

        if !isWidgetSandboxHome {
            urls.append(homeStyleURL)
        }

        if accountHomeDirectory == nil, let userHome = NSHomeDirectoryForUser(NSUserName()) {
            urls.append(
                URL(fileURLWithPath: userHome)
                    .appendingPathComponent("Library")
                    .appendingPathComponent("Group Containers")
                    .appendingPathComponent(suiteName)
                    .appendingPathComponent(widgetBackgroundStyleFilename)
            )
        }

        return urls.reduce(into: []) { uniqueURLs, url in
            guard !uniqueURLs.contains(url) else {
                return
            }
            uniqueURLs.append(url)
        }
    }

    private static var currentHomeDirectory: URL {
        #if os(macOS)
        return FileManager.default.homeDirectoryForCurrentUser
        #else
        if let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            return applicationSupportDirectory
                .deletingLastPathComponent()
                .deletingLastPathComponent()
        }

        return URL(fileURLWithPath: NSHomeDirectory())
        #endif
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

    public static func customBackgroundImageURL(fileManager: FileManager = .default) -> URL? {
        #if canImport(Darwin)
        return fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent(customBackgroundImageFilename)
        #else
        return nil
        #endif
    }

    public static func saveCustomBackgroundImageData(_ data: Data) throws {
        guard let fileURL = customBackgroundImageURL else {
            return
        }

        try saveCustomBackgroundImageData(data, fileURL: fileURL)
    }

    public static func saveCustomBackgroundImageData(_ data: Data, fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    public static func clearCustomBackgroundImage() {
        guard let fileURL = customBackgroundImageURL else {
            return
        }

        clearCustomBackgroundImage(fileURL: fileURL)
    }

    public static func clearCustomBackgroundImage(fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL)
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

public struct WidgetWeeklyScheduleDay: Identifiable, Equatable, Sendable {
    public let date: Date
    public let events: [WidgetPlannerSnapshot.Event]

    public var id: Date { date }

    public init(date: Date, events: [WidgetPlannerSnapshot.Event]) {
        self.date = date
        self.events = events
    }
}

public enum WidgetWeeklySchedulePlanner {
    public static func days(
        anchorDate: Date,
        displayRule: WidgetScheduleDisplayRule,
        events: [WidgetPlannerSnapshot.Event],
        weekStartPreference: WeekStartPreference,
        showCompletedSchedules: Bool,
        weekOffset: Int = 0,
        calendar: Calendar = .current
    ) -> [WidgetWeeklyScheduleDay] {
        var workingCalendar = calendar
        workingCalendar.firstWeekday = weekStartPreference.calendarFirstWeekday
        let offsetAnchorDate = workingCalendar.date(
            byAdding: .day,
            value: weekOffset * 7,
            to: anchorDate
        ) ?? anchorDate

        let startDate: Date
        switch displayRule {
        case .nextSevenDays:
            startDate = workingCalendar.startOfDay(for: offsetAnchorDate)
        case .calendarWeek:
            startDate = workingCalendar.dateInterval(of: .weekOfYear, for: offsetAnchorDate)?.start
                ?? workingCalendar.startOfDay(for: offsetAnchorDate)
        }

        let visibleEvents = events
            .filter { showCompletedSchedules || !$0.isCompleted }
            .sorted(by: eventSort)

        return (0..<7).compactMap { offset in
            guard let date = workingCalendar.date(byAdding: .day, value: offset, to: startDate) else {
                return nil
            }

            let dayEvents = visibleEvents.filter { event in
                event.plannerEvent.occurs(on: date, calendar: workingCalendar)
            }

            return WidgetWeeklyScheduleDay(date: date, events: dayEvents)
        }
    }

    private static func eventSort(
        _ lhs: WidgetPlannerSnapshot.Event,
        _ rhs: WidgetPlannerSnapshot.Event
    ) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }

        if lhs.isAllDay != rhs.isAllDay {
            return lhs.isAllDay
        }

        if lhs.startDate != rhs.startDate {
            return lhs.startDate < rhs.startDate
        }

        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
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
            homeDirectory: currentHomeDirectory,
            accountHomeDirectory: accountHomeDirectory
        )
    }

    private static var currentHomeDirectory: URL {
        #if os(macOS)
        return FileManager.default.homeDirectoryForCurrentUser
        #else
        if let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            return applicationSupportDirectory
                .deletingLastPathComponent()
                .deletingLastPathComponent()
        }

        return URL(fileURLWithPath: NSHomeDirectory())
        #endif
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
