import Combine
import MeowPlannerCore
#if os(macOS)
import AppKit
#endif
import SwiftData
import SwiftUI

@MainActor
final class FocusTimerStore: ObservableObject {
    @Published private(set) var timer = FocusTimerState(durationSeconds: PlannerPreference.defaults.defaultFocusMinutes * 60)
    @Published var focusTitle = ""
    @Published var focusMode: FocusMode = .countdown
    @Published var focusTagID: UUID?
    @Published private(set) var now = Date()

    private var tickerTask: Task<Void, Never>?

    var hasActiveSession: Bool {
        timer.startedAt != nil
    }

    var isRunning: Bool {
        timer.isRunning
    }

    var startedAt: Date? {
        timer.startedAt
    }

    var durationSeconds: Int {
        timer.durationSeconds
    }

    var formattedRemainingTime: String {
        switch focusMode {
        case .countdown:
            Self.timeString(timer.remainingSeconds(at: now))
        case .stopwatch:
            Self.timeString(timer.elapsedSeconds(at: now))
        }
    }

    func start(defaultDurationSeconds: Int, at date: Date = Date()) {
        syncDuration(defaultDurationSeconds)
        now = date
        timer.start(at: date)
        startTicker()
    }

    func pause(at date: Date = Date()) {
        now = date
        timer.pause(at: date)
        stopTicker()
    }

    func resume(at date: Date = Date()) {
        now = date
        timer.resume(at: date)
        startTicker()
    }

    func reset(defaultDurationSeconds: Int) {
        stopTicker()
        focusTitle = ""
        now = Date()
        timer = FocusTimerState(durationSeconds: defaultDurationSeconds)
    }

    func syncDuration(_ defaultDurationSeconds: Int) {
        guard timer.startedAt == nil, timer.durationSeconds != defaultDurationSeconds else {
            return
        }

        timer = FocusTimerState(durationSeconds: defaultDurationSeconds)
    }

    func completedSeconds(at date: Date = Date()) -> Int {
        timer.elapsedSeconds(at: date)
    }

    static func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func startTicker() {
        guard tickerTask == nil else {
            return
        }

        tickerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.now = Date()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func stopTicker() {
        tickerTask?.cancel()
        tickerTask = nil
    }
}

private enum FocusSection: String, CaseIterable, Identifiable {
    case timer
    case timeline
    case insights

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .timer:
            PlannerCopy.text(.focusTimer, language: language)
        case .timeline:
            PlannerCopy.text(.focusTimeline, language: language)
        case .insights:
            PlannerCopy.text(.focusInsights, language: language)
        }
    }
}

private enum FocusInsightRange: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch (self, language) {
        case (.day, .english): "Day"
        case (.day, .chinese): "日"
        case (.week, .english): "Week"
        case (.week, .chinese): "周"
        case (.month, .english): "Month"
        case (.month, .chinese): "月"
        case (.year, .english): "Year"
        case (.year, .chinese): "年"
        }
    }
}

