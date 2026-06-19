import MeowPlannerCore
import SwiftUI

#if os(iOS)
enum IOSAppNavigationMetrics {
    static let bottomNavigationContentHeight: CGFloat = 68
    static let bottomNavigationTopPadding: CGFloat = 8
    static let bottomNavigationRaisedPadding: CGFloat = 40
    static let bottomNavigationMinimumBottomPadding: CGFloat = 0

    static func bottomNavigationBottomPadding(for safeAreaInsets: EdgeInsets) -> CGFloat {
        max(safeAreaInsets.bottom, bottomNavigationMinimumBottomPadding)
    }

    static func bottomNavigationChromeHeight(safeAreaInsets: EdgeInsets) -> CGFloat {
        bottomNavigationContentHeight
            + bottomNavigationTopPadding
            + bottomNavigationRaisedPadding
            + bottomNavigationBottomPadding(for: safeAreaInsets)
    }

    static func bottomNavigationReservedHeight(safeAreaInsets: EdgeInsets) -> CGFloat {
        bottomNavigationContentHeight
            + bottomNavigationTopPadding
    }
}

@MainActor
final class IOSCalendarNavigationState: ObservableObject {
    @Published var displayedMonthTitle = ""
    @Published var selectedTagName: String?
    @Published var tagNames: [String] = []
    @Published var isCalendarAgendaOverlayPresented = false

    private var resetToTodayAction: () -> Void = {}
    private var presentMonthPickerAction: () -> Void = {}
    private var selectTagAction: (String?) -> Void = { _ in }

    func configure(
        displayedMonthTitle: String,
        selectedTagName: String?,
        tagNames: [String],
        resetToToday: @escaping () -> Void,
        presentMonthPicker: @escaping () -> Void,
        selectTag: @escaping (String?) -> Void
    ) {
        self.displayedMonthTitle = displayedMonthTitle
        self.selectedTagName = selectedTagName
        self.tagNames = tagNames
        resetToTodayAction = resetToToday
        presentMonthPickerAction = presentMonthPicker
        selectTagAction = selectTag
    }

    func clear() {
        displayedMonthTitle = ""
        selectedTagName = nil
        tagNames = []
        isCalendarAgendaOverlayPresented = false
        resetToTodayAction = {}
        presentMonthPickerAction = {}
        selectTagAction = { _ in }
    }

    func resetToToday() {
        resetToTodayAction()
    }

    func presentMonthPicker() {
        presentMonthPickerAction()
    }

    func selectTag(_ tagName: String?) {
        selectedTagName = tagName
        selectTagAction(tagName)
    }

    func setAgendaOverlayPresented(_ isPresented: Bool) {
        guard isCalendarAgendaOverlayPresented != isPresented else {
            return
        }

        isCalendarAgendaOverlayPresented = isPresented
    }
}

@MainActor
final class IOSTimetableNavigationState: ObservableObject {
    @Published var title = ""
    @Published var subtitle = ""
    @Published var isConfigured = false
    @Published var canEdit = false

    private var presentWeekPickerAction: () -> Void = {}
    private var editTimetableAction: () -> Void = {}

    func configure(
        title: String,
        subtitle: String,
        canEdit: Bool,
        presentWeekPicker: @escaping () -> Void,
        editTimetable: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.canEdit = canEdit
        isConfigured = true
        presentWeekPickerAction = presentWeekPicker
        editTimetableAction = editTimetable
    }

    func clear() {
        title = ""
        subtitle = ""
        isConfigured = false
        canEdit = false
        presentWeekPickerAction = {}
        editTimetableAction = {}
    }

    func presentWeekPicker() {
        presentWeekPickerAction()
    }

    func editTimetable() {
        editTimetableAction()
    }
}

struct IOSNavigationShellView<Content: View>: View {
    @Binding var selection: AppSection
    var allSections: [AppSection]
    var bottomSections: [AppSection]
    var language: AppLanguage
    @ObservedObject var calendarNavigationState: IOSCalendarNavigationState
    @ObservedObject var timetableNavigationState: IOSTimetableNavigationState
    var settingsCanNavigateBack: Bool = false
    var onSelect: (AppSection) -> Void
    var onSettingsBack: () -> Void = {}
    @ViewBuilder var content: () -> Content

