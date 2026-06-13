import MeowPlannerCore
import SwiftData
import SwiftUI
import WidgetKit

enum SettingsDestination: Hashable {
    case account
    case personalization
}

private enum SettingsSheet: String, Identifiable {
    case eventColorEditor
    case linkAccount
    case changePassword
    case deleteAccount

    var id: String { rawValue }
}

struct SettingsView: View {
    @Query private var preferences: [PlannerPreference]
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppLanguage.storageKey) private var appLanguageID = AppLanguage.english.rawValue
    @AppStorage(AppAppearancePreference.storageKey) private var appearanceID = AppAppearancePreference.system.rawValue
    @AppStorage(AppDockIconController.storageKey) private var showDockIcon = AppDockIconController.defaultShowDockIcon
    @StateObject private var accountStore = AccountSessionStore.shared
    private let defaults = UserDefaults.standard

    @State private var focusMinutes = PlannerPreference.defaults.defaultFocusMinutes
    @State private var weekStartPreference = PlannerPreference.defaults.weekStartPreference
    @State private var notificationsEnabled = true
    @State private var defaultEventIsAllDay = PlannerPreference.defaults.defaultEventIsAllDay
    @State private var showCompletedSchedules = PlannerPreference.defaults.showCompletedSchedules
    @State private var hideCompletedSchedules = !PlannerPreference.defaults.showCompletedSchedules
    @State private var completedSchedulesUseStrikethrough = PlannerPreference.defaults.completedSchedulesUseStrikethrough
    @State private var showChineseCalendar = PlannerPreference.defaults.showChineseCalendar
    @State private var scheduleTimeCollapseEnabled = PlannerPreference.defaults.scheduleTimeCollapseEnabled
    @State private var scheduleCollapsedStartHour = PlannerPreference.defaults.scheduleCollapsedStartHour
    @State private var scheduleCollapsedEndHour = PlannerPreference.defaults.scheduleCollapsedEndHour
    @State private var timeDisplayPreference = PlannerPreference.defaults.timeDisplayPreference
    @State private var eventColorHexes = PlannerPreference.defaultEventColorHexes
    @State private var showingTimeCollapsePanel = false
    @State private var activeSettingsSheet: SettingsSheet?
    @State private var showingDeleteAccountConfirmation = false
    @State private var eventColorEditorHex = PlannerPreference.defaultEventColorHexes[0]
    @State private var eventColorEditorOriginalHex: String?
    @Binding private var navigationPath: [SettingsDestination]

    init(navigationPath: Binding<[SettingsDestination]> = .constant([])) {
        _navigationPath = navigationPath
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            settingsHomePage
                .navigationDestination(for: SettingsDestination.self) { destination in
                    switch destination {
                    case .account:
                        accountSettingsPage
                    case .personalization:
                        personalizationSettingsPage
                    }
                }
        }
        .background(MeowPlannerTheme.plannerGradient)
        .alert(PlannerCopy.text(.deleteAccountConfirmationMessage, language: appLanguage), isPresented: $showingDeleteAccountConfirmation) {
            Button(PlannerCopy.text(.cancel, language: appLanguage), role: .cancel) {}
            Button(PlannerCopy.text(.deleteAccount, language: appLanguage), role: .destructive) {
                activeSettingsSheet = .deleteAccount
            }
        }
        .onAppear(perform: loadPreference)
        .onChange(of: appLanguageID) { _, _ in
            defaults.set(Date().timeIntervalSince1970, forKey: AppLanguage.updatedAtStorageKey)
        }
        .onChange(of: appearanceID) { _, _ in
            defaults.set(Date().timeIntervalSince1970, forKey: AppAppearancePreference.updatedAtStorageKey)
        }
        .onChange(of: focusMinutes) { _, newValue in
            preference.defaultFocusMinutes = newValue
            try? modelContext.save()
        }
        .onChange(of: weekStartPreference) { _, newValue in
            preference.weekStartPreference = newValue
            WidgetPlannerPreferenceStore.weekStartPreference = newValue
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
            try? modelContext.save()
        }
        .onChange(of: notificationsEnabled) { _, newValue in
            preference.localRemindersEnabled = newValue
            try? modelContext.save()
        }
        .onChange(of: defaultEventIsAllDay) { _, newValue in
            preference.defaultEventIsAllDay = newValue
            try? modelContext.save()
        }
        .onChange(of: hideCompletedSchedules) { _, newValue in
            showCompletedSchedules = !newValue
            preference.showCompletedSchedules = !newValue
            try? modelContext.save()
        }
        .onChange(of: completedSchedulesUseStrikethrough) { _, newValue in
            preference.completedSchedulesUseStrikethrough = newValue
            try? modelContext.save()
        }
        .onChange(of: showChineseCalendar) { _, newValue in
            preference.showChineseCalendar = newValue
            WidgetPlannerPreferenceStore.showChineseCalendar = newValue
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.todayKind)
            try? modelContext.save()
        }
        .onChange(of: scheduleTimeCollapseEnabled) { _, newValue in
            preference.scheduleTimeCollapseEnabled = newValue
            if newValue {
                showingTimeCollapsePanel = true
            } else {
                showingTimeCollapsePanel = false
            }
            try? modelContext.save()
        }
        .onChange(of: scheduleCollapsedStartHour) { _, _ in
            persistCollapsedHourRange()
        }
        .onChange(of: scheduleCollapsedEndHour) { _, _ in
            persistCollapsedHourRange()
        }
        .onChange(of: timeDisplayPreference) { _, newValue in
            preference.timeDisplayPreference = newValue
            try? modelContext.save()
        }
        .onChange(of: showDockIcon) { _, newValue in
            AppDockIconController.apply(showDockIcon: newValue, relaunchIfNeeded: true)
        }
    }

    private var settingsHomePage: some View {
        settingsForm {
            appHeaderSection

            Section {
                NavigationLink(value: SettingsDestination.account) {
                    SettingsDestinationRow(
                        title: PlannerCopy.text(.account, language: appLanguage),
                        subtitle: accountDestinationSubtitle,
                        systemImage: "person.crop.circle"
                    )
                }

                NavigationLink(value: SettingsDestination.personalization) {
                    SettingsDestinationRow(
                        title: PlannerCopy.text(.personalizationSettings, language: appLanguage),
                        subtitle: personalizationDestinationSubtitle,
                        systemImage: "slider.horizontal.3"
                    )
                }
            }

            scopeSection
        }
        .navigationTitle(PlannerCopy.text(.settings, language: appLanguage))
    }

    private var accountSettingsPage: some View {
        settingsForm {
            AccountSettingsSection(accountStore: accountStore)

            syncSection

            if accountStore.currentProfile != nil {
                accountActionsSection
            }
        }
        .navigationTitle(PlannerCopy.text(.account, language: appLanguage))
    }

    private var personalizationSettingsPage: some View {
        settingsForm {
            languageSection
            appearanceSection
            dockIconSection
            focusSection
            personalizationSection
            eventColorsSection
        }
        .navigationTitle(PlannerCopy.text(.personalizationSettings, language: appLanguage))
    }

    private func settingsForm<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Form {
            content()
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .verticalPageScrollOnly()
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(MeowPlannerTheme.plannerGradient)
        .sheet(item: $activeSettingsSheet) { sheet in
            settingsSheetContent(sheet)
        }
    }

    @ViewBuilder
    private func settingsSheetContent(_ sheet: SettingsSheet) -> some View {
        switch sheet {
        case .eventColorEditor:
            SettingsEventColorEditorView(
                initialColorHex: eventColorEditorHex,
                originalColorHex: eventColorEditorOriginalHex
            ) { colorHex, originalColorHex in
                if let originalColorHex {
                    updateEventColor(from: originalColorHex, to: colorHex)
                } else {
                    addEventColor(colorHex)
                }
            }
        case .changePassword:
            AccountAuthenticationModalView(
                accountStore: accountStore,
                initialMode: .changePassword
            )
        case .linkAccount:
            AccountAuthenticationModalView(
                accountStore: accountStore,
                initialMode: .linkAccount
            )
        case .deleteAccount:
            AccountAuthenticationModalView(
                accountStore: accountStore,
                initialMode: .deleteAccount
            )
        }
    }

    private var appHeaderSection: some View {
        Section {
            HStack(spacing: 14) {
                FuFuAssetImage(size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("MeowPlanner")
                        .font(.title3.bold())
                    Text(PlannerCopy.text(.fufuTimePlanner, language: appLanguage))
                        .foregroundStyle(.secondary)
                    Text(PlannerCopy.text(.appSubtitle, language: appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var languageSection: some View {
        Section(PlannerCopy.text(.language, language: appLanguage)) {
            Picker(PlannerCopy.text(.language, language: appLanguage), selection: $appLanguageID) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language.rawValue)
                }
            }
            .fufuSegmentedPickerStyle()
        }
    }

    private var appearanceSection: some View {
        Section(appearanceSectionTitle) {
            Picker(appearanceSystemModeTitle, selection: appearanceSystemModeBinding) {
                Text(AppAppearancePreference.system.title(language: appLanguage))
                    .tag(AppAppearancePreference.system.rawValue)
                Text(appearanceManualModeTitle)
                    .tag(appearanceManualSelectionID)
            }
            .fufuSegmentedPickerStyle()

            if AppAppearancePreference(storedValue: appearanceID) != .system {
                Picker(appearanceManualModeTitle, selection: appearanceManualModeBinding) {
                    Text(AppAppearancePreference.light.title(language: appLanguage))
                        .tag(AppAppearancePreference.light.rawValue)
                    Text(AppAppearancePreference.dark.title(language: appLanguage))
                        .tag(AppAppearancePreference.dark.rawValue)
                }
                .fufuSegmentedPickerStyle()
            }
        }
    }

    private var dockIconSection: some View {
        Section(PlannerCopy.text(.dockIcon, language: appLanguage)) {
            Toggle(PlannerCopy.text(.showDockIcon, language: appLanguage), isOn: $showDockIcon)
                .fufuControlTint()
        }
    }

    private var focusSection: some View {
        Section(PlannerCopy.text(.focusSettings, language: appLanguage)) {
            PlannerNumberInputRow(
                title: PlannerCopy.text(.defaultFocus, language: appLanguage),
                value: $focusMinutes,
                range: 0...Int.max,
                suffix: minuteUnit
            )
        }
    }

    private var personalizationSection: some View {
        Section(PlannerCopy.text(.personalizationSettings, language: appLanguage)) {
            Picker(PlannerCopy.text(.weekStartsOn, language: appLanguage), selection: $weekStartPreference) {
                ForEach(WeekStartPreference.allCases) { preference in
                    Text(preference.title(language: appLanguage)).tag(preference)
                }
            }
            .fufuControlTint()
            Toggle(PlannerCopy.text(.defaultAllDaySchedule, language: appLanguage), isOn: $defaultEventIsAllDay)
                .fufuControlTint()
            Toggle(PlannerCopy.text(.hideCompletedSchedules, language: appLanguage), isOn: $hideCompletedSchedules)
                .fufuControlTint()
            Toggle(PlannerCopy.text(.completedScheduleStrikethrough, language: appLanguage), isOn: $completedSchedulesUseStrikethrough)
                .fufuControlTint()
                .disabled(hideCompletedSchedules)
            Toggle(PlannerCopy.text(.showChineseCalendar, language: appLanguage), isOn: $showChineseCalendar)
                .fufuControlTint()
            Toggle(PlannerCopy.text(.timeCollapse, language: appLanguage), isOn: $scheduleTimeCollapseEnabled)
                .fufuControlTint()
            if scheduleTimeCollapseEnabled {
                timeCollapseSettingsButton
            }
            Picker(PlannerCopy.text(.timeDisplay, language: appLanguage), selection: $timeDisplayPreference) {
                ForEach(TimeDisplayPreference.allCases) { preference in
                    Text(preference.title(language: appLanguage)).tag(preference)
                }
            }
            .fufuSegmentedPickerStyle()
            Toggle(PlannerCopy.text(.localReminders, language: appLanguage), isOn: $notificationsEnabled)
                .fufuControlTint()
        }
    }

    private var eventColorsSection: some View {
        Section(PlannerCopy.text(.eventColors, language: appLanguage)) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(eventColorHexes, id: \.self) { colorHex in
                        SettingsEventColorSwatch(
                            colorHex: colorHex,
                            canDelete: eventColorHexes.count > 1,
                            onEdit: { openEventColorEditor(colorHex) },
                            onDelete: { deleteEventColor(colorHex) }
                        )
                    }

                    Button {
                        openEventColorEditor()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 32, height: 32)
                            .foregroundStyle(MeowPlannerTheme.caramel)
                            .background(MeowPlannerTheme.cream.opacity(0.72), in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(MeowPlannerTheme.caramel.opacity(0.32), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(PlannerCopy.text(.addColor, language: appLanguage))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
            }
        }
    }

    private var syncSection: some View {
        Section(PlannerCopy.text(.sync, language: appLanguage)) {
            LabeledContent(PlannerCopy.text(.icloudSync, language: appLanguage)) {
                Text(accountStore.currentProfile?.emailAddress ?? PlannerCopy.text(.notSignedIn, language: appLanguage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(PlannerCopy.text(.icloudDescription, language: appLanguage))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var scopeSection: some View {
        Section(PlannerCopy.text(.scope, language: appLanguage)) {
            Text(PlannerCopy.text(.scopeDescription, language: appLanguage))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var accountDestinationSubtitle: String {
        if let profile = accountStore.currentProfile {
            return accountDisplayName(for: profile)
        }
        return appLanguage == .chinese
            ? "登录和账号信息"
            : "Sign in and account details"
    }

    private var personalizationDestinationSubtitle: String {
        appLanguage == .chinese
            ? "语言、外观、Dock、专注和显示偏好"
            : "Language, appearance, Dock, focus, and display preferences"
    }

    private func accountDisplayName(for profile: AccountProfile) -> String {
        if let accountIdentifier = profile.accountIdentifier, !accountIdentifier.isEmpty {
            return accountIdentifier
        }
        if let displayName = profile.displayName, !displayName.isEmpty {
            return displayName
        }
        if let emailAddress = profile.emailAddress, !emailAddress.isEmpty {
            return emailAddress
        }
        return profile.provider.title(language: appLanguage)
    }

    private var preference: PlannerPreference {
        if let existing = preferences.first {
            return existing
        }

        let created = PlannerPreference.defaults
        modelContext.insert(created)
        return created
    }

    private func loadPreference() {
        focusMinutes = preference.defaultFocusMinutes
        weekStartPreference = preference.weekStartPreference
        notificationsEnabled = preference.localRemindersEnabled
        defaultEventIsAllDay = preference.defaultEventIsAllDay
        showCompletedSchedules = preference.showCompletedSchedules
        hideCompletedSchedules = !preference.showCompletedSchedules
        completedSchedulesUseStrikethrough = preference.completedSchedulesUseStrikethrough
        showChineseCalendar = preference.showChineseCalendar
        scheduleTimeCollapseEnabled = preference.scheduleTimeCollapseEnabled
        scheduleCollapsedStartHour = preference.scheduleCollapsedStartHour
        scheduleCollapsedEndHour = preference.scheduleCollapsedEndHour
        timeDisplayPreference = preference.timeDisplayPreference
        eventColorHexes = preference.eventColorHexes
        eventColorEditorHex = eventColorHexes.first ?? PlannerPreference.defaultEventColorHexes[0]
        WidgetPlannerPreferenceStore.weekStartPreference = preference.weekStartPreference
        WidgetPlannerPreferenceStore.showChineseCalendar = preference.showChineseCalendar
    }

    private var timeCollapseSettingsButton: some View {
        Button {
            showingTimeCollapsePanel.toggle()
        } label: {
            LabeledContent(PlannerCopy.text(.collapseTimeRange, language: appLanguage)) {
                HStack(spacing: 8) {
                    Text("\(hourLabel(scheduleCollapsedStartHour))-\(hourLabel(scheduleCollapsedEndHour))")
                        .monospacedDigit()
                        .foregroundStyle(MeowPlannerTheme.caramel)
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(MeowPlannerTheme.caramel.opacity(0.72))
                }
            }
        }
        .buttonStyle(.plain)
        .fufuControlTint()
        .popover(isPresented: $showingTimeCollapsePanel, arrowEdge: .bottom) {
            timeCollapseSettingsPanel
        }
    }

    private var timeCollapseSettingsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(PlannerCopy.text(.collapseTimeRange, language: appLanguage))
                .font(.headline)
                .foregroundStyle(MeowPlannerTheme.cocoa)

            PlannerNumberInputRow(
                title: PlannerCopy.text(.scheduleCollapsedStartHour, language: appLanguage),
                value: $scheduleCollapsedStartHour,
                range: 0...22,
                suffix: ":00"
            )

            Divider().opacity(0.35)

            PlannerNumberInputRow(
                title: PlannerCopy.text(.scheduleCollapsedEndHour, language: appLanguage),
                value: $scheduleCollapsedEndHour,
                range: 1...23,
                suffix: ":00"
            )
        }
        .padding(16)
        .frame(width: 320)
        .background(MeowPlannerTheme.fufuPlannerBackground)
    }

    private func persistCollapsedHourRange() {
        let normalized = PlannerPreference.normalizedCollapsedHourRange(
            start: scheduleCollapsedStartHour,
            end: scheduleCollapsedEndHour
        )
        if scheduleCollapsedStartHour != normalized.start {
            scheduleCollapsedStartHour = normalized.start
        }
        if scheduleCollapsedEndHour != normalized.end {
            scheduleCollapsedEndHour = normalized.end
        }
        preference.scheduleCollapsedStartHour = normalized.start
        preference.scheduleCollapsedEndHour = normalized.end
        try? modelContext.save()
    }

    private func hourLabel(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }

    private var minuteUnit: String {
        appLanguage == .chinese ? "分钟" : "min"
    }

    private var accountActionsSection: some View {
        Section {
            Button {
                activeSettingsSheet = .linkAccount
            } label: {
                Label(PlannerCopy.text(.linkAccount, language: appLanguage), systemImage: "person.crop.circle.badge.plus")
            }

            Button {
                activeSettingsSheet = .changePassword
            } label: {
                Label(PlannerCopy.text(.changePassword, language: appLanguage), systemImage: "key")
            }

            Button(role: .destructive) {
                showingDeleteAccountConfirmation = true
            } label: {
                SettingsDangerActionLabel(
                    title: PlannerCopy.text(.deleteAccount, language: appLanguage),
                    systemImage: "trash"
                )
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                accountStore.signOut()
            } label: {
                Label(PlannerCopy.text(.signOut, language: appLanguage), systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var appearanceManualSelectionID: String {
        "manual"
    }

    private var appearanceSectionTitle: String {
        appLanguage == .chinese ? "外观" : "Appearance"
    }

    private var appearanceSystemModeTitle: String {
        appLanguage == .chinese ? "显示模式" : "Display Mode"
    }

    private var appearanceManualModeTitle: String {
        appLanguage == .chinese ? "浅色 / 深色" : "Light / Dark"
    }

    private var appearanceSystemModeBinding: Binding<String> {
        Binding {
            AppAppearancePreference(storedValue: appearanceID) == .system
                ? AppAppearancePreference.system.rawValue
                : appearanceManualSelectionID
        } set: { newValue in
            if newValue == AppAppearancePreference.system.rawValue {
                appearanceID = AppAppearancePreference.system.rawValue
            } else if AppAppearancePreference(storedValue: appearanceID) == .system {
                appearanceID = AppAppearancePreference.light.rawValue
            }
        }
    }

    private var appearanceManualModeBinding: Binding<String> {
        Binding {
            let currentAppearance = AppAppearancePreference(storedValue: appearanceID)
            return currentAppearance == .dark
                ? AppAppearancePreference.dark.rawValue
                : AppAppearancePreference.light.rawValue
        } set: { newValue in
            appearanceID = newValue == AppAppearancePreference.dark.rawValue
                ? AppAppearancePreference.dark.rawValue
                : AppAppearancePreference.light.rawValue
        }
    }

    private func openEventColorEditor(_ colorHex: String? = nil) {
        let editorColorHex = colorHex ?? eventColorHexes.first ?? PlannerPreference.defaultEventColorHexes[0]
        eventColorEditorHex = MeowPlannerTheme.normalizedHex(editorColorHex) ?? PlannerPreference.defaultEventColorHexes[0]
        eventColorEditorOriginalHex = colorHex
        activeSettingsSheet = .eventColorEditor
    }

    private func addEventColor(_ value: String) {
        guard let normalized = MeowPlannerTheme.normalizedHex(value),
              !eventColorHexes.contains(normalized) else {
            return
        }

        eventColorHexes.append(normalized)
        preference.eventColorHexes = eventColorHexes
        try? modelContext.save()
    }

    private func updateEventColor(from originalColorHex: String, to newColorHex: String) {
        guard let original = MeowPlannerTheme.normalizedHex(originalColorHex),
              let updated = MeowPlannerTheme.normalizedHex(newColorHex) else {
            return
        }

        var colors = eventColorHexes
        if let index = colors.firstIndex(of: original) {
            colors[index] = updated
        } else {
            colors.append(updated)
        }
        eventColorHexes = PlannerPreference.normalizedEventColorHexes(colors)
        preference.eventColorHexes = eventColorHexes
        try? modelContext.save()
    }

    private func deleteEventColor(_ colorHex: String) {
        guard eventColorHexes.count > 1 else {
            return
        }

        eventColorHexes.removeAll { $0 == colorHex }
        preference.eventColorHexes = eventColorHexes
        try? modelContext.save()
    }
}

private struct SettingsDestinationRow: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(width: 24, height: 24)
        }
        .padding(.vertical, 3)
    }
}

private struct SettingsDangerActionLabel: View {
    var title: String
    var systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(.red)
            .lineLimit(1)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.red.opacity(0.28), lineWidth: 1)
            }
    }
}

private struct SettingsEventColorSwatch: View {
    @Environment(\.appLanguage) private var appLanguage

    var colorHex: String
    var canDelete: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Circle()
            .fill(MeowPlannerTheme.color(hex: colorHex))
            .frame(width: 30, height: 30)
            .overlay {
                Circle()
                    .stroke(Color.primary.opacity(0.16), lineWidth: 1)
            }
            .background {
                Circle()
                    .fill(MeowPlannerTheme.color(hex: colorHex).opacity(0.16))
                    .frame(width: 48, height: 48)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .accessibilityLabel(colorHex)
            .contextMenu {
                Button {
                    onEdit()
                } label: {
                    Label(PlannerCopy.text(.editColor, language: appLanguage), systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(PlannerCopy.text(.deleteColor, language: appLanguage), systemImage: "trash")
                }
                .disabled(!canDelete)
            }
    }
}

private struct SettingsEventColorEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var customColor: Color
    @State private var colorHexInput: String

    var originalColorHex: String?
    var onSave: (String, String?) -> Void

    init(initialColorHex: String, originalColorHex: String?, onSave: @escaping (String, String?) -> Void) {
        let normalized = MeowPlannerTheme.normalizedHex(initialColorHex) ?? PlannerPreference.defaultEventColorHexes[0]
        _customColor = State(initialValue: MeowPlannerTheme.color(hex: normalized))
        _colorHexInput = State(initialValue: normalized)
        self.originalColorHex = originalColorHex
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                ColorPicker(PlannerCopy.text(.newColor, language: appLanguage), selection: $customColor, supportsOpacity: false)

                HStack {
                    Text("HEX")
                        .foregroundStyle(.secondary)
                    TextField("#F57C6E", text: $colorHexInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(syncColorFromHexInput)
                    Circle()
                        .fill(MeowPlannerTheme.color(hex: normalizedColorHex ?? PlannerPreference.defaultEventColorHexes[0]))
                        .frame(width: 24, height: 24)
                        .overlay {
                            Circle()
                                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
                        }
                }

                if normalizedColorHex == nil {
                    Text("Use HEX format like #F57C6E")
                        .font(.caption)
                        .foregroundStyle(MeowPlannerTheme.blush)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(MeowPlannerTheme.plannerGradient)
            .onChange(of: customColor) { _, _ in
                syncColorFromPicker()
            }
            .navigationTitle(editorTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(PlannerCopy.text(.save, language: appLanguage)) {
                        if let normalizedColorHex {
                            onSave(normalizedColorHex, originalColorHex)
                            dismiss()
                        }
                    }
                    .disabled(normalizedColorHex == nil)
                }
            }
            .padding()
        }
        .frame(minWidth: 360, minHeight: 220)
    }

    private var normalizedColorHex: String? {
        MeowPlannerTheme.normalizedHex(colorHexInput)
    }

    private var editorTitle: String {
        originalColorHex == nil
            ? PlannerCopy.text(.addColor, language: appLanguage)
            : PlannerCopy.text(.editColor, language: appLanguage)
    }

    private func syncColorFromPicker() {
        guard let selectedHex = MeowPlannerTheme.hex(color: customColor) else {
            return
        }
        colorHexInput = selectedHex
    }

    private func syncColorFromHexInput() {
        guard let normalized = MeowPlannerTheme.normalizedHex(colorHexInput) else {
            return
        }
        colorHexInput = normalized
        customColor = MeowPlannerTheme.color(hex: normalized)
    }
}