struct FocusView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var focusTimerStore: FocusTimerStore
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]
    @Query(sort: \FocusTag.sortOrder) private var focusTags: [FocusTag]
    @Query private var preferences: [PlannerPreference]

    @State private var editingSession: FocusSession?
    @State private var selectedSection: FocusSection = .timer
    @State private var selectedTimelineDate = Date()
    @State private var selectedInsightDate = Date()
    @State private var selectedInsightRange: FocusInsightRange = .day
    @State private var showingFocusTagEditor = false
    @State private var editingFocusTag: FocusTag?
    @State private var customFocusMinutes = PlannerPreference.defaults.defaultFocusMinutes
    @State private var isEditingFocusDuration = false
    @State private var draftFocusMinutes = ""
    @State private var durationDragOffset: CGFloat = 0
    @State private var isAdjustingFocusDuration = false
    @FocusState private var isFocusDurationFieldFocused: Bool

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: focusPageContentSpacing) {
                focusHeader
                focusSectionPicker

                switch selectedSection {
                case .timer:
                    focusTimerContent
                case .timeline:
                    focusTimelineView
                case .insights:
                    focusInsightsView
                }
            }
            .padding(.horizontal, focusPageHorizontalPadding)
            .padding(.top, focusPageTopPadding)
            .padding(.bottom, focusPageBottomPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .verticalPageScrollOnly()
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            focusPageBackground
        }
        .onAppear {
            syncCustomDurationWithPreference()
            syncTimerDurationWithPreference()
        }
        .onChange(of: defaultFocusMinutes) { _, _ in
            syncCustomDurationWithPreference()
            syncTimerDurationWithPreference()
        }
        .onChange(of: customFocusMinutes) { _, _ in
            syncTimerDurationWithPreference()
        }
        .sheet(item: $editingSession) { editingSession in
            FocusSessionEditorView(session: editingSession, tags: focusTags)
        }
        .sheet(isPresented: $showingFocusTagEditor, onDismiss: { editingFocusTag = nil }) {
            FocusTagEditorView(tag: editingFocusTag, nextSortOrder: focusTags.count)
        }
    }

    private var focusPageContentSpacing: CGFloat {
        #if os(iOS)
        return 14
        #else
        return 18
        #endif
    }

    private var focusPageHorizontalPadding: CGFloat {
        #if os(iOS)
        return 16
        #else
        return 16
        #endif
    }

    private var focusPageTopPadding: CGFloat {
        #if os(iOS)
        return 24
        #else
        return 24
        #endif
    }

    private var focusPageBottomPadding: CGFloat {
        #if os(iOS)
        return IOSAppNavigationMetrics.bottomNavigationContentHeight
            + IOSAppNavigationMetrics.bottomNavigationTopPadding
            + IOSAppNavigationMetrics.bottomNavigationRaisedPadding
            + 16
        #else
        return 16
        #endif
    }

    @ViewBuilder
    private var focusPageBackground: some View {
        ZStack {
            #if os(iOS)
            Color.clear
            #else
            MeowPlannerTheme.plannerGradient
            #endif
            focusDurationOutsideCommitLayer
        }
    }

    private var focusTimerPanelBackgroundOpacity: Double {
        #if os(iOS)
        return 0.18
        #else
        return 0.42
        #endif
    }

    private var focusHeaderAvatarSize: CGFloat {
        #if os(iOS)
        return 58
        #else
        return 72
        #endif
    }

    private var focusHeaderTitleFont: Font {
        #if os(iOS)
        return .title3.bold()
        #else
        return .title2.bold()
        #endif
    }

    private var focusHeaderSubtitleFont: Font {
        #if os(iOS)
        return .footnote
        #else
        return .subheadline
        #endif
    }

    private var focusTimerPanelSpacing: CGFloat {
        #if os(iOS)
        return 12
        #else
        return 18
        #endif
    }

    private var focusTimerPanelPadding: CGFloat {
        #if os(iOS)
        return 18
        #else
        return 26
        #endif
    }

    private var focusTimerCircleSize: CGFloat {
        #if os(iOS)
        return 212
        #else
        return 240
        #endif
    }

    private var focusTimerCircleLineWidth: CGFloat {
        #if os(iOS)
        return 11
        #else
        return 14
        #endif
    }

    private var focusTimerDisplayFontSize: CGFloat {
        #if os(iOS)
        return 46
        #else
        return 54
        #endif
    }

    private var focusDurationFaceWidth: CGFloat {
        #if os(iOS)
        return 170
        #else
        return 190
        #endif
    }

    private var focusDurationFaceHeight: CGFloat {
        #if os(iOS)
        return 86
        #else
        return 96
        #endif
    }

    private var focusDurationTextHeight: CGFloat {
        #if os(iOS)
        return 64
        #else
        return 72
        #endif
    }

    private var focusDurationEditingMinuteWidth: CGFloat {
        #if os(iOS)
        return 82
        #else
        return 92
        #endif
    }

    private var focusDurationEditingSuffixWidth: CGFloat {
        #if os(iOS)
        return 88
        #else
        return 98
        #endif
    }

    private var focusControlButtonSpacing: CGFloat {
        #if os(iOS)
        return 24
        #else
        return 28
        #endif
    }

    private var focusControlButtonSize: CGFloat {
        #if os(iOS)
        return 64
        #else
        return 74
        #endif
    }

    private var focusPrimaryControlIconSize: CGFloat {
        #if os(iOS)
        return 24
        #else
        return 28
        #endif
    }

    private var focusSecondaryControlIconSize: CGFloat {
        #if os(iOS)
        return 22
        #else
        return 25
        #endif
    }

    private var focusRecentSessionsTitleFont: Font {
        #if os(iOS)
        return .subheadline.bold()
        #else
        return .headline
        #endif
    }

    private var focusRecentEmptyTitleFont: Font {
        #if os(iOS)
        return .footnote.weight(.semibold)
        #else
        return .headline
        #endif
    }

    private var focusRecentEmptyMessageFont: Font {
        #if os(iOS)
        return .caption2
        #else
        return .subheadline
        #endif
    }

    private var focusHeader: some View {
        HStack(spacing: 14) {
            FuFuAssetImage(size: focusHeaderAvatarSize)

            VStack(alignment: .leading, spacing: 4) {
                Text(PlannerCopy.text(.focusWithFuFu, language: appLanguage))
                    .font(focusHeaderTitleFont)
                Text(focusSubtitle)
                    .font(focusHeaderSubtitleFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var focusSectionPicker: some View {
        Picker("", selection: $selectedSection) {
            ForEach(FocusSection.allCases) { section in
                Text(section.title(language: appLanguage)).tag(section)
            }
        }
        .fufuSegmentedPickerStyle()
        .frame(maxWidth: 420)
    }

    private var focusTimerContent: some View {
        VStack(alignment: .leading, spacing: focusTimerPanelSpacing) {
            focusTimerPanel
            recentSessions.simultaneousGesture(focusDurationOutsideTapGesture)
        }
    }

    private var defaultFocusMinutes: Int {
        max(1, preferences.first?.defaultFocusMinutes ?? PlannerPreference.defaults.defaultFocusMinutes)
    }

    private var defaultFocusSeconds: Int {
        defaultFocusMinutes * 60
    }

    private var customFocusSeconds: Int {
        max(1, customFocusMinutes) * 60
    }

    private var focusProgress: Double {
        guard focusTimerStore.durationSeconds > 0 else {
            return 0
        }

        switch focusTimerStore.focusMode {
        case .countdown:
            let remainingSeconds = focusTimerStore.timer.remainingSeconds(at: focusTimerStore.now)
            return min(1, max(0, 1 - Double(remainingSeconds) / Double(focusTimerStore.durationSeconds)))
        case .stopwatch:
            let elapsedSeconds = focusTimerStore.timer.elapsedSeconds(at: focusTimerStore.now)
            return min(1, max(0, Double(elapsedSeconds) / Double(focusTimerStore.durationSeconds)))
        }
    }

    private var focusSubtitle: String {
        switch appLanguage {
        case .english:
            "A quiet timer for one task at a time."
        case .chinese:
            "一次只做一件事的安静计时器"
        }
    }

    private var focusTimerPanel: some View {
        VStack(spacing: focusTimerPanelSpacing) {
            focusTitleField.simultaneousGesture(focusDurationOutsideTapGesture)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    focusModePicker
                    focusTagPicker
                }

                VStack(spacing: 10) {
                    focusModePicker
                    focusTagPicker
                }
            }

            focusCircularTimer

            focusControlButtons.simultaneousGesture(focusDurationOutsideTapGesture)
        }
        .frame(maxWidth: .infinity)
        .padding(focusTimerPanelPadding)
        .background(
            ZStack {
                MeowPlannerTheme.monthGridHeaderBackground.opacity(focusTimerPanelBackgroundOpacity)
                focusTimerPanelOutsideCommitLayer
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 150, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.fufuPawTint.opacity(0.07))
                    .offset(x: 410, y: 76)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MeowPlannerTheme.warmCream.opacity(0.35), lineWidth: 1)
        )
    }

    private var focusTimerPanelOutsideCommitLayer: some View {
        focusDurationOutsideCommitLayer
    }

    private var focusDurationOutsideCommitLayer: some View {
        Group {
            if isEditingFocusDuration {
                Color.clear.contentShape(Rectangle())
                    .onTapGesture {
                        commitFocusDurationEdit()
                    }
                    .zIndex(1)
            }
        }
    }

    private var focusDurationOutsideTapGesture: some Gesture {
        TapGesture().onEnded {
            commitFocusDurationEditIfNeeded()
        }
    }

    private var focusTitleField: some View {
        TextField(PlannerCopy.text(.focusTitle, language: appLanguage), text: $focusTimerStore.focusTitle)
            .textFieldStyle(.plain)
            .font(.body.weight(.medium))
            .foregroundStyle(MeowPlannerTheme.cocoa)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 360)
            .background(MeowPlannerTheme.warmCream.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(MeowPlannerTheme.cocoa.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: MeowPlannerTheme.cocoa.opacity(0.05), radius: 8, y: 4)
    }

    private var focusModePicker: some View {
        Picker("", selection: $focusTimerStore.focusMode) {
            Text(PlannerCopy.text(.focusModeCountdown, language: appLanguage)).tag(FocusMode.countdown)
            Text(PlannerCopy.text(.focusModeStopwatch, language: appLanguage)).tag(FocusMode.stopwatch)
        }
        .fufuSegmentedPickerStyle()
        .frame(width: 210)
        .disabled(focusTimerStore.hasActiveSession)
    }

    private var focusTagPicker: some View {
        Menu {
            Button {
                focusTimerStore.focusTagID = nil
            } label: {
                Label(PlannerCopy.text(.uncategorizedFocus, language: appLanguage), systemImage: focusTimerStore.focusTagID == nil ? "checkmark" : "tag")
            }

            ForEach(focusTags) { tag in
                Button {
                    focusTimerStore.focusTagID = tag.id
                } label: {
                    Label(tag.name, systemImage: focusTimerStore.focusTagID == tag.id ? "checkmark" : "tag.fill")
                }
            }

            Divider()

            Button {
                editingFocusTag = nil
                showingFocusTagEditor = true
            } label: {
                Label(PlannerCopy.text(.newFocusTag, language: appLanguage), systemImage: "tag.badge.plus")
            }

            if let selectedTag {
                Button {
                    editingFocusTag = selectedTag
                    showingFocusTagEditor = true
                } label: {
                    Label(PlannerCopy.text(.editFocusTag, language: appLanguage), systemImage: "pencil")
                }
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(MeowPlannerTheme.color(hex: selectedFocusTagColorHex))
                    .frame(width: 10, height: 10)
                Text(selectedFocusTagName)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(MeowPlannerTheme.cocoa)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(MeowPlannerTheme.cream.opacity(0.76), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(MeowPlannerTheme.color(hex: selectedFocusTagColorHex).opacity(0.35), lineWidth: 1)
            }
        }
        .menuStyle(.button)
        .disabled(focusTimerStore.hasActiveSession)
    }

    private var focusCircularTimer: some View {
        ZStack {
            Circle()
                .stroke(MeowPlannerTheme.warmCream.opacity(0.38), lineWidth: focusTimerCircleLineWidth)

            Circle().trim(from: 0, to: focusProgress)
                .stroke(
                    MeowPlannerTheme.blush,
                    style: StrokeStyle(lineWidth: focusTimerCircleLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 8) {
                focusDurationFace

                Text(trimmedFocusTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 180)
            }
        }
        .frame(width: focusTimerCircleSize, height: focusTimerCircleSize)
    }

    private var focusDurationFace: some View {
        ZStack {
            durationAdjustmentPreview

            if isEditingFocusDuration && !focusTimerStore.hasActiveSession {
                focusDurationEditingFace
            } else {
                Text(displayedFocusTime)
                    .font(.system(size: focusTimerDisplayFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                    .frame(width: focusDurationFaceWidth, height: focusDurationTextHeight)
                    .offset(y: durationDragOffset)
                    .contentShape(Rectangle())
                    .animation(.spring(response: 0.22, dampingFraction: 0.76), value: durationDragOffset)
            }

            FocusDurationScrollView(
                onEditRequested: {
                    beginEditingFocusDuration()
                },
                onAdjustment: { delta, dragOffset in
                    adjustCustomFocusMinutes(by: -delta)
                    durationDragOffset = -dragOffset
                },
                onInteractionChanged: { isInteracting in
                    isAdjustingFocusDuration = isInteracting
                    if !isInteracting {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                            durationDragOffset = 0
                        }
                    }
                }
            )
            .disabled(focusTimerStore.hasActiveSession)
            .allowsHitTesting(!isEditingFocusDuration && !focusTimerStore.hasActiveSession)
        }
        .frame(width: focusDurationFaceWidth, height: focusDurationFaceHeight)
    }

    private var focusDurationEditingFace: some View {
        HStack(spacing: 0) {
            TextField("", text: $draftFocusMinutes)
                .textFieldStyle(.plain)
                .font(.system(size: focusTimerDisplayFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .foregroundStyle(MeowPlannerTheme.cocoa)
                .frame(width: focusDurationEditingMinuteWidth, alignment: .trailing)
                .focused($isFocusDurationFieldFocused)
                .onSubmit {
                    commitFocusDurationEdit()
                }
                .onChange(of: draftFocusMinutes) { _, _ in
                    draftFocusMinutes = draftFocusMinutes.filter(\.isNumber)
                }
                .onChange(of: isFocusDurationFieldFocused) { _, isFocused in
                    if !isFocused {
                        commitFocusDurationEdit()
                    }
                }

            Text(":00")
                .font(.system(size: focusTimerDisplayFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(MeowPlannerTheme.cocoa)
                .frame(width: focusDurationEditingSuffixWidth, alignment: .leading)
        }
        .frame(width: focusDurationFaceWidth, height: focusDurationTextHeight)
    }

    private var durationAdjustmentPreview: some View {
        VStack(spacing: 56) {
            Text(durationPreviewMinuteText(for: customFocusMinutes - 1))
                .offset(y: durationDragOffset - 12)

            Text(durationPreviewMinuteText(for: customFocusMinutes + 1))
                .offset(y: durationDragOffset + 12)
        }
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .monospacedDigit()
        .frame(width: 82, alignment: .trailing)
        .offset(x: -44)
        .foregroundStyle(MeowPlannerTheme.cocoa.opacity(0.22))
        .opacity(isAdjustingFocusDuration && !focusTimerStore.hasActiveSession ? 1 : 0)
        .animation(.easeOut(duration: 0.12), value: isAdjustingFocusDuration)
        .allowsHitTesting(false)
    }

    private var focusControlButtons: some View {
        HStack(spacing: focusControlButtonSpacing) {
            Button {
                pauseOrStartFocus()
            } label: {
                Image(systemName: focusTimerStore.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: focusPrimaryControlIconSize, weight: .bold))
                    .frame(width: focusControlButtonSize, height: focusControlButtonSize)
                    .foregroundStyle(MeowPlannerTheme.warmCream)
                    .background(MeowPlannerTheme.cocoa, in: Circle())
            }
            .buttonStyle(.plain)
            .help(focusTimerStore.isRunning ? PlannerCopy.text(.pause, language: appLanguage) : PlannerCopy.text(.start, language: appLanguage))

            Button {
                finish()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: focusSecondaryControlIconSize, weight: .bold))
                    .frame(width: focusControlButtonSize, height: focusControlButtonSize)
                    .foregroundStyle(MeowPlannerTheme.warmCream)
                    .background(MeowPlannerTheme.cocoa, in: Circle())
                    .opacity(focusTimerStore.hasActiveSession ? 1 : 0.35)
            }
            .buttonStyle(.plain)
            .disabled(!focusTimerStore.hasActiveSession)
            .help(PlannerCopy.text(.finish, language: appLanguage))
        }
    }

    private var displayedFocusTime: String {
        if focusTimerStore.hasActiveSession {
            return focusTimerStore.formattedRemainingTime
        }

        switch focusTimerStore.focusMode {
        case .countdown:
            return FocusTimerStore.timeString(customFocusSeconds)
        case .stopwatch:
            return FocusTimerStore.timeString(0)
        }
    }

    private var selectedTag: FocusTag? {
        guard let tagID = focusTimerStore.focusTagID else {
            return nil
        }
        return focusTags.first { $0.id == tagID }
    }

    private var selectedFocusTagName: String {
        selectedTag?.name ?? PlannerCopy.text(.uncategorizedFocus, language: appLanguage)
    }

    private var selectedFocusTagColorHex: String {
        selectedTag?.colorHex ?? PlannerPreference.defaultEventColorHexes[1]
    }

    private func focusTagName(for session: FocusSession) -> String {
        guard let tagID = session.tagID,
              let tag = focusTags.first(where: { $0.id == tagID }) else {
            return PlannerCopy.text(.uncategorizedFocus, language: appLanguage)
        }
        return tag.name
    }

    private func focusTagColorHex(for session: FocusSession) -> String {
        guard let tagID = session.tagID,
              let tag = focusTags.first(where: { $0.id == tagID }) else {
            return PlannerPreference.defaultEventColorHexes[1]
        }
        return tag.colorHex
    }

    private func durationPreviewMinuteText(for minutes: Int) -> String {
        "\(clampedFocusMinutes(minutes))"
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(PlannerCopy.text(.recentFocus, language: appLanguage))
                .font(focusRecentSessionsTitleFont)

            if sessions.isEmpty {
                focusRecentSessionsEmptyState
            } else {
                ForEach(sessions.prefix(6)) { session in
                    HStack(spacing: 12) {
                        Button {
                            editingSession = session
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "timer")
                                    .foregroundStyle(MeowPlannerTheme.fufuBlue)
                                VStack(alignment: .leading) {
                                    Text(session.title)
                                        .font(.body.weight(.semibold))
                                    Text("\(PlannerCopy.minutes(session.completedDurationSeconds / 60, language: appLanguage)) · \(session.startedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(focusTagName(for: session))
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(MeowPlannerTheme.cocoa)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(MeowPlannerTheme.color(hex: focusTagColorHex(for: session)).opacity(0.16), in: Capsule())
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            editingSession = session
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)

                        Button(role: .destructive) {
                            deleteFocusSession(session)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    @ViewBuilder
    private var focusRecentSessionsEmptyState: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 3) {
            Text(PlannerCopy.text(.noFocusSessions, language: appLanguage))
                .font(focusRecentEmptyTitleFont)
                .foregroundStyle(MeowPlannerTheme.cocoa)
            Text(PlannerCopy.text(.noFocusSessionsMessage, language: appLanguage))
                .font(focusRecentEmptyMessageFont)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        #else
        FuFuEmptyStateView(
            title: PlannerCopy.text(.noFocusSessions, language: appLanguage),
            message: PlannerCopy.text(.noFocusSessionsMessage, language: appLanguage)
        )
        .frame(maxWidth: .infinity)
        #endif
    }

    private var focusTimelineView: some View {
        VStack(alignment: .leading, spacing: 14) {
            dateNavigator(
                title: selectedTimelineDate.formatted(date: .abbreviated, time: .omitted),
                subtitle: selectedTimelineDate.formatted(.dateTime.weekday(.wide)),
                previous: { moveTimelineDate(by: -1) },
                next: { moveTimelineDate(by: 1) }
            )

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    let entries = FocusAnalytics.timelineEntries(
                        for: selectedTimelineDate,
                        sessions: sessions,
                        calendar: calendar
                    )
                    if entries.isEmpty {
                        FuFuEmptyStateView(
                            title: PlannerCopy.text(.noFocusSessions, language: appLanguage),
                            message: PlannerCopy.text(.noFocusSessionsMessage, language: appLanguage),
                            actionTitle: PlannerCopy.text(.addFocusRecord, language: appLanguage),
                            action: addManualFocusRecord
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(entries) { entry in
                            if entry.kind == .gap, let gapSeconds = entry.gapSeconds {
                                focusGapRow(seconds: gapSeconds)
                            } else if let session = entry.session {
                                focusTimelineSessionRow(session)
                            }
                        }
                    }
                }
                .padding(.bottom, 28)
            }
            .verticalPageScrollOnly()
        }
    }

    private var focusInsightsView: some View {
        let summary = FocusAnalytics.summary(
            sessions: sessions,
            tags: focusTags,
            range: currentInsightRange,
            calendar: calendar,
            uncategorizedName: PlannerCopy.text(.uncategorizedFocus, language: appLanguage)
        )

        return ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                Picker("", selection: $selectedInsightRange) {
                    ForEach(FocusInsightRange.allCases) { range in
                        Text(range.title(language: appLanguage)).tag(range)
                    }
                }
                .fufuSegmentedPickerStyle()
                .frame(maxWidth: 420)

                dateNavigator(
                    title: insightRangeTitle,
                    subtitle: selectedInsightRange.title(language: appLanguage),
                    previous: { moveInsightDate(by: -1) },
                    next: { moveInsightDate(by: 1) }
                )

                focusSummaryCard(summary)
                focusHourDistributionChart(summary)
                focusTagShareChart(summary)
            }
            .padding(.bottom, 28)
        }
        .verticalPageScrollOnly()
    }

    private func dateNavigator(
        title: String,
        subtitle: String,
        previous: @escaping () -> Void,
        next: @escaping () -> Void
    ) -> some View {
        HStack {
            Button(action: previous) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(MeowPlannerTheme.cocoa)
            }

            Spacer()

            Button(action: next) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MeowPlannerTheme.monthGridHeaderBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private func focusTimelineSessionRow(_ session: FocusSession) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(MeowPlannerTheme.color(hex: focusTagColorHex(for: session)))
                .frame(width: 42)

            VStack(alignment: .leading, spacing: 5) {
                Text(session.title)
                    .font(.headline)
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Text("\(formatDuration(session.completedDurationSeconds))  \(session.startedAt.formatted(date: .omitted, time: .shortened))-\((session.endedAt ?? session.startedAt).formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(focusTagName(for: session))
                    .font(.caption2.bold())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(MeowPlannerTheme.color(hex: focusTagColorHex(for: session)).opacity(0.16), in: Capsule())
            }

            Spacer()

            Button {
                editingSession = session
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)

            Button(role: .destructive) {
                deleteFocusSession(session)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .frame(minHeight: 78)
        .background(MeowPlannerTheme.monthGridHeaderBackground.opacity(0.36), in: RoundedRectangle(cornerRadius: 8))
    }

    private func focusGapRow(seconds: Int) -> some View {
        HStack {
            Rectangle()
                .fill(MeowPlannerTheme.cocoa.opacity(0.13))
                .frame(height: 1)
            Text("\(PlannerCopy.text(.gapTime, language: appLanguage)) \(formatDuration(seconds))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(MeowPlannerTheme.cocoa.opacity(0.13))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    private func focusSummaryCard(_ summary: FocusAnalytics.Summary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(PlannerCopy.text(.totalFocusTime, language: appLanguage))
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(formatDuration(summary.totalSeconds))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(MeowPlannerTheme.cocoa)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                focusMetric(PlannerCopy.text(.focusCount, language: appLanguage), "\(summary.sessionCount)")
                focusMetric(PlannerCopy.text(.averageFocus, language: appLanguage), formatDuration(summary.averageSeconds))
                focusMetric(PlannerCopy.text(.activeDays, language: appLanguage), "\(summary.activeDayCount)")
                focusMetric(PlannerCopy.text(.longestFocus, language: appLanguage), formatDuration(summary.longestSeconds))
            }
        }
        .padding(24)
        .background(MeowPlannerTheme.monthGridHeaderBackground.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
    }

    private func focusMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(MeowPlannerTheme.cocoa)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func focusHourDistributionChart(_ summary: FocusAnalytics.Summary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(PlannerCopy.text(.focusDistribution, language: appLanguage))
                .font(.headline)
                .foregroundStyle(MeowPlannerTheme.cocoa)

            HStack(alignment: .bottom, spacing: 5) {
                ForEach(summary.hourDistribution) { bucket in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(bucket.totalSeconds == 0 ? MeowPlannerTheme.cocoa.opacity(0.08) : MeowPlannerTheme.fufuBlue)
                        .frame(height: max(8, CGFloat(bucket.totalSeconds) / CGFloat(max(1, summary.longestSeconds)) * 110))
                }
            }
            .frame(height: 126, alignment: .bottom)

            HStack {
                Text("00:00")
                Spacer()
                Text("12:00")
                Spacer()
                Text("24:00")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(MeowPlannerTheme.monthGridHeaderBackground.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
    }

    private func focusTagShareChart(_ summary: FocusAnalytics.Summary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(PlannerCopy.text(.focusTimeShare, language: appLanguage))
                .font(.headline)
                .foregroundStyle(MeowPlannerTheme.cocoa)

            if summary.tagBreakdown.isEmpty {
                Text(PlannerCopy.text(.noFocusSessions, language: appLanguage))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(summary.tagBreakdown) { item in
                    HStack {
                        Circle()
                            .fill(MeowPlannerTheme.color(hex: item.colorHex))
                            .frame(width: 12, height: 12)
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(formatDuration(item.totalSeconds))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(MeowPlannerTheme.monthGridHeaderBackground.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
    }

    private func finish() {
        guard let startedAt = focusTimerStore.startedAt else {
            return
        }

        let finishedAt = Date()
        if focusTimerStore.isRunning {
            focusTimerStore.pause(at: finishedAt)
        }

        let session = FocusSession(
            title: trimmedFocusTitle,
            startedAt: startedAt,
            endedAt: finishedAt,
            plannedDurationSeconds: focusTimerStore.focusMode == .countdown ? focusTimerStore.durationSeconds : 0,
            completedDurationSeconds: focusTimerStore.completedSeconds(at: finishedAt),
            tagID: focusTimerStore.focusTagID,
            mode: focusTimerStore.focusMode
        )
        modelContext.insert(session)
        focusTimerStore.reset(defaultDurationSeconds: customFocusSeconds)
    }

    private func deleteFocusSession(_ session: FocusSession) {
        if editingSession?.id == session.id {
            editingSession = nil
        }
        modelContext.delete(session)
    }

    private var calendar: Calendar {
        Calendar.current
    }

    private var currentInsightRange: FocusAnalytics.Range {
        switch selectedInsightRange {
        case .day:
            .day(containing: selectedInsightDate, calendar: calendar)
        case .week:
            .week(containing: selectedInsightDate, calendar: calendar)
        case .month:
            .month(containing: selectedInsightDate, calendar: calendar)
        case .year:
            .year(containing: selectedInsightDate, calendar: calendar)
        }
    }

    private var insightRangeTitle: String {
        let interval = currentInsightRange.interval
        switch selectedInsightRange {
        case .day:
            return selectedInsightDate.formatted(date: .abbreviated, time: .omitted)
        case .week:
            let endDate = interval.end.addingTimeInterval(-1)
            return "\(interval.start.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))"
        case .month:
            return selectedInsightDate.formatted(.dateTime.year().month(.wide))
        case .year:
            return selectedInsightDate.formatted(.dateTime.year())
        }
    }

    private func moveTimelineDate(by value: Int) {
        selectedTimelineDate = calendar.date(byAdding: .day, value: value, to: selectedTimelineDate) ?? selectedTimelineDate
    }

    private func moveInsightDate(by value: Int) {
        let component: Calendar.Component = switch selectedInsightRange {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
        selectedInsightDate = calendar.date(byAdding: component, value: value, to: selectedInsightDate) ?? selectedInsightDate
    }

    private func addManualFocusRecord() {
        let endedAt = Date()
        let startedAt = endedAt.addingTimeInterval(-TimeInterval(customFocusSeconds))
        let session = FocusSession(
            title: trimmedFocusTitle,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedDurationSeconds: focusTimerStore.focusMode == .countdown ? customFocusSeconds : 0,
            completedDurationSeconds: customFocusSeconds,
            tagID: focusTimerStore.focusTagID,
            mode: focusTimerStore.focusMode
        )
        modelContext.insert(session)
        editingSession = session
    }

    private func formatDuration(_ seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        let hours = safeSeconds / 3_600
        let minutes = (safeSeconds % 3_600) / 60
        let remainingSeconds = safeSeconds % 60

        switch appLanguage {
        case .english:
            if hours > 0 {
                return remainingSeconds > 0 ? "\(hours)h \(minutes)m \(remainingSeconds)s" : "\(hours)h \(minutes)m"
            }
            return remainingSeconds > 0 ? "\(minutes)m \(remainingSeconds)s" : "\(minutes)m"
        case .chinese:
            if hours > 0 {
                return remainingSeconds > 0 ? "\(hours)小时 \(minutes)分钟 \(remainingSeconds)秒" : "\(hours)小时 \(minutes)分钟"
            }
            return remainingSeconds > 0 ? "\(minutes)分钟 \(remainingSeconds)秒" : "\(minutes)分钟"
        }
    }

    private var trimmedFocusTitle: String {
        let title = focusTimerStore.focusTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? PlannerCopy.text(.defaultFocusBlock, language: appLanguage) : title
    }

    private func beginEditingFocusDuration() {
        guard !focusTimerStore.hasActiveSession else {
            return
        }

        draftFocusMinutes = "\(customFocusMinutes)"
        isEditingFocusDuration = true
        Task { @MainActor in
            isFocusDurationFieldFocused = true
        }
    }

    private func commitFocusDurationEdit() {
        guard isEditingFocusDuration else {
            return
        }

        if let minutes = Int(draftFocusMinutes.trimmingCharacters(in: .whitespacesAndNewlines)) {
            customFocusMinutes = clampedFocusMinutes(minutes)
        }

        isEditingFocusDuration = false
        isFocusDurationFieldFocused = false
    }

    private func commitFocusDurationEditIfNeeded() {
        guard isEditingFocusDuration else {
            return
        }

        commitFocusDurationEdit()
    }

    private func pauseOrStartFocus() {
        if focusTimerStore.hasActiveSession {
            if focusTimerStore.isRunning {
                focusTimerStore.pause()
            } else {
                focusTimerStore.resume()
            }
        } else {
            syncTimerDurationWithPreference()
            focusTimerStore.start(defaultDurationSeconds: customFocusSeconds)
        }
    }

    private func adjustCustomFocusMinutes(by delta: Int) {
        guard !focusTimerStore.hasActiveSession else {
            return
        }

        isEditingFocusDuration = false
        customFocusMinutes = clampedFocusMinutes(customFocusMinutes + delta)
    }

    private func clampedFocusMinutes(_ minutes: Int) -> Int {
        min(240, max(1, minutes))
    }

    private func syncTimerDurationWithPreference() {
        focusTimerStore.syncDuration(customFocusSeconds)
    }

    private func syncCustomDurationWithPreference() {
        guard !focusTimerStore.hasActiveSession else {
            return
        }

        customFocusMinutes = defaultFocusMinutes
    }
}

#if os(macOS)
private struct FocusDurationScrollView: NSViewRepresentable {
    var onEditRequested: () -> Void
    var onAdjustment: (Int, CGFloat) -> Void
    var onInteractionChanged: (Bool) -> Void

    func makeNSView(context: Context) -> ScrollCaptureView {
        let view = ScrollCaptureView()
        view.onEditRequested = onEditRequested
        view.onAdjustment = onAdjustment
        view.onInteractionChanged = onInteractionChanged
        return view
    }

    func updateNSView(_ nsView: ScrollCaptureView, context: Context) {
        nsView.onEditRequested = onEditRequested
        nsView.onAdjustment = onAdjustment
        nsView.onInteractionChanged = onInteractionChanged
    }

    final class ScrollCaptureView: NSView {
        var onEditRequested: () -> Void = {}
        var onAdjustment: (Int, CGFloat) -> Void = { _, _ in }
        var onInteractionChanged: (Bool) -> Void = { _ in }

        private let scrollThreshold: CGFloat = 44
        private let dragThreshold: CGFloat = 20
        private var scrollAccumulator: CGFloat = 0
        private var dragAccumulator: CGFloat = 0
        private var isInteracting = false
        private var didDrag = false

        override var acceptsFirstResponder: Bool {
            true
        }

        override func scrollWheel(with event: NSEvent) {
            beginInteraction()
            scrollAccumulator += event.scrollingDeltaY
            emitSteps(from: &scrollAccumulator, threshold: scrollThreshold)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(endInteraction), object: nil)
            perform(#selector(endInteraction), with: nil, afterDelay: 0.18)
        }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            dragAccumulator = 0
            didDrag = false
            beginInteraction()
        }

        override func mouseDragged(with event: NSEvent) {
            beginInteraction()
            if abs(event.deltaY) > 0.5 {
                didDrag = true
            }
            dragAccumulator += event.deltaY
            emitSteps(from: &dragAccumulator, threshold: dragThreshold)
        }

        override func mouseUp(with event: NSEvent) {
            if !didDrag && event.clickCount >= 2 {
                onEditRequested()
            }
            endInteraction()
        }

        override func mouseExited(with event: NSEvent) {
            endInteraction()
        }

        private func beginInteraction() {
            if !isInteracting {
                isInteracting = true
                onInteractionChanged(true)
            }
        }

        @objc private func endInteraction() {
            guard isInteracting else {
                return
            }

            scrollAccumulator = 0
            dragAccumulator = 0
            isInteracting = false
            onInteractionChanged(false)
        }

        private func emitSteps(from accumulator: inout CGFloat, threshold: CGFloat) {
            guard abs(accumulator) >= threshold else {
                onAdjustment(0, previewOffset(for: accumulator, threshold: threshold))
                return
            }

            let steps = Int(accumulator / threshold)
            accumulator -= CGFloat(steps) * threshold
            onAdjustment(steps, previewOffset(for: accumulator, threshold: threshold))
        }

        private func previewOffset(for accumulator: CGFloat, threshold: CGFloat) -> CGFloat {
            let progress = max(-1, min(1, accumulator / threshold))
            return -progress * 18
        }
    }
}
#else
private struct FocusDurationScrollView: View {
    var onEditRequested: () -> Void
    var onAdjustment: (Int, CGFloat) -> Void
    var onInteractionChanged: (Bool) -> Void

    var body: some View {
        Color.clear
    }
}
#endif

private struct FocusSessionEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    let session: FocusSession
    let tags: [FocusTag]
    @State private var title: String
    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var completedMinutes: Int
    @State private var selectedTagID: UUID?
    @State private var selectedMode: FocusMode

    init(session: FocusSession, tags: [FocusTag] = []) {
        self.session = session
        self.tags = tags
        _title = State(initialValue: session.title)
        _startedAt = State(initialValue: session.startedAt)
        _endedAt = State(initialValue: session.endedAt ?? session.startedAt.addingTimeInterval(TimeInterval(max(60, session.completedDurationSeconds))))
        _completedMinutes = State(initialValue: max(1, session.completedDurationSeconds / 60))
        _selectedTagID = State(initialValue: session.tagID)
        _selectedMode = State(initialValue: session.mode)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(PlannerCopy.text(.title, language: appLanguage), text: $title)

                Picker(PlannerCopy.text(.focusModeCountdown, language: appLanguage), selection: $selectedMode) {
                    Text(PlannerCopy.text(.focusModeCountdown, language: appLanguage)).tag(FocusMode.countdown)
                    Text(PlannerCopy.text(.focusModeStopwatch, language: appLanguage)).tag(FocusMode.stopwatch)
                }
                .fufuSegmentedPickerStyle()

                Picker(PlannerCopy.text(.focusTag, language: appLanguage), selection: $selectedTagID) {
                    Text(PlannerCopy.text(.uncategorizedFocus, language: appLanguage)).tag(UUID?.none)
                    ForEach(tags) { tag in
                        Text(tag.name).tag(Optional(tag.id))
                    }
                }
                .fufuControlTint()

                DatePicker(PlannerCopy.text(.startDate, language: appLanguage), selection: $startedAt)
                    .fufuControlTint()

                DatePicker(PlannerCopy.text(.end, language: appLanguage), selection: $endedAt)
                    .fufuControlTint()

                PlannerNumberInputRow(
                    title: PlannerCopy.text(.completedMinutes, language: appLanguage),
                    value: $completedMinutes,
                    range: 1...720,
                    suffix: PlannerCopy.minutesUnit(language: appLanguage)
                )
            }
            .padding()
            .navigationTitle(PlannerCopy.text(.editFocusSession, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(PlannerCopy.text(.save, language: appLanguage)) {
                        save()
                    }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 320)
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        session.title = trimmedTitle.isEmpty ? PlannerCopy.text(.defaultFocusBlock, language: appLanguage) : trimmedTitle
        session.startedAt = startedAt
        session.endedAt = endedAt
        session.completedDurationSeconds = completedMinutes * 60
        session.plannedDurationSeconds = selectedMode == .countdown ? max(session.plannedDurationSeconds, session.completedDurationSeconds) : 0
        session.tagID = selectedTagID
        session.mode = selectedMode
        dismiss()
    }
}

private struct FocusTagEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [PlannerPreference]

    private var tag: FocusTag?
    private var nextSortOrder: Int
    @State private var name: String
    @State private var colorHex: String
    @State private var showingPaletteColorEditor = false
    @State private var paletteEditorColorHex = PlannerPreference.defaultEventColorHexes[0]
    @State private var paletteEditorOriginalColorHex: String?

    init(tag: FocusTag? = nil, nextSortOrder: Int = 0) {
        let initialColorHex = MeowPlannerTheme.normalizedHex(tag?.colorHex ?? PlannerPreference.defaultEventColorHexes[0]) ?? PlannerPreference.defaultEventColorHexes[0]
        self.tag = tag
        self.nextSortOrder = nextSortOrder
        _name = State(initialValue: tag?.name ?? "")
        _colorHex = State(initialValue: initialColorHex)
        _paletteEditorColorHex = State(initialValue: initialColorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(PlannerCopy.text(.focusTag, language: appLanguage), text: $name)
                paletteColorControls
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background {
                MeowPlannerTheme.plannerGradient
            }
            .sheet(isPresented: $showingPaletteColorEditor) {
                PaletteColorEditorView(
                    initialColorHex: paletteEditorColorHex,
                    originalColorHex: paletteEditorOriginalColorHex,
                    canDelete: paletteEditorOriginalColorHex != nil && eventColorOptions.count > 1,
                    onSave: { newColorHex, originalColorHex in
                        if let originalColorHex {
                            updatePaletteColor(from: originalColorHex, to: newColorHex)
                        } else {
                            addPaletteColor(newColorHex)
                        }
                    },
                    onDelete: { colorHex in
                        deletePaletteColor(colorHex)
                    }
                )
            }
            .navigationTitle(tag == nil ? PlannerCopy.text(.newFocusTag, language: appLanguage) : PlannerCopy.text(.editFocusTag, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(PlannerCopy.text(.save, language: appLanguage)) {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .frame(minWidth: 380, minHeight: 220)
    }

    private var paletteColorControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(PlannerCopy.text(.color, language: appLanguage))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(eventColorOptions, id: \.self) { option in
                    ColorSwatchButton(
                        colorHex: option,
                        isSelected: colorHex == option,
                        canDelete: eventColorOptions.count > 1,
                        onSelect: { applyColorHex(option) },
                        onDelete: { deletePaletteColor(option) }
                    )
                }

                Button {
                    openPaletteColorEditor(nil)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 30, height: 30)
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .background(MeowPlannerTheme.cream.opacity(0.72), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var eventColorOptions: [String] {
        preferences.first?.eventColorHexes ?? PlannerPreference.defaultEventColorHexes
    }

    private var preference: PlannerPreference {
        if let existing = preferences.first {
            return existing
        }

        let created = PlannerPreference.defaults
        modelContext.insert(created)
        return created
    }

    private func applyColorHex(_ value: String) {
        guard let normalized = MeowPlannerTheme.normalizedHex(value) else {
            return
        }
        colorHex = normalized
    }

    private func openPaletteColorEditor(_ colorHex: String?) {
        let editorColorHex = colorHex ?? self.colorHex
        paletteEditorColorHex = MeowPlannerTheme.normalizedHex(editorColorHex) ?? PlannerPreference.defaultEventColorHexes[0]
        paletteEditorOriginalColorHex = colorHex
        showingPaletteColorEditor = true
    }

    private func addPaletteColor(_ value: String) {
        guard let normalized = MeowPlannerTheme.normalizedHex(value) else {
            return
        }
        var colors = eventColorOptions
        if !colors.contains(normalized) {
            colors.append(normalized)
            persistPaletteColors(colors)
        }
        applyColorHex(normalized)
    }

    private func updatePaletteColor(from originalColorHex: String, to newColorHex: String) {
        guard let original = MeowPlannerTheme.normalizedHex(originalColorHex),
              let updated = MeowPlannerTheme.normalizedHex(newColorHex) else {
            return
        }
        var colors = eventColorOptions
        if let index = colors.firstIndex(of: original) {
            colors[index] = updated
        } else {
            colors.append(updated)
        }
        colors = PlannerPreference.normalizedEventColorHexes(colors)
        persistPaletteColors(colors)
        applyColorHex(updated)
    }

    private func deletePaletteColor(_ value: String) {
        guard eventColorOptions.count > 1,
              let normalized = MeowPlannerTheme.normalizedHex(value) else {
            return
        }
        var colors = eventColorOptions
        colors.removeAll { $0 == normalized }
        colors = PlannerPreference.normalizedEventColorHexes(colors)
        persistPaletteColors(colors)
        if colorHex == normalized, let firstColor = colors.first {
            applyColorHex(firstColor)
        }
    }

    private func persistPaletteColors(_ colors: [String]) {
        preference.eventColorHexes = colors
        preference.markUpdated()
        try? modelContext.save()
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let tag {
            tag.name = trimmedName
            tag.colorHex = colorHex
        } else {
            modelContext.insert(FocusTag(name: trimmedName, colorHex: colorHex, sortOrder: nextSortOrder))
        }
        dismiss()
    }
}
