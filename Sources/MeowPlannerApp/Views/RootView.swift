import MeowPlannerCore
import SwiftData
import SwiftUI
#if os(macOS)
import AppKit
#endif

#if os(macOS)
enum MainWindowLaunchCoordinator {
    @MainActor
    static private var isHandlingWidgetLaunch = false
    @MainActor
    static private var lastWidgetLaunchHandledAt = Date.distantPast
    @MainActor
    static private var didRequestInitialMainWindow = false

    @MainActor
    static func openInitialMainWindowIfNeeded(openWindow: @escaping () -> Void) {
        guard !didRequestInitialMainWindow else {
            return
        }

        didRequestInitialMainWindow = true
        openOrFocusMainWindowFromAppLifecycle(openWindow: openWindow)
    }

    @MainActor
    static func openOrFocusMainWindowFromAppLifecycle(openWindow: @escaping () -> Void) {
        openOrFocusMainWindow(openWindow: openWindow, settlingAttempts: 4)
    }

    @MainActor
    static func focusSystemCreatedMainWindowFromExternalURL(
        openWindow: @escaping () -> Void,
        settlingAttempts: Int = 40
    ) {
        let now = Date()
        guard !isHandlingWidgetLaunch else {
            return
        }

        guard now.timeIntervalSince(lastWidgetLaunchHandledAt) > 0.35 else {
            return
        }

        isHandlingWidgetLaunch = true
        lastWidgetLaunchHandledAt = now

        Task { @MainActor in
            defer {
                isHandlingWidgetLaunch = false
            }

            NSApplication.shared.activate(ignoringOtherApps: true)

            if let target = focusAndSanitizeMainWindow() {
                target.makeKey()
                return
            }

            for _ in 0..<settlingAttempts {
                try? await Task.sleep(nanoseconds: 120_000_000)
                if let target = focusAndSanitizeMainWindow() {
                    target.makeKey()
                    return
                }
            }

            openWindow()

            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 120_000_000)
                if let target = focusAndSanitizeMainWindow() {
                    target.makeKey()
                    return
                }
            }
        }
    }

    @MainActor
    static func openOrFocusMainWindow(openWindow: @escaping () -> Void, settlingAttempts: Int = 24) {
        let now = Date()
        guard !isHandlingWidgetLaunch else {
            return
        }

        guard now.timeIntervalSince(lastWidgetLaunchHandledAt) > 0.35 else {
            return
        }

        isHandlingWidgetLaunch = true
        lastWidgetLaunchHandledAt = now

        Task { @MainActor in
            defer {
                isHandlingWidgetLaunch = false
            }

            NSApplication.shared.activate(ignoringOtherApps: true)

            // If the app already has a main window, focus it and close duplicates.
            if let target = focusAndSanitizeMainWindow() {
                target.makeKey()
                return
            }

            // Allow system launch/open timing to settle (e.g. auto-open on URL tap).
            for _ in 0..<settlingAttempts {
                try? await Task.sleep(nanoseconds: 120_000_000)
                if let target = focusAndSanitizeMainWindow() {
                    target.makeKey()
                    return
                }
            }

            if findMainWindow() == nil {
                openWindow()
            }

            for _ in 0..<40 {
                if let target = focusAndSanitizeMainWindow() {
                    target.makeKey()
                    return
                }
                try? await Task.sleep(nanoseconds: 120_000_000)
            }

            // In case duplicate windows are created by the system during cold launch,
            // keep one candidate and close extras.
            if let target = focusCandidateWindow() {
                closeDuplicateCandidateWindows(keeping: target)
                if !target.isVisible {
                    target.makeKeyAndOrderFront(nil)
                } else {
                    target.makeKey()
                }
                target.orderFrontRegardless()
            }
        }
    }

    @MainActor
    private static func focusAndSanitizeMainWindow() -> NSWindow? {
        guard let targetWindow = focusCandidateWindow() else {
            return nil
        }

        if targetWindow.isMiniaturized {
            targetWindow.deminiaturize(nil)
        }

        closeDuplicateCandidateWindows(keeping: targetWindow)

        if !targetWindow.isVisible {
            targetWindow.makeKeyAndOrderFront(nil)
        } else {
            targetWindow.makeKey()
        }
        targetWindow.orderFrontRegardless()
        return targetWindow
    }

    @MainActor
    private static func focusCandidateWindow() -> NSWindow? {
        var candidates = mainWindowCandidates()
        guard !candidates.isEmpty else {
            return nil
        }

        candidates.sort(by: { lhs, rhs in
            if lhs.isMiniaturized != rhs.isMiniaturized {
                return !lhs.isMiniaturized && rhs.isMiniaturized
            }
            if lhs.isVisible != rhs.isVisible {
                return lhs.isVisible
            }
            return lhs.windowNumber < rhs.windowNumber
        })

        return candidates.first
    }

    @MainActor
    private static func closeDuplicateCandidateWindows(keeping target: NSWindow) {
        for candidate in primaryMainWindowCandidates() where candidate !== target {
            candidate.close()
        }
    }

    @MainActor
    private static func findMainWindow() -> NSWindow? {
        focusCandidateWindow()
    }

    @MainActor
    private static func mainWindowCandidates() -> [NSWindow] {
        let candidateWindows = NSApplication.shared.windows
        let primaryCandidates = primaryMainWindowCandidates()

        if !primaryCandidates.isEmpty {
            return primaryCandidates
        }

        return candidateWindows.filter { window in
            window.level == .normal || window.level == .floating
        }
    }

    @MainActor
    private static func primaryMainWindowCandidates() -> [NSWindow] {
        NSApplication.shared.windows.filter { window in
            window.identifier?.rawValue == "main" || window.title == "MeowPlanner"
        }
    }
}
#endif

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appLanguage) private var appLanguage
    @AppStorage(AppLanguage.storageKey) private var cloudAppLanguageID = AppLanguage.english.rawValue
    @AppStorage(AppLanguage.updatedAtStorageKey) private var cloudAppLanguageUpdatedAt = 0.0
    @AppStorage(AppAppearancePreference.storageKey) private var cloudAppearanceID = AppAppearancePreference.system.rawValue
    @AppStorage(AppAppearancePreference.updatedAtStorageKey) private var cloudAppearanceUpdatedAt = 0.0
    @AppStorage(AppDockIconController.storageKey) private var cloudShowDockIcon = AppDockIconController.defaultShowDockIcon
    @AppStorage("meowplanner.sidebar.sectionOrder") private var sidebarSectionOrderRaw = AppSection.defaultSidebarOrderStorageValue
    #if os(iOS)
    @AppStorage(AppSection.iosBottomNavigationStorageKey) private var iosBottomNavigationRaw = AppSection.defaultIOSBottomNavigationStorageValue
    #endif
    @Query(sort: \PlannerEvent.startDate) private var widgetEvents: [PlannerEvent]
    @Query(sort: \TodoGroup.createdAt) private var cloudTodoGroups: [TodoGroup]
    @Query(sort: \TodoItem.createdAt) private var widgetTodos: [TodoItem]
    @Query(sort: \Habit.createdAt) private var widgetHabits: [Habit]
    @Query(sort: \HabitCheckIn.date) private var cloudHabitCheckIns: [HabitCheckIn]
    @Query(sort: \FocusTag.sortOrder) private var cloudFocusTags: [FocusTag]
    @Query(sort: \FocusSession.startedAt) private var cloudFocusSessions: [FocusSession]
    @Query(sort: \PlannerPreference.id) private var widgetPreferences: [PlannerPreference]
    @Query(sort: \CourseTimetable.createdAt) private var cloudCourseTimetables: [CourseTimetable]
    @Query(sort: \CoursePeriod.index) private var cloudCoursePeriods: [CoursePeriod]
    @Query(sort: \Course.createdAt) private var cloudCourses: [Course]
    @Query(sort: \CourseSession.weekday) private var cloudCourseSessions: [CourseSession]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var accountStore = AccountSessionStore.shared
    @State private var selection: AppSection = .calendar
    @State private var settingsNavigationPath: [SettingsDestination] = []
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all
    @State private var calendarRenderToken = UUID()
    @State private var calendarAddScheduleRequestToken: UUID?
    @State private var pendingWidgetRefreshTask: Task<Void, Never>?
    @State private var isEditingSidebarOrder = false
    @State private var sidebarDropTargetSection: AppSection?
    #if os(iOS)
    @StateObject private var iosCalendarNavigationState = IOSCalendarNavigationState()
    @StateObject private var iosTimetableNavigationState = IOSTimetableNavigationState()
    #endif
    #if os(macOS)
    private let macOSSidebarExpandButtonTopPadding: CGFloat = 72
    private let macOSSidebarExpandButtonTrailingPadding: CGFloat = 34
    #endif

    var body: some View {
        #if os(macOS)
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            List {
                sidebarHeader

                ForEach(orderedSections) { section in
                    sidebarSectionRow(for: section)
                }

                if isEditingSidebarOrder {
                    sidebarBottomDropTarget
                }
            }
            .tint(MeowPlannerTheme.softBrownHighlight)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(MeowPlannerTheme.plannerGradient)
            .navigationSplitViewColumnWidth(min: 96, ideal: 210, max: 260)
        } detail: {
            ZStack {
                MeowPlannerTheme.plannerGradient
                    .ignoresSafeArea()

                sectionView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(alignment: .topTrailing) { nonCalendarSidebarExpandButtonOverlay }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar(removing: .sidebarToggle)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .background(SidebarToolbarOverflowCleaner(trigger: sidebarVisibility).frame(width: 0, height: 0))
        .background(MainWindowResizeAffordanceInstaller().frame(width: 0, height: 0))
        .onAppear {
            scheduleWidgetSnapshotRefresh(reload: true, delayNanoseconds: 0)
            scheduleCloudAppDataSync()
        }
        .onChange(of: widgetSnapshotSignature) { _, _ in
            scheduleWidgetSnapshotRefresh(reload: true, delayNanoseconds: 180_000_000)
        }
        .onChange(of: appDataCloudSyncSignature) { _, _ in
            scheduleCloudAppDataSync()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                scheduleWidgetSnapshotRefresh(reload: true, delayNanoseconds: 260_000_000)
                scheduleCloudAppDataSync()
            }
        }
        .onChange(of: accountStore.currentProfile?.remoteUserID) { _, _ in
            scheduleCloudAppDataSync()
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: .meowPlannerOpenSection)) { notification in
            guard let rawSection = notification.object as? String,
                  let section = AppSection(rawValue: rawSection)
            else {
                return
            }

            selectSidebarSection(section)
        }
        .onReceive(NotificationCenter.default.publisher(for: .meowPlannerExternalOpenURL)) { _ in
            refreshCalendarAfterExternalOpen()
        }
        #endif
        #else
        IOSNavigationShellView(
            selection: $selection,
            allSections: orderedSections,
            bottomSections: iosBottomNavigationSections,
            language: appLanguage,
            calendarNavigationState: iosCalendarNavigationState,
            timetableNavigationState: iosTimetableNavigationState,
            settingsCanNavigateBack: !settingsNavigationPath.isEmpty,
            onSelect: selectSidebarSection,
            onSettingsBack: navigateBackFromSettingsDestination
        ) {
            sectionView
        }
        .background(MeowPlannerTheme.plannerGradient)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            scheduleWidgetSnapshotRefresh(reload: true, delayNanoseconds: 0)
            scheduleCloudAppDataSync()
        }
        .onChange(of: widgetSnapshotSignature) { _, _ in
            scheduleWidgetSnapshotRefresh(reload: true, delayNanoseconds: 180_000_000)
        }
        .onChange(of: appDataCloudSyncSignature) { _, _ in
            scheduleCloudAppDataSync()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                scheduleWidgetSnapshotRefresh(reload: true, delayNanoseconds: 260_000_000)
                scheduleCloudAppDataSync()
            }
        }
        .onChange(of: accountStore.currentProfile?.remoteUserID) { _, _ in
            scheduleCloudAppDataSync()
        }
        .onReceive(NotificationCenter.default.publisher(for: .meowPlannerExternalOpenURL)) { notification in
            handleExternalURL(notification.object as? URL)
        }
        #endif
    }

    private func scheduleCloudAppDataSync() {
        FirestoreAppDataSyncService.shared.scheduleSync(for: accountStore.currentProfile?.remoteUserID, using: modelContext)
    }

    #if os(macOS)
    private func refreshCalendarFromCloud() {
        FirestoreAppDataSyncService.shared.syncImmediately(for: accountStore.currentProfile?.remoteUserID, using: modelContext)
    }
    #endif

    private var orderedSections: [AppSection] {
        AppSection.orderedSections(from: sidebarSectionOrderRaw)
    }

    #if os(iOS)
    private var iosBottomNavigationSections: [AppSection] {
        AppSection.iosBottomNavigationSections(from: iosBottomNavigationRaw)
    }
    #endif

    #if os(macOS)
    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            Text("MeowPlanner")
                .font(.headline.weight(.bold))
                .foregroundStyle(MeowPlannerTheme.cocoa)
                .lineLimit(1)

            Spacer(minLength: 0)

            sidebarCollapseButton
            sidebarOrderEditButton
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 8, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var sidebarOrderEditButton: some View {
        Button {
            toggleSidebarOrderEditing()
        } label: {
            Image(systemName: isEditingSidebarOrder ? "checkmark.circle.fill" : "arrow.up.arrow.down.circle")
                .font(.system(size: 15, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(width: 28, height: 28)
                .background(MeowPlannerTheme.cream.opacity(0.68), in: Circle())
        }
        .buttonStyle(.borderless)
        .help(sidebarOrderEditTitle)
        .accessibilityLabel(sidebarOrderEditTitle)
    }

    private var sidebarOrderEditTitle: String {
        if isEditingSidebarOrder {
            return appLanguage == .chinese ? "完成" : "Done"
        }

        return appLanguage == .chinese ? "自定义顺序" : "Customize order"
    }

    private var sidebarCollapseButton: some View {
        Button {
            collapseSidebar()
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 15, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(width: 28, height: 28)
                .background(MeowPlannerTheme.cream.opacity(0.68), in: Circle())
        }
        .buttonStyle(.borderless)
        .help(sidebarCollapseTitle)
        .accessibilityLabel(sidebarCollapseTitle)
    }

    private var sidebarCollapseTitle: String {
        appLanguage == .chinese ? "收起侧边栏" : "Hide sidebar"
    }

    private var sidebarExpandTitle: String {
        appLanguage == .chinese ? "展开侧边栏" : "Show sidebar"
    }

    @ViewBuilder
    private var nonCalendarSidebarExpandButtonOverlay: some View {
        if sidebarVisibility == .detailOnly && selection != .calendar {
            MeowPlannerSidebarExpandButton(action: expandSidebar, title: sidebarExpandTitle)
                .padding(.top, macOSSidebarExpandButtonTopPadding)
                .padding(.trailing, macOSSidebarExpandButtonTrailingPadding)
        }
    }

    @ViewBuilder
    private func sidebarSectionRow(for section: AppSection) -> some View {
        if isEditingSidebarOrder {
            draggableSidebarSectionRow(for: section)
        } else {
            selectableSidebarSectionRow(for: section)
        }
    }

    private func selectableSidebarSectionRow(for section: AppSection) -> some View {
        Button {
            guard !isEditingSidebarOrder else {
                return
            }

            selectSidebarSection(section)
        } label: {
            SidebarSectionRow(
                section: section,
                language: appLanguage,
                isSelected: selection == section,
                isReordering: isEditingSidebarOrder
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityLabel(section.title(language: appLanguage))
        .listRowInsets(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func draggableSidebarSectionRow(for section: AppSection) -> some View {
        SidebarSectionRow(
            section: section,
            language: appLanguage,
            isSelected: selection == section,
            isReordering: isEditingSidebarOrder
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .scaleEffect(sidebarDropTargetSection == section ? 1.015 : 1)
        .animation(.easeInOut(duration: 0.12), value: sidebarDropTargetSection)
        .draggable(section.rawValue) {
            SidebarDragPreviewView(
                title: section.title(language: appLanguage),
                systemImage: section.systemImage
            )
        }
        .dropDestination(for: String.self) { itemIdentifiers, _ in
            guard let draggedRawValue = itemIdentifiers.first else {
                return false
            }

            return moveSidebarSection(draggedRawValue: draggedRawValue, before: section)
        } isTargeted: { isTargeted in
            sidebarDropTargetSection = isTargeted ? section : nil
        }
        .accessibilityLabel(section.title(language: appLanguage))
        .listRowInsets(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var sidebarBottomDropTarget: some View {
        Color.clear
            .frame(height: 18)
            .dropDestination(for: String.self) { itemIdentifiers, _ in
                guard let draggedRawValue = itemIdentifiers.first else {
                    return false
                }

                return moveSidebarSection(draggedRawValue: draggedRawValue, before: nil)
            } isTargeted: { isTargeted in
                if !isTargeted {
                    sidebarDropTargetSection = nil
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
    #endif

    private var widgetPreference: PlannerPreference {
        widgetPreferences.first ?? PlannerPreference.defaults
    }

    private var activeWidgetHabitCount: Int {
        widgetHabits.filter { $0.archivedAt == nil }.count
    }

    private var widgetSnapshotSignature: String {
        [
            widgetEvents.map(eventSignature).joined(separator: ";"),
            widgetTodos.map(todoSignature).joined(separator: ";"),
            String(activeWidgetHabitCount),
            String(widgetPreference.weekStartPreference.rawValue),
            String(widgetPreference.showChineseCalendar),
            String(widgetPreference.showCompletedSchedules),
            String(widgetPreference.completedSchedulesUseStrikethrough)
        ].joined(separator: "||")
    }

    private var appDataCloudSyncSignature: String {
        let eventPart = widgetEvents.map(eventSignature).joined(separator: ";")
        let todoGroupPart = cloudTodoGroups.map(todoGroupSignature).joined(separator: ";")
        let todoPart = widgetTodos.map(todoSignature).joined(separator: ";")
        let habitPart = widgetHabits.map(habitSignature).joined(separator: ";")
        let habitCheckInPart = cloudHabitCheckIns.map(habitCheckInSignature).joined(separator: ";")
        let focusTagPart = cloudFocusTags.map(focusTagSignature).joined(separator: ";")
        let focusSessionPart = cloudFocusSessions.map(focusSessionSignature).joined(separator: ";")
        let preferencePart = widgetPreferences.map(preferenceSignature).joined(separator: ";")
        let timetablePart = cloudCourseTimetables.map(courseTimetableSignature).joined(separator: ";")
        let periodPart = cloudCoursePeriods.map(coursePeriodSignature).joined(separator: ";")
        let coursePart = cloudCourses.map(courseSignature).joined(separator: ";")
        let courseSessionPart = cloudCourseSessions.map(courseSessionSignature).joined(separator: ";")
        let settingsPart = [
            cloudAppLanguageID,
            String(cloudAppLanguageUpdatedAt),
            cloudAppearanceID,
            String(cloudAppearanceUpdatedAt),
            String(cloudShowDockIcon),
            sidebarSectionOrderRaw
        ].joined(separator: ";")

        return [
            eventPart,
            todoGroupPart,
            todoPart,
            habitPart,
            habitCheckInPart,
            focusTagPart,
            focusSessionPart,
            preferencePart,
            timetablePart,
            periodPart,
            coursePart,
            courseSessionPart,
            settingsPart
        ].joined(separator: "||")
    }

    private func selectSidebarSection(_ section: AppSection) {
        settingsNavigationPath.removeAll()

        switch section {
        case .calendar:
            #if os(iOS)
            selection = section
            #else
            refreshCalendarAfterExternalOpen()
            #endif
        default:
            selection = section
        }
    }

    private func navigateBackFromSettingsDestination() {
        guard !settingsNavigationPath.isEmpty else {
            return
        }

        settingsNavigationPath.removeLast()
    }

    #if os(macOS)
    private func toggleSidebarOrderEditing() {
        withAnimation(.snappy(duration: 0.18)) {
            isEditingSidebarOrder.toggle()
        }

        if !isEditingSidebarOrder {
            sidebarDropTargetSection = nil
        }
    }

    private func collapseSidebar() {
        withAnimation(.snappy(duration: 0.18)) {
            sidebarVisibility = .detailOnly
            isEditingSidebarOrder = false
        }

        sidebarDropTargetSection = nil
    }

    private func expandSidebar() {
        withAnimation(.snappy(duration: 0.18)) {
            sidebarVisibility = .all
        }
    }

    @discardableResult
    private func moveSidebarSection(draggedRawValue: String, before targetSection: AppSection?) -> Bool {
        guard isEditingSidebarOrder,
              let draggedSection = AppSection(rawValue: draggedRawValue)
        else {
            sidebarDropTargetSection = nil
            return false
        }

        guard draggedSection != targetSection else {
            sidebarDropTargetSection = nil
            return false
        }

        var reordered = orderedSections
        guard let sourceIndex = reordered.firstIndex(of: draggedSection) else {
            sidebarDropTargetSection = nil
            return false
        }

        reordered.remove(at: sourceIndex)

        let destinationIndex: Int
        if let targetSection {
            guard let targetIndex = reordered.firstIndex(of: targetSection) else {
                sidebarDropTargetSection = nil
                return false
            }
            destinationIndex = targetIndex
        } else {
            destinationIndex = reordered.count
        }

        reordered.insert(draggedSection, at: destinationIndex)
        sidebarSectionOrderRaw = AppSection.sidebarStorageValue(for: reordered)
        sidebarDropTargetSection = nil
        return true
    }
    #endif

    private func publishWidgetSnapshot(reload: Bool = false) {
        WidgetTimelineSyncService.publishSnapshotAndReload(using: modelContext, shouldReload: reload)
    }

    private func scheduleWidgetSnapshotRefresh(reload: Bool = false, delayNanoseconds: UInt64? = nil) {
        pendingWidgetRefreshTask?.cancel()
        pendingWidgetRefreshTask = Task { @MainActor in
            if let delayNanoseconds, delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            publishWidgetSnapshot(reload: reload)
        }
    }

    private func refreshCalendarAfterExternalOpen() {
        selection = .calendar

        Task { @MainActor in
            await Task.yield()
            calendarRenderToken = UUID()
        }
    }

    private func handleExternalURL(_ url: URL?) {
        guard let url,
              url.scheme?.lowercased() == "meowplanner" else {
            refreshCalendarAfterExternalOpen()
            return
        }

        if url.host == WidgetConstants.newScheduleURL.host,
           url.path == WidgetConstants.newScheduleURL.path {
            openNewScheduleFromExternalURL()
            return
        }

        refreshCalendarAfterExternalOpen()
    }

    private func openNewScheduleFromExternalURL() {
        settingsNavigationPath.removeAll()
        selection = .calendar
        calendarAddScheduleRequestToken = UUID()
    }

    private func eventSignature(_ event: PlannerEvent) -> String {
        [
            event.id.uuidString,
            event.title,
            dateToken(event.startDate),
            event.endDate.map(dateToken) ?? "",
            String(event.isAllDay),
            String(event.isCompleted),
            event.completedAt.map(dateToken) ?? "",
            String(event.reminderOffsetMinutes ?? -1),
            String(describing: event.repeatRule),
            event.tagName,
            event.colorHex,
            dateToken(event.updatedAt)
        ].joined(separator: "|")
    }

    private func todoSignature(_ todo: TodoItem) -> String {
        [
            todo.id.uuidString,
            todo.title,
            todo.notes,
            todo.dueDate.map(dateToken) ?? "",
            todo.groupID?.uuidString ?? "",
            String(todo.sortOrder ?? -1),
            String(todo.isCompleted),
            todo.completedAt.map(dateToken) ?? "",
            todo.reminderDate.map(dateToken) ?? "",
            dateToken(todo.updatedAt)
        ].joined(separator: "|")
    }

    private func todoGroupSignature(_ group: TodoGroup) -> String {
        [
            group.id.uuidString,
            group.name,
            group.colorHex,
            dateToken(group.createdAt),
            dateToken(group.updatedAt)
        ].joined(separator: "|")
    }

    private func habitSignature(_ habit: Habit) -> String {
        [
            habit.id.uuidString,
            habit.title,
            habit.symbolName,
            habit.colorHex,
            habit.reminderDate.map(dateToken) ?? "",
            dateToken(habit.createdAt),
            habit.archivedAt.map(dateToken) ?? ""
        ].joined(separator: "|")
    }

    private func habitCheckInSignature(_ checkIn: HabitCheckIn) -> String {
        [
            checkIn.id.uuidString,
            checkIn.habitID.uuidString,
            dateToken(checkIn.date),
            checkIn.note,
            dateToken(checkIn.createdAt)
        ].joined(separator: "|")
    }

    private func focusTagSignature(_ tag: FocusTag) -> String {
        [
            tag.id.uuidString,
            tag.name,
            tag.colorHex,
            dateToken(tag.createdAt),
            String(tag.sortOrder)
        ].joined(separator: "|")
    }

    private func focusSessionSignature(_ session: FocusSession) -> String {
        [
            session.id.uuidString,
            session.title,
            dateToken(session.startedAt),
            session.endedAt.map(dateToken) ?? "",
            String(session.plannedDurationSeconds),
            String(session.completedDurationSeconds),
            session.linkedTodoID?.uuidString ?? "",
            session.linkedHabitID?.uuidString ?? "",
            session.tagID?.uuidString ?? "",
            session.modeRawValue
        ].joined(separator: "|")
    }

    private func preferenceSignature(_ preference: PlannerPreference) -> String {
        [
            preference.id,
            preference.localeIdentifier,
            String(preference.defaultFocusMinutes),
            preference.cloudKitContainerIdentifier,
            String(preference.showFuFuTheme),
            String(preference.notificationLeadMinutes),
            String(preference.weekStartDayRawValue),
            String(preference.localRemindersEnabled),
            preference.eventColorHexList,
            preference.eventTagNameList,
            String(preference.defaultEventIsAllDay),
            String(preference.showCompletedSchedules),
            String(preference.completedSchedulesUseStrikethrough),
            String(preference.showChineseCalendar),
            String(preference.scheduleTimeCollapseEnabled),
            String(preference.scheduleCollapsedStartHour),
            String(preference.scheduleCollapsedEndHour),
            preference.timeDisplayRawValue,
            dateToken(preference.updatedAt)
        ].joined(separator: "|")
    }

    private func courseTimetableSignature(_ timetable: CourseTimetable) -> String {
        [
            timetable.id.uuidString,
            timetable.name,
            dateToken(timetable.semesterStartDate),
            String(timetable.semesterWeeks),
            String(timetable.periodsPerDay),
            String(timetable.lessonDurationMinutes),
            String(timetable.breakDurationMinutes),
            String(timetable.skipHolidays),
            dateToken(timetable.createdAt),
            dateToken(timetable.updatedAt)
        ].joined(separator: "|")
    }

    private func coursePeriodSignature(_ period: CoursePeriod) -> String {
        [
            period.id.uuidString,
            period.timetableID.uuidString,
            String(period.index),
            String(period.startMinutesFromMidnight),
            String(period.endMinutesFromMidnight)
        ].joined(separator: "|")
    }

    private func courseSignature(_ course: Course) -> String {
        [
            course.id.uuidString,
            course.timetableID.uuidString,
            course.name,
            course.colorHex,
            course.teacherName,
            course.location,
            dateToken(course.createdAt),
            dateToken(course.updatedAt)
        ].joined(separator: "|")
    }

    private func courseSessionSignature(_ session: CourseSession) -> String {
        [
            session.id.uuidString,
            session.courseID.uuidString,
            String(session.weekday),
            String(session.startPeriodIndex),
            String(session.endPeriodIndex),
            String(session.startWeek),
            String(session.endWeek)
        ].joined(separator: "|")
    }

    private func dateToken(_ date: Date) -> String {
        String(date.timeIntervalSince1970)
    }

    private var isSignedOutWorkspace: Bool {
        accountStore.currentProfile == nil
    }

    @ViewBuilder
    private var sectionView: some View {
        sectionContent(for: selection)
    }

    @ViewBuilder
    private func sectionContent(for section: AppSection) -> some View {
        Group {
            switch section {
            case .calendar:
                #if os(iOS)
                CalendarHomeView(
                    iosNavigationState: iosCalendarNavigationState,
                    newScheduleRequestToken: calendarAddScheduleRequestToken
                )
                    .id(calendarRenderToken)
                #else
                CalendarHomeView(
                    sidebarExpandAction: sidebarVisibility == .detailOnly ? { expandSidebar() } : nil,
                    sidebarExpandTitle: sidebarExpandTitle,
                    newScheduleRequestToken: calendarAddScheduleRequestToken,
                    onCloudRefresh: refreshCalendarFromCloud
                )
                    .id(calendarRenderToken)
                #endif
            case .todo:
                TodoHomeView()
            case .schedule:
                #if os(iOS)
                ScheduleAgendaView(iosNavigationState: iosCalendarNavigationState)
                #else
                ScheduleAgendaView()
                #endif
            case .timetable:
                #if os(iOS)
                CourseTimetableView(iosNavigationState: iosTimetableNavigationState)
                #else
                CourseTimetableView()
                #endif
            case .focus:
                FocusView()
            case .settings:
                SettingsView(navigationPath: $settingsNavigationPath)
            }
        }
        .modifier(SignedOutWorkspaceReadOnlyModifier(
            isEnabled: isSignedOutWorkspace && section != .settings,
            disablesContent: isSignedOutWorkspace && section != .settings && section != .calendar,
            language: appLanguage
        ))
    }
}

struct MeowPlannerSidebarExpandButton: View {
    var action: () -> Void
    var title: String

    var body: some View {
        Button(action: action) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 16, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(width: 34, height: 34)
                .background(MeowPlannerTheme.cream.opacity(0.82), in: Circle())
        }
        .buttonStyle(.borderless)
        .help(title)
        .accessibilityLabel(title)
    }
}

private struct MeowPlannerSignedOutReadOnlyKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var meowPlannerSignedOutReadOnly: Bool {
        get { self[MeowPlannerSignedOutReadOnlyKey.self] }
        set { self[MeowPlannerSignedOutReadOnlyKey.self] = newValue }
    }
}

private struct SignedOutWorkspaceReadOnlyModifier: ViewModifier {
    var isEnabled: Bool
    var disablesContent: Bool = true
    var language: AppLanguage

    func body(content: Content) -> some View {
        content
            .environment(\.meowPlannerSignedOutReadOnly, isEnabled)
            .disabled(disablesContent)
            .overlay(alignment: .topTrailing) {
                if isEnabled {
                    signedOutBadge
                }
            }
    }

    private var signedOutBadge: some View {
        Label(title, systemImage: "lock")
            .font(.caption.weight(.semibold))
            .foregroundStyle(MeowPlannerTheme.cocoa)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(MeowPlannerTheme.cream.opacity(0.88), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(MeowPlannerTheme.caramel.opacity(0.28), lineWidth: 1)
            }
            .padding(16)
            .allowsHitTesting(false)
    }

    private var title: String {
        switch language {
        case .english: "Sign in to edit"
        case .chinese: "登录后编辑"
        }
    }
}

private enum ScheduleAgendaMode: String, CaseIterable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .daily:
            switch language {
            case .english: "Daily"
            case .chinese: "每日"
            }
        case .weekly:
            switch language {
            case .english: "Weekly"
            case .chinese: "每周"
            }
        }
    }
}

private struct ScheduleAgendaView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Query(sort: \PlannerEvent.startDate) private var events: [PlannerEvent]
    @Query private var preferences: [PlannerPreference]
    #if os(iOS)
    @ObservedObject private var iosNavigationState: IOSCalendarNavigationState
    #endif

    @State private var mode: ScheduleAgendaMode = .daily
    @State private var selectedDate = Date()
    @State private var isEarlyMorningExpanded = false
    @State private var showingScheduleDatePicker = false

    #if os(iOS)
    private let scheduleDatePickerYearRange = 1901...2099

    init(iosNavigationState: IOSCalendarNavigationState) {
        self.iosNavigationState = iosNavigationState
    }
    #else
    init() {}
    #endif

    private var calendar: Calendar {
        preference.weekStartPreference.configuredCalendar
    }

    var body: some View {
        ZStack {
            schedulePageBackground

            schedulePageContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .sheet(isPresented: $showingScheduleDatePicker) {
            IOSScheduleWheelDatePickerSheet(
                selection: scheduleDatePickerSelection,
                yearRange: scheduleDatePickerYearRange,
                language: appLanguage,
                calendar: calendar
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            syncIOSScheduleNavigationState()
        }
        .onChange(of: selectedDate) { _, _ in
            syncIOSScheduleNavigationState()
        }
        #endif
    }

    @ViewBuilder
    private var schedulePageBackground: some View {
        #if os(iOS)
        Color.clear
            .ignoresSafeArea()
        #else
        MeowPlannerTheme.fufuPlannerBackground
            .overlay {
                MeowPlannerTheme.plannerGradient.opacity(0.88)
            }
            .overlay {
                scheduleBackgroundMotifs
            }
            .ignoresSafeArea()
        #endif
    }

    @ViewBuilder
    private var schedulePageContent: some View {
        #if os(iOS)
        scheduleTimelineContent
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        #else
        scheduleTimelineContent
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        #endif
    }

    private var scheduleTimelineContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            scheduleHeader

            ScheduleTimeGridView(
                mode: mode,
                selectedDate: selectedDate,
                dayDates: mode == .daily ? [selectedDate] : weekDates,
                events: events,
                timeCollapseEnabled: scheduleTimeCollapseEnabled,
                collapsedStartHour: scheduleCollapsedStartHour,
                collapsedEndHour: scheduleCollapsedEndHour,
                timeDisplayPreference: timeDisplayPreference,
                showCompletedSchedules: showCompletedSchedules,
                completedSchedulesUseStrikethrough: completedSchedulesUseStrikethrough,
                isEarlyMorningExpanded: $isEarlyMorningExpanded,
                language: appLanguage,
                calendar: calendar,
                usesOuterVerticalScroll: scheduleUsesOuterVerticalScroll
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(MeowPlannerTheme.fufuPlannerBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(MeowPlannerTheme.caramel.opacity(0.16), lineWidth: 1)
            }
            .background {
                HorizontalSwipeScrollDetector { horizontal in
                    moveDate(by: horizontal < 0 ? 1 : -1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var scheduleUsesOuterVerticalScroll: Bool {
        false
    }

    private var scheduleHeader: some View {
        #if os(iOS)
        scheduleModePicker
            .frame(maxWidth: .infinity, alignment: .leading)
        #else
        HStack(alignment: .center, spacing: 16) {
            FuFuAssetImage(size: 58)
            scheduleDatePickerButton

            Spacer()

            scheduleModePicker
        }
        #endif
    }

    private var scheduleIOSDateTitleFont: Font {
        #if os(iOS)
        .system(size: 30, weight: .bold)
        #else
        .largeTitle.bold()
        #endif
    }

    private var scheduleIOSDateSubtitleFont: Font {
        #if os(iOS)
        .footnote
        #else
        .subheadline
        #endif
    }

    private var scheduleIOSChineseCalendarFont: Font {
        #if os(iOS)
        .caption2.weight(selectedChineseCalendarInfo.isFestival ? .bold : .medium)
        #else
        .caption.weight(selectedChineseCalendarInfo.isFestival ? .bold : .medium)
        #endif
    }

    private var scheduleModePicker: some View {
        Picker(PlannerCopy.text(.scheduleView, language: appLanguage), selection: $mode) {
            ForEach(ScheduleAgendaMode.allCases) { option in
                Text(option.title(language: appLanguage)).tag(option)
            }
        }
        .fufuSegmentedPickerStyle()
        #if os(iOS)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        #else
        .frame(width: 180)
        #endif
    }

    private var scheduleDatePickerButton: some View {
        Button {
            showingScheduleDatePicker.toggle()
        } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                        .font(scheduleIOSDateTitleFont)
                        .foregroundStyle(MeowPlannerTheme.cocoa)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day().year()))
                        .font(scheduleIOSDateSubtitleFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    if showChineseCalendar {
                        Text(selectedChineseCalendarInfo.displayText)
                            .font(scheduleIOSChineseCalendarFont)
                            .foregroundStyle(selectedChineseCalendarInfo.isFestival ? MeowPlannerTheme.blush : MeowPlannerTheme.caramel)
                            .lineLimit(1)
                    }
                }
                .layoutPriority(1)

                Image(systemName: "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(MeowPlannerTheme.caramel)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingScheduleDatePicker, arrowEdge: .bottom) {
            ScheduleDatePickerPanel(
                selectedDate: $selectedDate,
                mode: $mode,
                showChineseCalendar: showChineseCalendar,
                language: appLanguage,
                calendar: calendar
            )
        }
    }

    private var preference: PlannerPreference {
        preferences.first ?? PlannerPreference.defaults
    }

    private var scheduleCollapsedStartHour: Int {
        PlannerPreference.normalizedCollapsedHourRange(
            start: preferences.first?.scheduleCollapsedStartHour ?? PlannerPreference.defaults.scheduleCollapsedStartHour,
            end: preferences.first?.scheduleCollapsedEndHour ?? PlannerPreference.defaults.scheduleCollapsedEndHour
        ).start
    }

    private var scheduleCollapsedEndHour: Int {
        PlannerPreference.normalizedCollapsedHourRange(
            start: preferences.first?.scheduleCollapsedStartHour ?? PlannerPreference.defaults.scheduleCollapsedStartHour,
            end: preferences.first?.scheduleCollapsedEndHour ?? PlannerPreference.defaults.scheduleCollapsedEndHour
        ).end
    }

    private var scheduleTimeCollapseEnabled: Bool {
        preference.scheduleTimeCollapseEnabled
    }

    private var timeDisplayPreference: TimeDisplayPreference {
        preference.timeDisplayPreference
    }

    private var showCompletedSchedules: Bool {
        preference.showCompletedSchedules
    }

    private var completedSchedulesUseStrikethrough: Bool {
        preference.completedSchedulesUseStrikethrough
    }

    private var showChineseCalendar: Bool {
        preference.showChineseCalendar
    }

    private var selectedChineseCalendarInfo: ChineseCalendarDayInfo {
        ChineseCalendarInfoProvider.info(for: selectedDate, calendar: calendar)
    }

    #if os(iOS)
    private var scheduleDatePickerSelection: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newValue in
                selectedDate = newValue
            }
        )
    }

    private func presentIOSScheduleDatePicker() {
        showingScheduleDatePicker = true
    }

    private func resetScheduleDateToToday() {
        selectedDate = Date()
    }

    private var scheduleIOSNavigationTitle: String {
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let year = components.year ?? 0
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d.%02d.%02d", year, month, day)
    }

    private func syncIOSScheduleNavigationState() {
        iosNavigationState.configure(
            displayedMonthTitle: scheduleIOSNavigationTitle,
            selectedTagName: nil,
            tagNames: [],
            resetToToday: { resetScheduleDateToToday() },
            presentMonthPicker: { presentIOSScheduleDatePicker() },
            selectTag: { _ in }
        )
    }
    #endif

    private var scheduleBackgroundMotifs: some View {
        GeometryReader { proxy in
            ZStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 240, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.fufuPawTint.opacity(0.10))
                    .rotationEffect(.degrees(-12))
                    .position(x: proxy.size.width * 0.18, y: proxy.size.height * 0.58)

                Image(systemName: "pawprint")
                    .font(.system(size: 170, weight: .semibold))
                    .foregroundStyle(MeowPlannerTheme.caramel.opacity(0.13))
                    .rotationEffect(.degrees(8))
                    .position(x: proxy.size.width * 0.52, y: proxy.size.height * 0.30)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 260, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.blush.opacity(0.10))
                    .rotationEffect(.degrees(15))
                    .position(x: proxy.size.width * 0.84, y: proxy.size.height * 0.62)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }

    private var weekDates: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return [selectedDate]
        }

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekInterval.start)
        }
    }

    private func moveDate(by value: Int) {
        let component: Calendar.Component = mode == .daily ? .day : .weekOfYear
        selectedDate = calendar.date(byAdding: component, value: value, to: selectedDate) ?? selectedDate
    }

}

#if os(iOS)
private struct IOSScheduleWheelDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: Date
    var yearRange: ClosedRange<Int>
    var language: AppLanguage
    var calendar: Calendar

    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    init(selection: Binding<Date>, yearRange: ClosedRange<Int>, language: AppLanguage, calendar: Calendar) {
        _selection = selection
        self.yearRange = yearRange
        self.language = language
        self.calendar = calendar

        let components = calendar.dateComponents([.year, .month, .day], from: selection.wrappedValue)
        let year = components.year ?? yearRange.lowerBound
        let month = components.month ?? 1
        let day = components.day ?? 1
        let clampedYear = min(max(year, yearRange.lowerBound), yearRange.upperBound)
        let clampedMonth = min(max(month, 1), 12)
        let clampedDay = min(max(day, 1), Self.daysInMonth(year: clampedYear, month: clampedMonth, calendar: calendar))
        _selectedYear = State(initialValue: clampedYear)
        _selectedMonth = State(initialValue: clampedMonth)
        _selectedDay = State(initialValue: clampedDay)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Text(PlannerCopy.text(.cancel, language: language))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
                .buttonStyle(.plain)

                Divider()

                Button {
                    selection = selectedDate
                    dismiss()
                } label: {
                    Text(confirmTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MeowPlannerTheme.cocoa)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
                .buttonStyle(.plain)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(MeowPlannerTheme.caramel.opacity(0.12))
                    .frame(height: 1)
            }

            HStack(spacing: 0) {
                Picker("Year", selection: $selectedYear) {
                    ForEach(Array(yearRange), id: \.self) { year in
                        Text(yearText(for: year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(monthText(for: month)).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("Day", selection: $selectedDay) {
                    ForEach(dayRange, id: \.self) { day in
                        Text(dayText(for: day)).tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 224)
            .background(MeowPlannerTheme.fufuPlannerBackground)
        }
        .background(MeowPlannerTheme.fufuPlannerBackground)
        .onChange(of: selectedYear) { _, _ in
            clampSelectedDay()
        }
        .onChange(of: selectedMonth) { _, _ in
            clampSelectedDay()
        }
    }

    private var confirmTitle: String {
        switch language {
        case .english:
            return "Confirm"
        case .chinese:
            return "确认"
        }
    }

    private var selectedDate: Date {
        let time = calendar.dateComponents([.hour, .minute, .second], from: selection)
        var components = DateComponents()
        components.calendar = calendar
        components.year = selectedYear
        components.month = selectedMonth
        components.day = min(max(selectedDay, 1), daysInSelectedMonth)
        components.hour = time.hour
        components.minute = time.minute
        components.second = time.second
        return calendar.date(from: components) ?? selection
    }

    private var dayRange: ClosedRange<Int> {
        1...daysInSelectedMonth
    }

    private var daysInSelectedMonth: Int {
        Self.daysInMonth(year: selectedYear, month: selectedMonth, calendar: calendar)
    }

    private func clampSelectedDay() {
        selectedDay = min(max(selectedDay, 1), daysInSelectedMonth)
    }

    private static func daysInMonth(year: Int, month: Int, calendar: Calendar) -> Int {
        var components = DateComponents()
        components.calendar = calendar
        components.year = year
        components.month = month
        components.day = 1
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date)
        else {
            return 31
        }
        return max(1, range.count)
    }

    private func yearText(for year: Int) -> String {
        switch language {
        case .english:
            return "\(year)"
        case .chinese:
            return "\(year) 年"
        }
    }

    private func monthText(for month: Int) -> String {
        switch language {
        case .english:
            var components = DateComponents()
            components.calendar = calendar
            components.year = 2026
            components.month = month
            components.day = 1
            guard let date = calendar.date(from: components) else {
                return "\(month)"
            }
            return date.formatted(.dateTime.month(.twoDigits))
        case .chinese:
            return month < 10 ? "0\(month) 月" : "\(month) 月"
        }
    }

    private func dayText(for day: Int) -> String {
        switch language {
        case .english:
            return day < 10 ? "0\(day)" : "\(day)"
        case .chinese:
            return day < 10 ? "0\(day) 日" : "\(day) 日"
        }
    }
}
#endif

private struct ScheduleDatePickerPanel: View {
    @Binding var selectedDate: Date
    @Binding var mode: ScheduleAgendaMode
    var showChineseCalendar: Bool
    var language: AppLanguage
    var calendar: Calendar

    @State private var displayedMonth = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker(PlannerCopy.text(.scheduleView, language: language), selection: $mode) {
                ForEach(ScheduleAgendaMode.allCases) { option in
                    Text(option.title(language: language)).tag(option)
                }
            }
            .fufuSegmentedPickerStyle()

            HStack {
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline.bold())
                    .foregroundStyle(MeowPlannerTheme.cocoa)

                Spacer()

                monthNavigationButton(systemImage: "chevron.left", offset: -1)
                monthNavigationButton(systemImage: "chevron.right", offset: 1)
            }

            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(inlineCalendarDays, id: \.self) { date in
                    dayButton(for: date)
                }
            }
        }
        .padding(14)
        .frame(width: 330)
        .background(MeowPlannerTheme.fufuPlannerBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(MeowPlannerTheme.blush.opacity(0.22), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            displayedMonth = monthStart(for: selectedDate)
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = language == .chinese
            ? ["日", "一", "二", "三", "四", "五", "六"]
            : calendar.shortWeekdaySymbols
        let startIndex = max(0, min(6, calendar.firstWeekday - 1))
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }

    private var inlineCalendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstWeek.start)
        }
    }

    private func monthNavigationButton(systemImage: String, offset: Int) -> some View {
        Button {
            displayedMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) ?? displayedMonth
        } label: {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .frame(width: 28, height: 28)
                .background(MeowPlannerTheme.warmCream.opacity(0.26), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func dayButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isInDisplayedMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        let info = ChineseCalendarInfoProvider.info(for: date, calendar: calendar)

        return Button {
            selectDate(date)
        } label: {
            VStack(spacing: 1) {
                Text(date.formatted(.dateTime.day()))
                    .font(.caption.weight(isSelected ? .bold : .medium))
                if showChineseCalendar {
                    Text(info.displayText)
                        .font(.system(size: 8, weight: info.isFestival ? .bold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .foregroundStyle(dayForeground(isSelected: isSelected, isInDisplayedMonth: isInDisplayedMonth, info: info))
            .frame(maxWidth: .infinity)
            .frame(height: showChineseCalendar ? 36 : 30)
            .background(isSelected ? MeowPlannerTheme.caramel : MeowPlannerTheme.warmCream.opacity(0.22), in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private func dayForeground(isSelected: Bool, isInDisplayedMonth: Bool, info: ChineseCalendarDayInfo) -> Color {
        if isSelected {
            return .white
        }
        if info.isFestival {
            return MeowPlannerTheme.blush
        }
        return isInDisplayedMonth ? MeowPlannerTheme.cocoa : MeowPlannerTheme.cocoa.opacity(0.36)
    }

    private func selectDate(_ date: Date) {
        let time = calendar.dateComponents([.hour, .minute, .second], from: selectedDate)
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        var merged = DateComponents()
        merged.year = day.year
        merged.month = day.month
        merged.day = day.day
        merged.hour = time.hour
        merged.minute = time.minute
        merged.second = time.second
        selectedDate = calendar.date(from: merged) ?? date
        displayedMonth = monthStart(for: date)
    }

    private func monthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}

private struct ScheduleTimeGridView: View {
    var mode: ScheduleAgendaMode
    var selectedDate: Date
    var dayDates: [Date]
    var events: [PlannerEvent]
    var timeCollapseEnabled: Bool
    var collapsedStartHour: Int
    var collapsedEndHour: Int
    var timeDisplayPreference: TimeDisplayPreference
    var showCompletedSchedules: Bool
    var completedSchedulesUseStrikethrough: Bool
    @Binding var isEarlyMorningExpanded: Bool
    var language: AppLanguage
    var calendar: Calendar
    var usesOuterVerticalScroll: Bool = false

    private let hourRowHeight: CGFloat = 64
    private let dailyMinimumDayWidth: CGFloat = 80
    private let timeColumnWidth: CGFloat = 58
    private let allDayLaneHeight: CGFloat = 46
    private let earlyMorningCollapsedHeight: CGFloat = 44
    private var earlyMorningHours: [Int] {
        Array(collapsedStartHour..<collapsedEndHour)
    }

    var body: some View {
        VStack(spacing: 0) {
            fixedTimelineHeader

            if usesOuterVerticalScroll {
                scrollableTimelineRows
            } else {
                ScrollView(.vertical) {
                    scrollableTimelineRows
                }
                .verticalPageScrollOnly()
                .scrollContentBackground(.hidden)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var fixedTimelineHeader: some View {
        VStack(spacing: 0) {
            weekdayHeader
            allDayLane
            if timeCollapseEnabled {
                earlyMorningToggle
            }
        }
    }

    private var scrollableTimelineRows: some View {
        timeGrid
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            Text(mode == .daily ? selectedDate.formatted(.dateTime.month().day()) : "")
                .frame(width: timeColumnWidth, alignment: .leading)
                .foregroundStyle(.secondary)

            ForEach(dayDates, id: \.self) { date in
                VStack(spacing: 3) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(weekdaySymbolFont)
                    Text(date.formatted(.dateTime.day()))
                        .font(weekdayDayFont(for: date))
                        .padding(.horizontal, calendar.isDateInToday(date) ? 8 : 0)
                        .padding(.vertical, calendar.isDateInToday(date) ? 2 : 0)
                        .background(calendar.isDateInToday(date) ? MeowPlannerTheme.blush : .clear, in: Capsule())
                        .foregroundStyle(calendar.isDateInToday(date) ? .white : MeowPlannerTheme.cocoa)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MeowPlannerTheme.cream.opacity(0.46))
    }

    private var weekdaySymbolFont: Font {
        mode == .weekly ? .caption2.weight(.semibold) : .subheadline.weight(.semibold)
    }

    private func weekdayDayFont(for date: Date) -> Font {
        if mode == .weekly {
            return .caption.weight(calendar.isDateInToday(date) ? .bold : .medium)
        }

        return calendar.isDateInToday(date) ? .headline.bold() : .subheadline
    }

    private var allDayLane: some View {
        HStack(spacing: 0) {
            Text(PlannerCopy.text(.allDay, language: language))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: timeColumnWidth, alignment: .leading)

            ForEach(dayDates, id: \.self) { date in
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(allDayEvents(on: date).prefix(2)) { event in
                        eventPill(event)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 6)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(MeowPlannerTheme.caramel.opacity(0.10))
                        .frame(width: 1)
                }
            }
        }
        .frame(height: allDayLaneHeight)
        .padding(.horizontal, 12)
        .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.62))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MeowPlannerTheme.caramel.opacity(0.18))
                .frame(height: 1)
        }
    }

    private var earlyMorningToggle: some View {
        Button {
            isEarlyMorningExpanded.toggle()
        } label: {
            HStack(spacing: 10) {
                Text("\(formatHour(collapsedStartHour))-\(formatHour(collapsedEndHour))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MeowPlannerTheme.caramel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .layoutPriority(1)
                    .frame(minWidth: 96, alignment: .leading)
                Image(systemName: isEarlyMorningExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(MeowPlannerTheme.caramel)
                Text(isEarlyMorningExpanded ? "Expanded" : "Collapsed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: earlyMorningCollapsedHeight)
            .background(MeowPlannerTheme.warmCream.opacity(0.22))
        }
        .buttonStyle(.plain)
    }

    private var timeGrid: some View {
        GeometryReader { proxy in
            let dayWidth = timelineDayWidth(for: proxy.size.width)

            ZStack(alignment: .topLeading) {
                hourRows(dayWidth: dayWidth)

                ForEach(Array(dayDates.enumerated()), id: \.element) { index, date in
                    ForEach(timedEvents(on: date)) { event in
                        eventBlock(event)
                            .frame(width: eventColumnWidth(dayWidth: dayWidth), height: eventHeight(event))
                            .offset(
                                x: timeColumnWidth + 12 + CGFloat(index) * dayWidth + eventHorizontalInset,
                                y: eventOffset(event)
                            )
                    }
                }

                currentTimeLine(dayWidth: dayWidth)
            }
            .frame(height: gridHeight)
        }
        .frame(height: gridHeight)
    }

    private func timelineDayWidth(for availableWidth: CGFloat) -> CGFloat {
        let dayCount = CGFloat(max(dayDates.count, 1))
        let availableDayWidth = max(1, availableWidth - timeColumnWidth - 24)

        if mode == .weekly {
            return max(24, availableDayWidth / dayCount)
        }

        return max(dailyMinimumDayWidth, availableDayWidth / dayCount)
    }

    private var eventHorizontalInset: CGFloat {
        mode == .weekly ? 2 : 6
    }

    private func eventColumnWidth(dayWidth: CGFloat) -> CGFloat {
        if mode == .weekly {
            return max(18, dayWidth - eventHorizontalInset * 2)
        }

        return max(70, dayWidth - 12)
    }

    private func hourRows(dayWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(visibleHours, id: \.self) { hour in
                HStack(spacing: 0) {
                    Text(hourLabel(hour))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MeowPlannerTheme.caramel.opacity(0.72))
                        .frame(width: timeColumnWidth, alignment: .leading)
                        .padding(.leading, 12)

                    ForEach(dayDates, id: \.self) { date in
                        Rectangle()
                            .fill(calendar.isDateInToday(date) ? MeowPlannerTheme.fufuBlue.opacity(0.035) : Color.white.opacity(0.10))
                            .frame(width: dayWidth, height: hourRowHeight)
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(MeowPlannerTheme.caramel.opacity(0.14))
                                    .frame(height: 1)
                            }
                            .overlay(alignment: .trailing) {
                                Rectangle()
                                    .fill(MeowPlannerTheme.caramel.opacity(0.10))
                                    .frame(width: 1)
                            }
                    }
                }
                .frame(height: hourRowHeight)
            }
        }
    }

    private func eventBlock(_ event: PlannerEvent) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(event.title)
                .font(eventBlockTitleFont)
                .lineLimit(1)
                .strikethrough(event.isCompleted && completedSchedulesUseStrikethrough)
            Text(eventTimeSummary(event))
                .font(eventBlockDetailFont)
                .lineLimit(1)
                .strikethrough(event.isCompleted && completedSchedulesUseStrikethrough)
            if !event.tagName.isEmpty {
                Text(event.tagName)
                    .font(eventBlockDetailFont.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .padding(mode == .weekly ? 3 : 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MeowPlannerTheme.color(hex: event.colorHex).opacity(0.86), in: RoundedRectangle(cornerRadius: mode == .weekly ? 4 : 6))
        .shadow(color: MeowPlannerTheme.coffee.opacity(0.10), radius: 4, y: 2)
    }

    private var eventBlockTitleFont: Font {
        mode == .weekly ? .system(size: 8, weight: .bold) : .caption.weight(.bold)
    }

    private var eventBlockDetailFont: Font {
        mode == .weekly ? .system(size: 7, weight: .medium) : .caption2
    }

    private func eventPill(_ event: PlannerEvent) -> some View {
        Text(event.title)
            .font(mode == .weekly ? .system(size: 7, weight: .semibold) : .caption2.weight(.semibold))
            .lineLimit(1)
            .strikethrough(event.isCompleted && completedSchedulesUseStrikethrough)
            .padding(.horizontal, mode == .weekly ? 3 : 6)
            .padding(.vertical, mode == .weekly ? 1 : 2)
            .foregroundStyle(.white)
            .background(MeowPlannerTheme.color(hex: event.colorHex).opacity(0.86), in: Capsule())
    }

    private func currentTimeLine(dayWidth: CGFloat) -> some View {
        Group {
            if shouldShowCurrentTimeLine {
                HStack(spacing: 0) {
                    Text(currentTimeText)
                        .font(.caption.bold())
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(MeowPlannerTheme.blush, in: Capsule())
                        .frame(width: timeColumnWidth, alignment: .leading)

                    Rectangle()
                        .fill(MeowPlannerTheme.blush)
                        .frame(width: currentTimeLineWidth(dayWidth: dayWidth), height: 2)
                }
                .offset(x: 12, y: currentTimeOffset)
            }
        }
    }

    private var visibleHours: [Int] {
        if !timeCollapseEnabled || isEarlyMorningExpanded {
            return Array(0..<24)
        }

        return Array(0..<collapsedStartHour) + Array(collapsedEndHour..<24)
    }

    private var firstVisibleHour: Int {
        visibleHours.first ?? 0
    }

    private var gridHeight: CGFloat {
        CGFloat(visibleHours.count) * hourRowHeight
    }

    private var shouldShowCurrentTimeLine: Bool {
        let now = Date()
        guard visibleHours.contains(calendar.component(.hour, from: now)) else {
            return false
        }
        return dayDates.contains { calendar.isDate($0, inSameDayAs: now) }
    }

    private var currentTimeOffset: CGFloat {
        timeOffset(for: Date())
    }

    private var currentTimeText: String {
        formatTime(Date())
    }

    private func currentTimeLineWidth(dayWidth: CGFloat) -> CGFloat {
        if mode == .daily {
            return dayWidth
        }
        return dayWidth * CGFloat(dayDates.count)
    }

    private func eventHeight(_ event: PlannerEvent) -> CGFloat {
        guard let endDate = event.endDate else {
            return max(34, hourRowHeight * 0.62)
        }
        let duration = max(1_800, endDate.timeIntervalSince(event.startDate))
        return max(34, CGFloat(duration / 3_600) * hourRowHeight - 4)
    }

    private func eventOffset(_ event: PlannerEvent) -> CGFloat {
        timeOffset(for: event.startDate) + 3
    }

    private func timeOffset(for date: Date) -> CGFloat {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        guard let hourIndex = visibleHours.firstIndex(of: hour) else {
            let insertionIndex = visibleHours.firstIndex { $0 > hour } ?? visibleHours.count
            return CGFloat(max(0, insertionIndex)) * hourRowHeight
        }
        return (CGFloat(hourIndex) + CGFloat(minute) / 60.0) * hourRowHeight
    }

    private func hourLabel(_ hour: Int) -> String {
        formatHour(hour)
    }

    private func formatHour(_ hour: Int) -> String {
        switch timeDisplayPreference {
        case .twentyFourHour:
            return String(format: "%02d:00", hour)
        case .twelveHour:
            let period = hour < 12 ? "AM" : "PM"
            let hourValue = hour % 12 == 0 ? 12 : hour % 12
            return "\(hourValue):00 \(period)"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        switch timeDisplayPreference {
        case .twentyFourHour:
            return String(format: "%02d:%02d", hour, minute)
        case .twelveHour:
            let period = hour < 12 ? "AM" : "PM"
            let hourValue = hour % 12 == 0 ? 12 : hour % 12
            return String(format: "%d:%02d %@", hourValue, minute, period)
        }
    }

    private func eventTimeSummary(_ event: PlannerEvent) -> String {
        if event.isAllDay {
            return PlannerCopy.text(.allDay, language: language)
        }

        guard let endDate = event.endDate else {
            return formatTime(event.startDate)
        }

        return "\(formatTime(event.startDate))-\(formatTime(endDate))"
    }

    private func allDayEvents(on date: Date) -> [PlannerEvent] {
        events(on: date).filter(\.isAllDay)
    }

    private func timedEvents(on date: Date) -> [PlannerEvent] {
        events(on: date).filter { !$0.isAllDay }
    }

    private func events(on date: Date) -> [PlannerEvent] {
        events
            .filter { eventOccurs($0, on: date) }
            .filter { event in showCompletedSchedules || !event.isCompleted }
            .sorted { $0.startDate < $1.startDate }
    }

    private func eventOccurs(_ event: PlannerEvent, on date: Date) -> Bool {
        event.occurs(on: date, calendar: calendar)
    }
}

#if os(macOS)
private struct SidebarToolbarOverflowCleaner: NSViewRepresentable {
    var trigger: NavigationSplitViewVisibility

    func makeNSView(context: Context) -> CleanerView {
        CleanerView()
    }

    func updateNSView(_ nsView: CleanerView, context: Context) {
        _ = trigger
        nsView.removeSidebarToolbarOverflowSoon()
    }

    final class CleanerView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            removeSidebarToolbarOverflowSoon()
        }

        func removeSidebarToolbarOverflowSoon() {
            for delay in [0.0, 0.08, 0.24, 0.6, 1.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let window = self?.window else {
                        return
                    }

                    window.toolbar?.isVisible = false
                    window.toolbar?.showsBaselineSeparator = false
                    MainWindowChromeConfigurator.apply(to: window)
                }
            }
        }
    }
}

private struct MainWindowResizeAffordanceInstaller: NSViewRepresentable {
    func makeNSView(context: Context) -> InstallerView {
        InstallerView()
    }

    func updateNSView(_ nsView: InstallerView, context: Context) {
        nsView.installResizeViewSoon()
    }

    final class InstallerView: NSView {
        private weak var resizeView: ResizeView?

        override var acceptsFirstResponder: Bool {
            false
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            installResizeViewSoon()
        }

        override func viewWillMove(toWindow newWindow: NSWindow?) {
            if newWindow == nil {
                resizeView?.removeFromSuperview()
                resizeView = nil
            }

            super.viewWillMove(toWindow: newWindow)
        }

        func installResizeViewSoon() {
            DispatchQueue.main.async { [weak self] in
                self?.installResizeView()
            }
        }

        private func installResizeView() {
            guard let window,
                  let contentView = window.contentView
            else {
                return
            }

            MainWindowChromeConfigurator.apply(to: window)

            let existingResizeView = contentView.subviews.compactMap { $0 as? ResizeView }.first
            let resizeView = self.resizeView ?? existingResizeView ?? ResizeView()
            if resizeView.superview != nil {
                resizeView.removeFromSuperview()
            }

            resizeView.frame = contentView.bounds
            resizeView.autoresizingMask = [.width, .height]
            contentView.addSubview(resizeView, positioned: .above, relativeTo: nil)
            resizeView.refreshWindowChrome()
            self.resizeView = resizeView
        }
    }

    final class ResizeView: NSView {
        private let edgeThickness: CGFloat = 16
        private var activeRegion: ResizeRegion = []
        private var dragStartFrame: NSRect = .zero
        private var dragStartScreenPoint: NSPoint = .zero
        private var trackingArea: NSTrackingArea?

        override var acceptsFirstResponder: Bool {
            false
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            refreshWindowChrome()
        }

        override func layout() {
            super.layout()
            window?.invalidateCursorRects(for: self)
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()

            if let trackingArea {
                removeTrackingArea(trackingArea)
            }

            let area = NSTrackingArea(
                rect: bounds,
                options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(area)
            trackingArea = area
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard isResizable,
                  !resizeRegion(at: point).isEmpty
            else {
                return nil
            }

            return self
        }

        override func resetCursorRects() {
            super.resetCursorRects()
            guard isResizable else {
                return
            }

            let edge = edgeThickness
            let horizontalWidth = max(0, bounds.width - edge * 2)
            let verticalHeight = max(0, bounds.height - edge * 2)

            addCursorRect(NSRect(x: edge, y: bounds.maxY - edge, width: horizontalWidth, height: edge), cursor: NSCursor.resizeUpDown)
            addCursorRect(NSRect(x: edge, y: bounds.minY, width: horizontalWidth, height: edge), cursor: NSCursor.resizeUpDown)
            addCursorRect(NSRect(x: bounds.minX, y: edge, width: edge, height: verticalHeight), cursor: NSCursor.resizeLeftRight)
            addCursorRect(NSRect(x: bounds.maxX - edge, y: edge, width: edge, height: verticalHeight), cursor: NSCursor.resizeLeftRight)
            addCursorRect(NSRect(x: bounds.minX, y: bounds.maxY - edge, width: edge, height: edge), cursor: Self.northwestSoutheastCursor)
            addCursorRect(NSRect(x: bounds.maxX - edge, y: bounds.minY, width: edge, height: edge), cursor: Self.northwestSoutheastCursor)
            addCursorRect(NSRect(x: bounds.maxX - edge, y: bounds.maxY - edge, width: edge, height: edge), cursor: Self.northeastSouthwestCursor)
            addCursorRect(NSRect(x: bounds.minX, y: bounds.minY, width: edge, height: edge), cursor: Self.northeastSouthwestCursor)
        }

        override func mouseMoved(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            resizeCursor(for: resizeRegion(at: point))?.set()
        }

        override func mouseDown(with event: NSEvent) {
            guard let window else {
                return
            }

            activeRegion = resizeRegion(at: convert(event.locationInWindow, from: nil))
            guard !activeRegion.isEmpty else {
                return
            }

            dragStartFrame = window.frame
            dragStartScreenPoint = window.convertPoint(toScreen: event.locationInWindow)
        }

        override func mouseDragged(with event: NSEvent) {
            guard let window,
                  !activeRegion.isEmpty
            else {
                return
            }

            var frame = resizedFrame(for: event, in: window)
            clamp(&frame, for: window)
            window.setFrame(frame, display: true)
        }

        override func mouseUp(with event: NSEvent) {
            activeRegion = []
        }

        @MainActor
        func refreshWindowChrome() {
            guard let window else {
                return
            }

            window.acceptsMouseMovedEvents = true
            MainWindowChromeConfigurator.apply(to: window)
            window.invalidateCursorRects(for: self)
        }

        private var isResizable: Bool {
            window?.styleMask.contains(.resizable) == true
        }

        private func resizeRegion(at point: NSPoint) -> ResizeRegion {
            guard bounds.width > edgeThickness * 2,
                  bounds.height > edgeThickness * 2
            else {
                return []
            }

            var region: ResizeRegion = []
            if point.x <= bounds.minX + edgeThickness {
                region.insert(.left)
            }
            if point.x >= bounds.maxX - edgeThickness {
                region.insert(.right)
            }
            if point.y <= bounds.minY + edgeThickness {
                region.insert(.bottom)
            }
            if point.y >= bounds.maxY - edgeThickness {
                region.insert(.top)
            }
            return region
        }

        private func resizeCursor(for region: ResizeRegion) -> NSCursor? {
            if region.contains([.top, .left]) || region.contains([.bottom, .right]) {
                return Self.northwestSoutheastCursor
            }
            if region.contains([.top, .right]) || region.contains([.bottom, .left]) {
                return Self.northeastSouthwestCursor
            }
            if region.contains(.left) || region.contains(.right) {
                return NSCursor.resizeLeftRight
            }
            if region.contains(.top) || region.contains(.bottom) {
                return NSCursor.resizeUpDown
            }
            return nil
        }

        private func resizedFrame(for event: NSEvent, in window: NSWindow) -> NSRect {
            let currentPoint = window.convertPoint(toScreen: event.locationInWindow)
            let deltaX = currentPoint.x - dragStartScreenPoint.x
            let deltaY = currentPoint.y - dragStartScreenPoint.y
            var frame = dragStartFrame

            if activeRegion.contains(.left) {
                frame.origin.x += deltaX
                frame.size.width -= deltaX
            }
            if activeRegion.contains(.right) {
                frame.size.width += deltaX
            }
            if activeRegion.contains(.bottom) {
                frame.origin.y += deltaY
                frame.size.height -= deltaY
            }
            if activeRegion.contains(.top) {
                frame.size.height += deltaY
            }

            return frame
        }

        private func clamp(_ frame: inout NSRect, for window: NSWindow) {
            let minimumContentSize = window.contentMinSize
            let minimumFrameSize = window.frameRect(
                forContentRect: NSRect(origin: .zero, size: minimumContentSize)
            ).size

            if frame.size.width < minimumFrameSize.width {
                if activeRegion.contains(.left) {
                    frame.origin.x = frame.maxX - minimumFrameSize.width
                }
                frame.size.width = minimumFrameSize.width
            }

            if frame.size.height < minimumFrameSize.height {
                if activeRegion.contains(.bottom) {
                    frame.origin.y = frame.maxY - minimumFrameSize.height
                }
                frame.size.height = minimumFrameSize.height
            }
        }

        private static let northwestSoutheastCursor = diagonalCursor(
            systemName: "arrow.up.left.and.arrow.down.right",
            fallback: NSCursor.resizeLeftRight
        )
        private static let northeastSouthwestCursor = diagonalCursor(
            systemName: "arrow.up.right.and.arrow.down.left",
            fallback: NSCursor.resizeLeftRight
        )

        private static func diagonalCursor(systemName: String, fallback: NSCursor) -> NSCursor {
            guard let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil) else {
                return fallback
            }

            image.size = NSSize(width: 18, height: 18)
            return NSCursor(image: image, hotSpot: NSPoint(x: 9, y: 9))
        }
    }

    private struct ResizeRegion: OptionSet {
        let rawValue: Int

        static let left = ResizeRegion(rawValue: 1 << 0)
        static let right = ResizeRegion(rawValue: 1 << 1)
        static let bottom = ResizeRegion(rawValue: 1 << 2)
        static let top = ResizeRegion(rawValue: 1 << 3)
    }
}

private struct SidebarSectionRow: View {
    var section: AppSection
    var language: AppLanguage
    var isSelected: Bool
    var isReordering: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24, height: 24)

            Text(section.title(language: language))
                .font(.body.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 0)

            if isReordering {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.82) : MeowPlannerTheme.caramel)
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(isSelected ? Color.white : MeowPlannerTheme.cocoa)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(isSelected ? MeowPlannerTheme.softBrownHighlight : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(section.title(language: language))
    }
}

private struct SidebarDragPreviewView: View {
    var title: String
    var systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(MeowPlannerTheme.cocoa)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(MeowPlannerTheme.cream.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: MeowPlannerTheme.caramel.opacity(0.16), radius: 8, y: 4)
    }
}
#endif