    private let sidebarHeaderTopPadding: CGFloat = 16
    private let sidebarHeaderBottomPadding: CGFloat = 8
    private let sidebarListTopPadding: CGFloat = 4
    private let sidebarRowHeight: CGFloat = 44
    private let sidebarRowSpacing: CGFloat = 4

    @State private var isShowingSidebar = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        if shouldShowNavigationBars {
                            topNavigationBar
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if shouldShowNavigationBars && !bottomSections.isEmpty {
                            bottomNavigationReservation(safeAreaInsets: proxy.safeAreaInsets)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if shouldShowNavigationBars && !bottomSections.isEmpty {
                            bottomNavigationBar(safeAreaInsets: proxy.safeAreaInsets)
                                .offset(y: proxy.safeAreaInsets.bottom)
                                .ignoresSafeArea(edges: .bottom)
                        }
                    }

                if isShowingSidebar {
                    sidebarOverlay(panelWidth: sidebarWidth(for: proxy.size.width), safeAreaInsets: proxy.safeAreaInsets)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                        .zIndex(2)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background { iosFullScreenBackground }
            .animation(.snappy(duration: 0.2), value: isShowingSidebar)
            .animation(.easeInOut(duration: 0.18), value: calendarNavigationState.isCalendarAgendaOverlayPresented)
        }
    }

    private var iosFullScreenBackground: some View {
        PlannerIOSImageBackground(gradientOpacity: 0.86)
            .ignoresSafeArea()
    }

    private var shouldShowNavigationBars: Bool {
        !(selection == .calendar && calendarNavigationState.isCalendarAgendaOverlayPresented)
    }

    private var shouldShowSidebarButton: Bool {
        selection != .settings
    }

    private var shouldShowSettingsBackButton: Bool {
        selection == .settings && settingsCanNavigateBack
    }

    private var topNavigationBar: some View {
        HStack(spacing: 12) {
            if shouldShowSettingsBackButton {
                Button {
                    onSettingsBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(MeowPlannerTheme.cocoa)
                        .frame(width: 42, height: 42)
                        .background(MeowPlannerTheme.cream.opacity(0.76), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settingsBackTitle)
            } else if shouldShowSidebarButton {
                Button {
                    isShowingSidebar = true
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 18, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .frame(width: 42, height: 42)
                        .background(MeowPlannerTheme.cream.opacity(0.76), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(sidebarOpenTitle)
            } else {
                Color.clear
                    .frame(width: 42, height: 42)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            if selection == .calendar || selection == .schedule {
                calendarNavigationBarCenter
            } else if selection == .timetable && timetableNavigationState.isConfigured {
                timetableNavigationBarCenter
            } else {
                Text(selection.title(language: language))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)

            if selection == .calendar {
                calendarScheduleDisplayMenu
            } else if selection == .timetable && timetableNavigationState.canEdit {
                timetableEditButton
            } else {
                Color.clear
                    .frame(width: 42, height: 42)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            topNavigationBackground
        }
    }

    private var topNavigationBackground: some View {
        Color.clear
            .ignoresSafeArea(edges: .top)
    }

    private var calendarNavigationBarCenter: some View {
        HStack(spacing: 7) {
            Button {
                calendarNavigationState.resetToToday()
            } label: {
                FuFuAssetImage(size: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(PlannerCopy.text(.today, language: language))

            Button {
                calendarNavigationState.presentMonthPicker()
            } label: {
                HStack(spacing: 5) {
                    Text(calendarNavigationTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MeowPlannerTheme.cocoa)
                        .lineLimit(1)
                        .monospacedDigit()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(calendarNavigationTitle)
        }
        .contentShape(Rectangle())
    }

    private var timetableNavigationBarCenter: some View {
        Button {
            timetableNavigationState.presentWeekPicker()
        } label: {
            HStack(spacing: 8) {
                FuFuAssetImage(size: 30)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(timetableNavigationState.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(MeowPlannerTheme.cocoa)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(MeowPlannerTheme.caramel)
                    }

                    Text(timetableNavigationState.subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .lineLimit(1)
                }
                .layoutPriority(1)
            }
            .frame(maxWidth: 210)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(timetableNavigationState.title)
    }

    private var calendarScheduleDisplayMenu: some View {
        ScheduleDisplayTagFilterMenu(
            selectedTagName: Binding(
                get: { calendarNavigationState.selectedTagName },
                set: { calendarNavigationState.selectTag($0) }
            ),
            tagNames: calendarNavigationState.tagNames
        )
        .labelStyle(.iconOnly)
        .font(.title2.weight(.semibold))
        .buttonStyle(.plain)
        .frame(width: 42, height: 42)
        .background(MeowPlannerTheme.cream.opacity(0.76), in: Circle())
        .accessibilityLabel(PlannerCopy.text(.scheduleDisplay, language: language))
    }

    private var timetableEditButton: some View {
        Button {
            timetableNavigationState.editTimetable()
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 18, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MeowPlannerTheme.caramel)
                .frame(width: 42, height: 42)
                .background(MeowPlannerTheme.cream.opacity(0.76), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language == .chinese ? "编辑课程表" : "Edit timetable")
    }

    private func bottomNavigationReservation(safeAreaInsets: EdgeInsets) -> some View {
        Color.clear
            .frame(height: IOSAppNavigationMetrics.bottomNavigationReservedHeight(safeAreaInsets: safeAreaInsets))
    }

    private func bottomNavigationBar(safeAreaInsets: EdgeInsets) -> some View {
        GeometryReader { proxy in
            let itemWidth = bottomNavigationItemWidth(containerWidth: proxy.size.width)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(bottomSections) { section in
                        bottomNavigationButton(for: section, width: itemWidth)
                    }
                }
                .padding(.horizontal, 12)
                .frame(minWidth: proxy.size.width, alignment: .center)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .frame(height: IOSAppNavigationMetrics.bottomNavigationContentHeight)
        .padding(.top, IOSAppNavigationMetrics.bottomNavigationTopPadding)
        .padding(.bottom, IOSAppNavigationMetrics.bottomNavigationRaisedPadding)
        .frame(height: IOSAppNavigationMetrics.bottomNavigationChromeHeight(safeAreaInsets: safeAreaInsets), alignment: .bottom)
        .background {
            bottomNavigationBackground
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var bottomNavigationBackground: some View {
        Color.clear
    }

    private func bottomNavigationButton(for section: AppSection, width: CGFloat) -> some View {
        let isSelected = selection == section

        return Button {
            select(section)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 24, height: 24)

                Text(section.title(language: language))
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .foregroundStyle(isSelected ? Color.white : MeowPlannerTheme.cocoa)
            .frame(width: width, height: 58)
            .background(
                bottomNavigationButtonBackground(isSelected: isSelected),
                in: Capsule()
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title(language: language))
    }

    private func bottomNavigationButtonBackground(isSelected: Bool) -> some ShapeStyle {
        isSelected
            ? AnyShapeStyle(MeowPlannerTheme.softBrownHighlight)
            : AnyShapeStyle(Color.clear)
    }

    private func sidebarOverlay(panelWidth: CGFloat, safeAreaInsets: EdgeInsets) -> some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture {
                    closeSidebar()
                }

            sidebarPanel(width: panelWidth, safeAreaInsets: safeAreaInsets)
        }
    }

    private func sidebarPanel(width: CGFloat, safeAreaInsets: EdgeInsets) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                FuFuAssetImage(size: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("MeowPlanner")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(MeowPlannerTheme.cocoa)
                        .lineLimit(1)
                    Text(selection.title(language: language))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    closeSidebar()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 18, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .frame(width: 34, height: 34)
                        .background(MeowPlannerTheme.cream.opacity(0.76), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(sidebarCloseTitle)
            }
            .padding(.horizontal, 20)
            .padding(.top, sidebarHeaderTopPadding)
            .padding(.bottom, sidebarHeaderBottomPadding)

            Rectangle()
                .fill(MeowPlannerTheme.caramel.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 20)

            VStack(spacing: sidebarRowSpacing) {
                ForEach(allSections) { section in
                    sidebarRow(for: section)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, sidebarListTopPadding)

            Spacer(minLength: 0)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background {
            MeowPlannerTheme.fufuPlannerBackground
                .overlay {
                    MeowPlannerTheme.plannerGradient.opacity(0.72)
                }
                .overlay {
                    sidebarDecorativeBackground(width: width, safeAreaInsets: safeAreaInsets)
                }
        }
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 18,
            topTrailingRadius: 18
        ))
        .shadow(color: MeowPlannerTheme.coffee.opacity(0.20), radius: 18, x: 8, y: 0)
        .ignoresSafeArea(edges: .bottom)
    }

    private func sidebarDecorativeBackground(width: CGFloat, safeAreaInsets: EdgeInsets) -> some View {
        GeometryReader { proxy in
            ZStack {
                sidebarPawWatermark(
                    proxy: proxy,
                    size: width * 0.52,
                    x: 0.82,
                    y: 0.22,
                    rotation: -12,
                    color: MeowPlannerTheme.fufuPawTint.opacity(0.09)
                )

                sidebarPawWatermark(
                    proxy: proxy,
                    size: width * 0.46,
                    x: 0.18,
                    y: 0.72,
                    rotation: 10,
                    color: MeowPlannerTheme.blush.opacity(0.10)
                )

                sidebarPawWatermark(
                    proxy: proxy,
                    size: width * 0.36,
                    x: 0.84,
                    y: 0.48,
                    rotation: 14,
                    color: MeowPlannerTheme.fufuPawTint.opacity(0.12)
                )

                sidebarPawWatermark(
                    proxy: proxy,
                    size: width * 0.22,
                    x: 0.24,
                    y: 0.40,
                    rotation: -8,
                    color: MeowPlannerTheme.blush.opacity(0.09)
                )

                sidebarStarWatermark(proxy: proxy, size: width * 0.12, x: 0.66, y: 0.64, rotation: -10, color: MeowPlannerTheme.caramel.opacity(0.11))
                sidebarStarWatermark(proxy: proxy, size: width * 0.09, x: 0.36, y: 0.22, rotation: 12, color: MeowPlannerTheme.warmCream.opacity(0.12), systemImage: "star.fill")
                sidebarStarWatermark(proxy: proxy, size: width * 0.08, x: 0.90, y: 0.82, rotation: 18, color: MeowPlannerTheme.blush.opacity(0.10), systemImage: "star.fill")
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func sidebarPawWatermark(
        proxy: GeometryProxy,
        size: CGFloat,
        x: CGFloat,
        y: CGFloat,
        rotation: Double,
        color: Color
    ) -> some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
            .position(x: proxy.size.width * x, y: proxy.size.height * y)
    }

    private func sidebarStarWatermark(
        proxy: GeometryProxy,
        size: CGFloat,
        x: CGFloat,
        y: CGFloat,
        rotation: Double,
        color: Color,
        systemImage: String = "sparkle"
    ) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
            .position(x: proxy.size.width * x, y: proxy.size.height * y)
    }

    private func sidebarRow(for section: AppSection) -> some View {
        let isSelected = selection == section

        return Button {
            select(section)
            closeSidebar()
        } label: {
            HStack(spacing: 13) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28, height: 28)

                Text(section.title(language: language))
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(isSelected ? Color.white : MeowPlannerTheme.cocoa)
            .padding(.horizontal, 12)
            .frame(height: sidebarRowHeight)
            .background(
                isSelected ? MeowPlannerTheme.softBrownHighlight : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title(language: language))
    }

    private func select(_ section: AppSection) {
        onSelect(section)
    }

    private func closeSidebar() {
        isShowingSidebar = false
    }

    private func sidebarWidth(for availableWidth: CGFloat) -> CGFloat {
        min(max(280, availableWidth * 0.78), 360)
    }

    private func bottomNavigationItemWidth(containerWidth: CGFloat) -> CGFloat {
        let itemCount = max(bottomSections.count, 1)
        let totalSpacing = CGFloat(max(itemCount - 1, 0)) * 6
        let availableWidth = max(0, containerWidth - 24 - totalSpacing)
        return max(64, availableWidth / CGFloat(itemCount))
    }

    private var sidebarOpenTitle: String {
        language == .chinese ? "打开侧边栏" : "Open sidebar"
    }

    private var sidebarCloseTitle: String {
        language == .chinese ? "关闭侧边栏" : "Close sidebar"
    }

    private var settingsBackTitle: String {
        language == .chinese ? "返回" : "Back"
    }

    private var calendarNavigationTitle: String {
        calendarNavigationState.displayedMonthTitle.isEmpty
            ? selection.title(language: language)
            : calendarNavigationState.displayedMonthTitle
    }
}
#endif
