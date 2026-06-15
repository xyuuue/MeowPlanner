import MeowPlannerCore
#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif
import SwiftData
import SwiftUI
struct CalendarHomeView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.meowPlannerSignedOutReadOnly) private var signedOutReadOnly
    @Query(sort: \PlannerEvent.startDate) private var events: [PlannerEvent]
    @Query private var preferences: [PlannerPreference]
    @AppStorage("meowplanner.calendarFloatingAddButtonPositionX") private var floatingAddButtonPositionX: Double = 1.0
    @AppStorage("meowplanner.calendarFloatingAddButtonPositionY") private var floatingAddButtonPositionY: Double = 1.0

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var monthTransitionDirection = 1
    @State private var selectedEventTagName: String?
    @State private var showingEventEditor = false
    @State private var editingEvent: PlannerEvent?
    @State private var floatingButtonDragOffset = CGSize.zero
    @State private var agendaCardDate: Date?
    @State private var agendaCardScrollAnchorDate = Date()
    @State private var showingIOSDatePicker = false

    private let compactMonthGridMinHeight: CGFloat = 520
    private let regularMonthGridHeight: CGFloat = 760
    private let iosCalendarToolbarHeight: CGFloat = 52
    private let iosCalendarVerticalPadding: CGFloat = 12
    private let iosCalendarBottomReserve: CGFloat = 18
    private let iosMonthGridMinHeight: CGFloat = 620
    private let agendaCardSpacing: CGFloat = 14
    private let agendaCardSidePeek: CGFloat = 30
    private let iosDatePickerYearRange = 1901...2099

    private var displayedEvents: [PlannerEvent] {
        events.filter { event in
            let matchesCompletion = showCompletedSchedules || !event.isCompleted
            let matchesTag = selectedEventTagName == nil || event.tagName == selectedEventTagName
            return matchesCompletion && matchesTag
        }
    }

    private var dayEvents: [PlannerEvent] {
        dayEvents(on: selectedDate)
    }

    private func dayEvents(on date: Date) -> [PlannerEvent] {
        displayedEvents
            .filter { eventOccurs($0, on: date) }
            .sorted(by: completedLastEvents)
    }

    private var calendar: Calendar {
        .current
    }

    var body: some View {
        GeometryReader { proxy in
            #if os(iOS)
            iosFullScreenMonthCalendar(proxy: proxy)
            #else
            desktopCalendarScroll(proxy: proxy)
            #endif
        }
        .overlay(alignment: .bottomTrailing) {
            GeometryReader { proxy in
                let buttonSize = floatingAddButtonSize(for: proxy.size)
                let inset = calendarFloatingAddButtonEdgeInset(for: buttonSize)
                let minX = inset + buttonSize / 2
                let maxX = max(minX, proxy.size.width - inset - buttonSize / 2)
                let minY = inset + buttonSize / 2
                let maxY = max(minY, proxy.size.height - inset - buttonSize / 2)
                let movableWidth = max(0, maxX - minX)
                let movableHeight = max(0, maxY - minY)
                let clampX = { (value: CGFloat) in
                    min(max(value, minX), maxX)
                }
                let clampY = { (value: CGFloat) in
                    min(max(value, minY), maxY)
                }
                let normalizedX = min(max(floatingAddButtonPositionX, 0), 1)
                let normalizedY = min(max(floatingAddButtonPositionY, 0), 1)
                let baseX = minX + CGFloat(normalizedX) * movableWidth
                let baseY = minY + CGFloat(normalizedY) * movableHeight
                let x = clampX(baseX + floatingButtonDragOffset.width)
                let y = clampY(baseY + floatingButtonDragOffset.height)

                floatingAddScheduleButton(size: buttonSize)
                    .position(x: x, y: y)
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !signedOutReadOnly else {
                                    floatingButtonDragOffset = .zero
                                    return
                                }

                                floatingButtonDragOffset = value.translation
                            }
                            .onEnded { value in
                                guard !signedOutReadOnly else {
                                    floatingButtonDragOffset = .zero
                                    return
                                }

                                let finalX = clampX(baseX + value.translation.width)
                                let finalY = clampY(baseY + value.translation.height)
                                let dragDistance = hypot(value.translation.width, value.translation.height)

                                if dragDistance < 8 {
                                    openEventEditor(on: selectedDate)
                                } else {
                                    if movableWidth > 0 {
                                        floatingAddButtonPositionX = Double((finalX - minX) / movableWidth)
                                    }
                                    if movableHeight > 0 {
                                        floatingAddButtonPositionY = Double((finalY - minY) / movableHeight)
                                    }
                                }

                                floatingButtonDragOffset = .zero
                            }
                    )
            }
        }
        .background {
            MeowPlannerTheme.fufuPlannerBackground
                .overlay {
                    MeowPlannerTheme.plannerGradient.opacity(0.86)
                }
                .overlay {
                    mainBackgroundMotifs
                }
        }
        .overlay(alignment: .center) {
            #if os(iOS)
            iosAgendaCardOverlay
            #else
            EmptyView()
            #endif
        }
        .sheet(isPresented: $showingEventEditor) {
            EventEditorView(defaultDate: selectedDate, localRemindersEnabled: localRemindersEnabled, defaultEventIsAllDay: defaultEventIsAllDay)
        }
        .sheet(isPresented: Binding(get: { editingEvent != nil }, set: { if !$0 { editingEvent = nil } })) {
            if let editingEvent {
                EventEditorView(defaultDate: selectedDate, event: editingEvent, localRemindersEnabled: localRemindersEnabled, defaultEventIsAllDay: defaultEventIsAllDay)
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showingIOSDatePicker) {
            IOSCalendarWheelDatePickerSheet(
                selection: iosDatePickerSelection,
                yearRange: iosDatePickerYearRange,
                language: appLanguage,
                calendar: calendar
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
        }
        #endif
    }

    #if os(iOS)
    private func iosFullScreenMonthCalendar(proxy: GeometryProxy) -> some View {
        let iosMonthGridHeight = iosMonthGridHeight(for: proxy.size, safeAreaInsets: proxy.safeAreaInsets)

        return VStack(alignment: .leading, spacing: iosCalendarVerticalPadding) {
            iosCompactCalendarToolbar

            MonthGridView(
                selectedDate: $selectedDate,
                displayedMonth: $displayedMonth,
                monthTransitionDirection: $monthTransitionDirection,
                events: displayedEvents,
                todos: [],
                completedSchedulesUseStrikethrough: completedSchedulesUseStrikethrough,
                showChineseCalendar: showChineseCalendar,
                showsMonthHeader: false,
                onDayTap: { presentAgendaCard(for: $0) },
                onDayDoubleClick: openEventEditor,
                onEventDoubleClick: editEvent
            )
            .frame(maxWidth: .infinity)
            .frame(height: iosMonthGridHeight)
        }
        .padding(.horizontal, 12)
        .padding(.top, iosCalendarVerticalPadding)
        .padding(.bottom, iosCalendarBottomReserve)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var iosCompactCalendarToolbar: some View {
        HStack(spacing: 16) {
            ScheduleDisplayTagFilterMenu(
                selectedTagName: $selectedEventTagName,
                tagNames: eventFilterTagOptions
            )
            .labelStyle(.iconOnly)
            .font(.title2.weight(.semibold))
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            iosDateToolbarTitle

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)
        }
        .frame(height: iosCalendarToolbarHeight)
    }

    private var iosDateToolbarTitle: some View {
        HStack(spacing: 7) {
            Button {
                resetDisplayedMonthToToday()
            } label: {
                FuFuAssetImage(size: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(PlannerCopy.text(.today, language: appLanguage))

            Button {
                presentIOSDatePicker()
            } label: {
                HStack(spacing: 5) {
                    Text(iosDisplayedMonthTitle)
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
            .accessibilityLabel(iosDisplayedMonthTitle)
        }
        .contentShape(Rectangle())
    }

    private var iosDatePickerSelection: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newValue in
                setCalendarSelection(to: newValue)
            }
        )
    }

    private func presentIOSDatePicker() {
        showingIOSDatePicker = true
    }

    private var iosDisplayedMonthTitle: String {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        let year = components.year ?? 0
        let month = components.month ?? 1
        let monthText = month < 10 ? "0\(month)" : "\(month)"
        return "\(year).\(monthText)"
    }

    private func resetDisplayedMonthToToday() {
        setCalendarSelection(to: Date())
    }

    private func iosMonthGridHeight(for availableSize: CGSize, safeAreaInsets: EdgeInsets) -> CGFloat {
        guard availableSize.height.isFinite, availableSize.height > 0 else {
            return iosMonthGridMinHeight
        }

        let reservedHeight = iosCalendarToolbarHeight
            + iosCalendarVerticalPadding * 2
            + iosCalendarBottomReserve
            + max(0, safeAreaInsets.bottom - 12)
        return max(iosMonthGridMinHeight, availableSize.height - reservedHeight)
    }

    private var iosAgendaCardOverlay: some View {
        Group {
            if let displayedAgendaCardDate = agendaCardDate {
                ZStack {
                    Color.black.opacity(0.38)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissAgendaCard()
                        }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center) {
                            Text(iosAgendaTitle(for: displayedAgendaCardDate))
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.72)

                            Spacer(minLength: 10)

                            Button {
                                presentAgendaCard(for: Date())
                            } label: {
                                Label(PlannerCopy.text(.today, language: appLanguage), systemImage: "arrow.uturn.backward")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(MeowPlannerTheme.pawButtonBrown, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)

                        GeometryReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: agendaCardSpacing) {
                                    ForEach(agendaCardDates(centeredOn: agendaCardScrollAnchorDate), id: \.self) { date in
                                        iosAgendaCard(for: date)
                                            .frame(width: agendaCardWidth(for: proxy.size.width))
                                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                                content
                                                    .scaleEffect(phase.isIdentity ? 1 : 0.96)
                                                    .opacity(phase.isIdentity ? 1 : 0.78)
                                            }
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .contentMargins(.horizontal, agendaCardSidePeek, for: .scrollContent)
                            .scrollTargetBehavior(.viewAligned)
                            .scrollPosition(id: $agendaCardDate)
                            .onChange(of: agendaCardDate) { _, newValue in
                                guard let newValue else {
                                    return
                                }
                                setCalendarSelection(to: newValue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 560)
                    }
                    .padding(.horizontal, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: agendaCardDate)
    }

    private func iosAgendaCard(for date: Date) -> some View {
        let addButtonSize = floatingAddButtonSize(for: UIScreen.main.bounds.size)
        let addButtonIconSize = addButtonSize * 24 / 62
        let addButtonRingWidth = addButtonSize * 3 / 62

        return ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(PlannerCopy.text(.schedule, language: appLanguage))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(MeowPlannerTheme.accentText)

                    Spacer()

                    Text(PlannerCopy.scheduleSummary(scheduleCount: dayEvents(on: date).count, language: appLanguage))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(MeowPlannerTheme.cream.opacity(0.72), in: Capsule())
                }

                let eventsForDate = dayEvents(on: date)
                if eventsForDate.isEmpty {
                    FuFuEmptyStateView(
                        title: PlannerCopy.text(.clearDay, language: appLanguage),
                        message: PlannerCopy.text(.clearDayMessage, language: appLanguage),
                        actionTitle: PlannerCopy.text(.addSchedule, language: appLanguage),
                        action: { openEventEditor(on: date) }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(eventsForDate) { event in
                                iosAgendaEventRow(event)
                            }
                        }
                        .padding(.bottom, 88)
                    }
                    .scrollIndicators(.hidden)
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(MeowPlannerTheme.blush.opacity(0.40), lineWidth: 2)
            }

            Button {
                openEventEditor(on: date)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: addButtonIconSize, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: addButtonSize, height: addButtonSize)
                    .background(MeowPlannerTheme.pawButtonBrown, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(MeowPlannerTheme.coffee.opacity(0.34), lineWidth: addButtonRingWidth)
                    }
            }
            .buttonStyle(.plain)
            .padding(24)
            .accessibilityLabel(PlannerCopy.text(.addSchedule, language: appLanguage))
        }
    }

    private func agendaCardWidth(for availableWidth: CGFloat) -> CGFloat {
        guard availableWidth.isFinite, availableWidth > 0 else {
            return 308
        }

        return max(260, availableWidth - agendaCardSidePeek * 2)
    }

    private func iosAgendaEventRow(_ event: PlannerEvent) -> some View {
        HStack(spacing: 12) {
            Button {
                completeEvent(event)
            } label: {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(event.isCompleted ? MeowPlannerTheme.color(hex: event.colorHex) : MeowPlannerTheme.blush.opacity(0.42))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                    .lineLimit(2)
                    .strikethrough(event.isCompleted && completedSchedulesUseStrikethrough)

                Text(event.timeSummary(language: appLanguage))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MeowPlannerTheme.accentText.opacity(0.72))
            }

            Spacer(minLength: 8)

            Button {
                editEvent(event)
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MeowPlannerTheme.accentText)
                    .frame(width: 34, height: 34)
                    .background(MeowPlannerTheme.cream.opacity(0.70), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(MeowPlannerTheme.color(hex: event.colorHex).opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(MeowPlannerTheme.color(hex: event.colorHex))
                .frame(width: 5)
                .padding(.vertical, 10)
        }
    }

    private func agendaCardDates(centeredOn date: Date) -> [Date] {
        let startDate = calendar.startOfDay(for: date)
        return (-15...15).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }

    private func iosAgendaTitle(for date: Date) -> String {
        let dateText = date.formatted(.dateTime.month(.twoDigits).day(.twoDigits).weekday(.wide))
        guard showChineseCalendar else {
            return dateText
        }

        let chineseInfo = ChineseCalendarInfoProvider.info(for: date, calendar: calendar)
        return "\(dateText)  \(chineseInfo.displayText)"
    }

    private func presentAgendaCard(for date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)
        setCalendarSelection(to: normalizedDate)
        agendaCardDate = normalizedDate
        agendaCardScrollAnchorDate = normalizedDate
    }

    private func dismissAgendaCard() {
        agendaCardDate = nil
    }

    #else
    private func desktopCalendarScroll(proxy: GeometryProxy) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                header

                MonthGridView(
                    selectedDate: $selectedDate,
                    displayedMonth: $displayedMonth,
                    monthTransitionDirection: $monthTransitionDirection,
                    events: displayedEvents,
                    todos: [],
                    completedSchedulesUseStrikethrough: completedSchedulesUseStrikethrough,
                    showChineseCalendar: showChineseCalendar,
                    onDayDoubleClick: openEventEditor,
                    onEventDoubleClick: editEvent
                )
                .frame(maxWidth: .infinity)
                .frame(height: monthGridHeight(for: proxy.size.height))

                DayAgendaView(
                    selectedDate: selectedDate,
                    events: dayEvents,
                    onCompleteEvent: completeEvent,
                    onDeleteEvent: deleteEvent,
                    onEditEvent: editEvent,
                    onAddEvent: { openEventEditor(on: selectedDate) },
                    completedSchedulesUseStrikethrough: completedSchedulesUseStrikethrough,
                    showChineseCalendar: showChineseCalendar
                )
            }
            .padding()
        }
        .verticalPageScrollOnly()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    #endif

    private func monthGridHeight(for availableHeight: CGFloat) -> CGFloat {
        guard availableHeight.isFinite else {
            return regularMonthGridHeight
        }

        return min(
            regularMonthGridHeight,
            max(compactMonthGridMinHeight, availableHeight - 140)
        )
    }

    private func floatingAddButtonSize(for availableSize: CGSize) -> CGFloat {
        guard availableSize.width.isFinite,
              availableSize.height.isFinite,
              availableSize.width > 0,
              availableSize.height > 0 else {
            return 62
        }

        let shortSide = min(availableSize.width, availableSize.height)
        let scaledSize = shortSide / 930 * 62
        return min(84, max(50, scaledSize))
    }

    private func calendarFloatingAddButtonEdgeInset(for buttonSize: CGFloat) -> CGFloat {
        min(20, max(16, buttonSize * 0.28))
    }

    private var localRemindersEnabled: Bool {
        preferences.first?.localRemindersEnabled ?? PlannerPreference.defaults.localRemindersEnabled
    }

    private var defaultEventIsAllDay: Bool {
        preferences.first?.defaultEventIsAllDay ?? PlannerPreference.defaults.defaultEventIsAllDay
    }

    private var showCompletedSchedules: Bool {
        preferences.first?.showCompletedSchedules ?? PlannerPreference.defaults.showCompletedSchedules
    }

    private var completedSchedulesUseStrikethrough: Bool {
        preferences.first?.completedSchedulesUseStrikethrough ?? PlannerPreference.defaults.completedSchedulesUseStrikethrough
    }

    private var showChineseCalendar: Bool {
        preferences.first?.showChineseCalendar ?? PlannerPreference.defaults.showChineseCalendar
    }

    private var mainBackgroundMotifs: some View {
        GeometryReader { proxy in
            ZStack {
                cornerPawWatermark(
                    proxy: proxy,
                    size: 300,
                    x: 0.12,
                    y: 0.76,
                    rotation: -12,
                    color: MeowPlannerTheme.fufuPawTint.opacity(0.13)
                )

                centerPawWatermark(
                    proxy: proxy,
                    size: 190,
                    x: 0.50,
                    y: 0.38,
                    rotation: 6,
                    color: MeowPlannerTheme.caramel.opacity(0.15)
                )

                cornerPawWatermark(
                    proxy: proxy,
                    size: 320,
                    x: 0.84,
                    y: 0.70,
                    rotation: 16,
                    color: MeowPlannerTheme.blush.opacity(0.12)
                )

                pawMotif(proxy: proxy, size: 132, x: 0.78, y: 0.10, rotation: 8, color: MeowPlannerTheme.warmCream.opacity(0.09))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }

    private func centerPawWatermark(
        proxy: GeometryProxy,
        size: CGFloat,
        x: CGFloat,
        y: CGFloat,
        rotation: Double,
        color: Color
    ) -> some View {
        Image(systemName: "pawprint")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
            .position(x: proxy.size.width * x, y: proxy.size.height * y)
    }

    private func cornerPawWatermark(
        proxy: GeometryProxy,
        size: CGFloat,
        x: CGFloat,
        y: CGFloat,
        rotation: Double,
        color: Color
    ) -> some View {
        pawMotif(proxy: proxy, size: size, x: x, y: y, rotation: rotation, color: color)
    }

    private func pawMotif(
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

    private func floatingAddScheduleButton(size: CGFloat) -> some View {
        let iconSize = size * 24 / 62
        let ringWidth = size * 3 / 62
        let shadowRadius = size * 14 / 62
        let shadowY = size * 7 / 62

        return Image(systemName: "pawprint.fill")
            .font(.system(size: iconSize, weight: .bold))
            .frame(width: size, height: size)
            .foregroundStyle(.white)
            .background(MeowPlannerTheme.pawButtonBrown, in: Circle())
            .overlay {
                Circle()
                    .stroke(MeowPlannerTheme.creamRing, lineWidth: ringWidth)
            }
            .shadow(color: MeowPlannerTheme.coffee.opacity(0.24), radius: shadowRadius, y: shadowY)
            .opacity(signedOutReadOnly ? 0.45 : 1)
            .contentShape(Circle())
            .accessibilityLabel(PlannerCopy.text(.addSchedule, language: appLanguage))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                openEventEditor(on: selectedDate)
            }
    }

    private var header: some View {
        HStack(spacing: 14) {
            FuFuAssetImage(size: 58)

            VStack(alignment: .leading, spacing: 3) {
                Text(PlannerCopy.text(.fufuTimePlanner, language: appLanguage))
                    .font(.title2.bold())
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Text(PlannerCopy.text(.appSubtitle, language: appLanguage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            scheduleDisplayFilterButton
        }
    }

    private var scheduleDisplayFilterButton: some View {
        ScheduleDisplayTagFilterMenu(
            selectedTagName: $selectedEventTagName,
            tagNames: eventFilterTagOptions
        )
        .buttonStyle(.borderedProminent)
        .tint(MeowPlannerTheme.softBrownHighlight)
    }

    private var eventFilterTagOptions: [String] {
        let configuredTags = preferences.first?.eventTagNames ?? PlannerPreference.defaultEventTagNames
        let eventTags = events.map(\.tagName)
        return PlannerPreference.eventTagOptions(configuredTags: configuredTags, assignedTagNames: eventTags)
    }

    private func eventOccurs(_ event: PlannerEvent, on date: Date) -> Bool {
        event.occurs(on: date, calendar: .current)
    }

    private func completedLastEvents(_ lhs: PlannerEvent, _ rhs: PlannerEvent) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }
        return lhs.startDate < rhs.startDate
    }

    private func completeEvent(_ event: PlannerEvent) {
        guard !signedOutReadOnly else {
            return
        }

        if event.isCompleted {
            event.reopen()
        } else {
            event.markCompleted()
        }
        persistWidgetUpdate()
    }

    private func deleteEvent(_ event: PlannerEvent) {
        guard !signedOutReadOnly else {
            return
        }

        modelContext.delete(event)
        persistWidgetUpdate()
    }

    private func editEvent(_ event: PlannerEvent) {
        guard !signedOutReadOnly else {
            return
        }

        showingEventEditor = false
        agendaCardDate = nil
        editingEvent = event
    }

    private func persistWidgetUpdate() {
        try? modelContext.save()
        WidgetTimelineSyncService.publishSnapshotAndReload(using: modelContext)
    }

    private func openEventEditor(on date: Date) {
        guard !signedOutReadOnly else {
            return
        }

        guard editingEvent == nil else {
            return
        }
        setCalendarSelection(to: date)
        agendaCardDate = nil
        showingEventEditor = true
    }

    private func setCalendarSelection(to date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)
        let targetMonth = monthStart(for: normalizedDate)
        monthTransitionDirection = targetMonth < displayedMonth ? -1 : 1
        withAnimation(.snappy(duration: 0.26)) {
            selectedDate = normalizedDate
            displayedMonth = targetMonth
        }
    }

    private func monthStart(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }
}

#if os(iOS)
private struct IOSCalendarWheelDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: Date
    var yearRange: ClosedRange<Int>
    var language: AppLanguage
    var calendar: Calendar

    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    init(selection: Binding<Date>, yearRange: ClosedRange<Int>, language: AppLanguage, calendar: Calendar) {
        _selection = selection
        self.yearRange = yearRange
        self.language = language
        self.calendar = calendar

        let components = calendar.dateComponents([.year, .month], from: selection.wrappedValue)
        let year = components.year ?? yearRange.lowerBound
        let month = components.month ?? 1
        _selectedYear = State(initialValue: min(max(year, yearRange.lowerBound), yearRange.upperBound))
        _selectedMonth = State(initialValue: min(max(month, 1), 12))
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

            }
            .frame(height: 224)
            .background(MeowPlannerTheme.fufuPlannerBackground)
        }
        .background(MeowPlannerTheme.fufuPlannerBackground)
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
        components.day = 1
        components.hour = time.hour
        components.minute = time.minute
        components.second = time.second
        return calendar.date(from: components) ?? selection
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

}
#endif

private struct EventEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlannerEvent.startDate) private var events: [PlannerEvent]
    @Query private var preferences: [PlannerPreference]

    @State private var title = ""
    @State private var startDate: Date
    @State private var isAllDay = false
    @State private var isMultiDay = false
    @State private var hasEndDate = true
    @State private var endDate: Date
    @State private var hasReminder: Bool
    @State private var reminderOffset = 10
    @State private var tagName = ""
    @State private var repeatRuleSelection: RepeatRuleSelection
    @State private var showingTagSelector = false
    @State private var showingNewTagEditor = false
    @State private var colorHex = PlannerPreference.defaultEventColorHexes[0]
    @State private var didSyncInitialColorWithPalette = false
    @State private var showingPaletteColorEditor = false
    @State private var paletteEditorColorHex = PlannerPreference.defaultEventColorHexes[0]
    @State private var paletteEditorOriginalColorHex: String?
    @State private var notes = ""
    private let localRemindersEnabled: Bool
    private var event: PlannerEvent?

    init(defaultDate: Date, event: PlannerEvent? = nil, localRemindersEnabled: Bool = true, defaultEventIsAllDay: Bool = false) {
        let calendar = Calendar.current
        let roundedDate = event?.startDate ?? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        let initialIsAllDay = event?.isAllDay ?? defaultEventIsAllDay
        let initialIsMultiDay = initialIsAllDay && event?.endDate != nil
        _title = State(initialValue: event?.title ?? "")
        _startDate = State(initialValue: roundedDate)
        _isAllDay = State(initialValue: initialIsAllDay)
        _isMultiDay = State(initialValue: initialIsMultiDay)
        _hasEndDate = State(initialValue: initialIsAllDay ? false : event?.endDate != nil)
        _endDate = State(initialValue: event?.endDate ?? calendar.date(byAdding: .hour, value: 1, to: roundedDate) ?? roundedDate)
        let initialHasReminder = localRemindersEnabled && (event?.reminderOffsetMinutes != nil || event == nil)
        _hasReminder = State(initialValue: initialHasReminder)
        _reminderOffset = State(initialValue: event?.reminderOffsetMinutes ?? 10)
        _tagName = State(initialValue: event?.tagName ?? "")
        _repeatRuleSelection = State(initialValue: RepeatRuleSelection(rule: event?.repeatRule ?? .none, startDate: roundedDate, calendar: calendar))
        let initialColorHex = MeowPlannerTheme.normalizedHex(event?.colorHex ?? PlannerPreference.defaultEventColorHexes[0]) ?? PlannerPreference.defaultEventColorHexes[0]
        _colorHex = State(initialValue: initialColorHex)
        _paletteEditorColorHex = State(initialValue: initialColorHex)
        _notes = State(initialValue: event?.notes ?? "")
        self.localRemindersEnabled = localRemindersEnabled
        self.event = event
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(PlannerCopy.text(.title, language: appLanguage), text: $title)
                Toggle(PlannerCopy.text(.allDay, language: appLanguage), isOn: $isAllDay)
                    .fufuControlTint()
                    .disabled(isMultiDay)
                Toggle(PlannerCopy.text(.multiDayTask, language: appLanguage), isOn: $isMultiDay)
                    .fufuControlTint()
                datePickerRows
                Toggle(PlannerCopy.text(.reminder, language: appLanguage), isOn: $hasReminder)
                    .fufuControlTint()
                    .disabled(!localRemindersEnabled)
                if localRemindersEnabled && hasReminder {
                    PlannerNumberInputRow(
                        title: PlannerCopy.text(.reminderBefore, language: appLanguage),
                        value: $reminderOffset,
                        range: 0...120,
                        suffix: appLanguage == .chinese ? "分钟" : "min"
                    )
                } else if !localRemindersEnabled {
                    Label(PlannerCopy.text(.noReminder, language: appLanguage), systemImage: "bell.slash")
                        .foregroundStyle(.secondary)
                }
                Picker(PlannerCopy.text(.repeatSchedule, language: appLanguage), selection: $repeatRuleSelection) {
                    ForEach(RepeatRuleSelection.allCases) { selection in
                        Text(selection.title(language: appLanguage)).tag(selection)
                    }
                }
                .fufuControlTint()
                Button {
                    showingTagSelector = true
                } label: {
                    LabeledContent(PlannerCopy.text(.tag, language: appLanguage)) {
                        HStack(spacing: 6) {
                            Text(tagName.isEmpty ? PlannerCopy.text(.noTag, language: appLanguage) : tagName)
                                .foregroundStyle(tagName.isEmpty ? .secondary : MeowPlannerTheme.cocoa)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                paletteColorControls
                TextField(PlannerCopy.text(.notes, language: appLanguage), text: $notes, axis: .vertical)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(MeowPlannerTheme.plannerGradient)
            .onAppear(perform: syncInitialColorWithPalette)
            .onChange(of: isMultiDay, syncMultiDayMode)
            .onChange(of: startDate) { _, _ in
                keepDeadlineAfterStart()
            }
            .onChange(of: endDate) { _, _ in
                keepDeadlineAfterStart()
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
            .sheet(isPresented: $showingTagSelector) {
                TagSelectionSheet(
                    selectedTagName: tagName,
                    tagNames: eventTagOptions,
                    onSelect: { selectedTagName in
                        tagName = selectedTagName
                    },
                    onAddTag: {
                        showingTagSelector = false
                        DispatchQueue.main.async {
                            showingNewTagEditor = true
                        }
                    }
                )
            }
            .sheet(isPresented: $showingNewTagEditor) {
                NewTagEditorView { newTagName in
                    addEventTag(newTagName)
                }
            }
            .navigationTitle(event == nil ? PlannerCopy.text(.newSchedule, language: appLanguage) : PlannerCopy.text(.editSchedule, language: appLanguage))
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .frame(minWidth: 420, minHeight: 360)
    }

    private var datePickerRows: some View {
        VStack(spacing: 10) {
            FuFuDatePickerRow(
                title: isMultiDay ? PlannerCopy.text(.startDate, language: appLanguage) : (isAllDay ? PlannerCopy.text(.date, language: appLanguage) : PlannerCopy.text(.startDate, language: appLanguage)),
                selection: $startDate,
                endSelection: $endDate,
                hasEndTime: $hasEndDate,
                includesTime: !isAllDay && !isMultiDay,
                allowsEndTime: !isAllDay && !isMultiDay,
                showChineseCalendar: showChineseCalendar
            )

            if isMultiDay {
                FuFuDatePickerRow(
                    title: PlannerCopy.text(.deadlineDate, language: appLanguage),
                    selection: $endDate,
                    includesTime: false,
                    showChineseCalendar: showChineseCalendar
                )
            }
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
        .listRowBackground(Color.clear)
    }

    private var paletteColorControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(PlannerCopy.text(.color, language: appLanguage))
                    .foregroundStyle(.secondary)

                Spacer()

                Circle()
                    .fill(MeowPlannerTheme.color(hex: colorHex))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Circle()
                            .stroke(Color.primary.opacity(0.14), lineWidth: 1)
                    }
                    .accessibilityLabel(colorHex)
            }

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
                        .overlay {
                            Circle()
                                .stroke(MeowPlannerTheme.caramel.opacity(0.32), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(PlannerCopy.text(.addColor, language: appLanguage))
            }
        }
    }

    private var eventColorOptions: [String] {
        preferences.first?.eventColorHexes ?? PlannerPreference.defaultEventColorHexes
    }

    private var eventTagOptions: [String] {
        let configuredTags = preferences.first?.eventTagNames ?? PlannerPreference.defaultEventTagNames
        let eventTags = events.map(\.tagName)
        return PlannerPreference.eventTagOptions(configuredTags: configuredTags, assignedTagNames: eventTags)
    }

    private var showChineseCalendar: Bool {
        preferences.first?.showChineseCalendar ?? PlannerPreference.defaults.showChineseCalendar
    }

    private var preference: PlannerPreference {
        if let existing = preferences.first {
            return existing
        }

        let created = PlannerPreference.defaults
        modelContext.insert(created)
        return created
    }

    private func syncInitialColorWithPalette() {
        guard event == nil, !didSyncInitialColorWithPalette else {
            return
        }

        didSyncInitialColorWithPalette = true
        if let firstColor = eventColorOptions.first {
            applyColorHex(firstColor)
        }
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

    private func addEventTag(_ value: String) {
        let normalized = PlannerPreference.normalizedTagName(value)
        guard !normalized.isEmpty else {
            return
        }

        var tags = eventTagOptions
        if !tags.contains(normalized) {
            tags.append(normalized)
            preference.eventTagNames = tags
            preference.markUpdated()
            try? modelContext.save()
        }
        tagName = normalized
    }

    private func save() {
        let repeatRule = repeatRuleSelection.rule(for: normalizedStartDate, calendar: .current)
        if let event {
            event.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            event.startDate = normalizedStartDate
            event.endDate = normalizedEndDate
            event.isAllDay = isAllDay || isMultiDay
            event.notes = notes
            event.reminderOffsetMinutes = localRemindersEnabled && hasReminder ? reminderOffset : nil
            event.repeatRule = repeatRule
            event.tagName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
            event.colorHex = colorHex
            event.updatedAt = Date()
        } else {
            let event = PlannerEvent(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: normalizedStartDate,
                endDate: normalizedEndDate,
                isAllDay: isAllDay || isMultiDay,
                notes: notes,
                reminderOffsetMinutes: localRemindersEnabled && hasReminder ? reminderOffset : nil,
                repeatRule: repeatRule,
                tagName: tagName.trimmingCharacters(in: .whitespacesAndNewlines),
                colorHex: colorHex
            )
            modelContext.insert(event)
        }
        try? modelContext.save()
        WidgetTimelineSyncService.publishSnapshotAndReload(using: modelContext)
        dismiss()
    }

    private var normalizedStartDate: Date {
        guard isAllDay || isMultiDay else {
            return startDate
        }
        return Calendar.current.startOfDay(for: startDate)
    }

    private var normalizedEndDate: Date? {
        if isMultiDay {
            let calendar = Calendar.current
            let deadlineStart = calendar.startOfDay(for: endDate)
            let startDay = calendar.startOfDay(for: startDate)
            let safeDeadline = max(deadlineStart, startDay)
            return calendar.date(byAdding: .day, value: 1, to: safeDeadline)?.addingTimeInterval(-1) ?? safeDeadline
        }

        if isAllDay {
            return nil
        }

        return hasEndDate ? endDate : nil
    }

    private func syncMultiDayMode(_ oldValue: Bool, _ newValue: Bool) {
        guard newValue else {
            return
        }

        isAllDay = true
        hasEndDate = false
        keepDeadlineAfterStart()
    }

    private func keepDeadlineAfterStart() {
        guard isMultiDay else {
            return
        }

        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let deadlineDay = calendar.startOfDay(for: endDate)
        if deadlineDay < startDay {
            endDate = startDay
        }
    }
}

private struct FuFuDatePickerRow: View {
    @Environment(\.appLanguage) private var appLanguage

    var title: String
    @Binding var selection: Date
    var endSelection: Binding<Date>? = nil
    var hasEndTime: Binding<Bool>? = nil
    var includesTime: Bool
    var allowsEndTime: Bool = false
    var showChineseCalendar: Bool

    @State private var isExpanded = false
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    displayedMonth = monthStart(for: selection)
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(MeowPlannerTheme.caramel)
                        Image(systemName: "calendar")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)
                    .shadow(color: MeowPlannerTheme.coffee.opacity(0.12), radius: 6, y: 3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MeowPlannerTheme.caramel)
                        Text(primaryDateText)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(MeowPlannerTheme.cocoa)
                        Text(secondaryDateText)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(MeowPlannerTheme.caramel)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .padding(8)
                        .background(MeowPlannerTheme.cream.opacity(0.76), in: Circle())
                }
                .padding(16)
                .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.88), in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(MeowPlannerTheme.caramel.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                FuFuInlineDatePickerPanel(
                    title: title,
                    selection: $selection,
                    displayedMonth: $displayedMonth,
                    endSelection: endSelection,
                    hasEndTime: hasEndTime,
                    includesTime: includesTime,
                    allowsEndTime: allowsEndTime,
                    showChineseCalendar: showChineseCalendar
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            displayedMonth = monthStart(for: selection)
        }
    }

    private var primaryDateText: String {
        selection.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var secondaryDateText: String {
        var parts: [String] = []
        if includesTime {
            let startText = selection.formatted(date: .omitted, time: .shortened)
            if allowsEndTime,
               hasEndTime?.wrappedValue == true,
               let endSelection {
                let endText = endSelection.wrappedValue.formatted(date: .omitted, time: .shortened)
                parts.append("\(startText)-\(endText)")
            } else {
                parts.append(startText)
            }
        } else {
            parts.append(PlannerCopy.text(.allDay, language: appLanguage))
        }

        if showChineseCalendar {
            let info = ChineseCalendarInfoProvider.info(for: selection, calendar: calendar)
            parts.append(info.displayText)
        }

        return parts.joined(separator: " · ")
    }

    private func monthStart(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }
}

private struct FuFuInlineDatePickerPanel: View {
    @Environment(\.appLanguage) private var appLanguage

    var title: String
    @Binding var selection: Date
    @Binding var displayedMonth: Date
    var endSelection: Binding<Date>? = nil
    var hasEndTime: Binding<Bool>? = nil
    var includesTime: Bool
    var allowsEndTime: Bool = false
    var showChineseCalendar: Bool

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(MeowPlannerTheme.cocoa)

                Spacer()

                HStack(spacing: 6) {
                    monthNavigationButton(systemName: "chevron.left", value: -1)
                    monthNavigationButton(systemName: "chevron.right", value: 1)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .frame(maxWidth: .infinity)
                }

                ForEach(inlineCalendarDays, id: \.self) { date in
                    dayButton(for: date)
                }
            }
            .simultaneousGesture(timeEditingCommitGesture)

            if includesTime {
                timeControls
            }
        }
        .padding(20)
        .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.90), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(MeowPlannerTheme.caramel.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: MeowPlannerTheme.coffee.opacity(0.08), radius: 12, y: 5)
        .background(timeEditingCommitMonitor)
        .onChange(of: selection) { _, _ in
            syncEndTimeAfterStartChange()
        }
    }

    private var timeEditingCommitGesture: some Gesture {
        TapGesture().onEnded {
            commitTimeEditingAndNormalize()
        }
    }

    @ViewBuilder
    private var timeEditingCommitMonitor: some View {
        #if os(macOS)
        TimeEditingCommitMonitor(onMouseDown: commitTimeEditingAndNormalize)
        #else
        EmptyView()
        #endif
    }

    private var timeControls: some View {
        VStack(spacing: 10) {
            HStack {
                Label(PlannerCopy.text(.time, language: appLanguage), systemImage: "clock")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Spacer()
                DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .fufuControlTint()
            }

            if allowsEndTime,
               let endSelection,
               let hasEndTime {
                Divider()
                    .background(MeowPlannerTheme.caramel.opacity(0.14))
                    .simultaneousGesture(timeEditingCommitGesture)

                Toggle(PlannerCopy.text(.hasEndTime, language: appLanguage), isOn: endTimeToggleBinding(hasEndTime))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                    .fufuControlTint()

                if hasEndTime.wrappedValue {
                    HStack {
                        Label(PlannerCopy.text(.end, language: appLanguage), systemImage: "clock.badge.checkmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MeowPlannerTheme.cocoa)
                        Spacer()
                        DatePicker("", selection: endTimeSelectionBinding(endSelection), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .fufuControlTint()
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(MeowPlannerTheme.cream.opacity(0.46), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(MeowPlannerTheme.caramel.opacity(0.12), lineWidth: 1)
        }
    }

    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }

    private var inlineCalendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1)) else {
            return []
        }

        var days: [Date] = []
        var current = firstWeek.start
        while current < lastWeek.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? lastWeek.end
        }
        return days
    }

    private func monthNavigationButton(systemName: String, value: Int) -> some View {
        Button {
            displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MeowPlannerTheme.cocoa)
                .frame(width: 30, height: 30)
                .background(MeowPlannerTheme.cream.opacity(0.60), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func dayButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selection)
        let isInDisplayedMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)

        return Button {
            selectDate(date)
        } label: {
            Text(date.formatted(.dateTime.day()))
                .font(.callout.weight(isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? .white : (isInDisplayedMonth ? MeowPlannerTheme.cocoa : .secondary))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    isSelected ? MeowPlannerTheme.caramel : MeowPlannerTheme.cream.opacity(isInDisplayedMonth ? 0.38 : 0.18),
                    in: RoundedRectangle(cornerRadius: 11)
                )
        }
        .buttonStyle(.plain)
    }

    private func selectDate(_ date: Date) {
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: selection)
        var merged = DateComponents()
        merged.year = dayComponents.year
        merged.month = dayComponents.month
        merged.day = dayComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        merged.second = timeComponents.second
        selection = calendar.date(from: merged) ?? date
        displayedMonth = calendar.dateInterval(of: .month, for: date)?.start ?? displayedMonth
    }

    private func endTimeToggleBinding(_ binding: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = newValue
                if newValue {
                    syncEndTimeAfterStartChange()
                }
            }
        )
    }

    private func endTimeSelectionBinding(_ binding: Binding<Date>) -> Binding<Date> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = normalizedEndTime(for: newValue)
            }
        )
    }

    private func commitTimeEditingAndNormalize() {
        resignTimeFieldFocus()
        syncEndTimeAfterStartChange()

        DispatchQueue.main.async {
            syncEndTimeAfterStartChange()
        }
    }

    private func resignTimeFieldFocus() {
        #if os(macOS)
        NSApp.keyWindow?.makeFirstResponder(nil)
        #endif
    }

    private func syncEndTimeAfterStartChange() {
        guard includesTime,
              allowsEndTime,
              let endSelection else {
            return
        }

        endSelection.wrappedValue = normalizedEndTime(for: endSelection.wrappedValue)
    }

    private func normalizedEndTime(for proposedEndDate: Date) -> Date {
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: selection)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: proposedEndDate)
        var merged = DateComponents()
        merged.year = dayComponents.year
        merged.month = dayComponents.month
        merged.day = dayComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        merged.second = timeComponents.second

        let proposed = calendar.date(from: merged) ?? proposedEndDate
        guard proposed <= selection else {
            return proposed
        }

        return calendar.date(byAdding: .hour, value: 1, to: selection) ?? selection.addingTimeInterval(3_600)
    }
}

#if os(macOS)
private struct TimeEditingCommitMonitor: NSViewRepresentable {
    var onMouseDown: () -> Void

    func makeNSView(context: Context) -> MonitoringView {
        let view = MonitoringView()
        view.onMouseDown = onMouseDown
        return view
    }

    func updateNSView(_ nsView: MonitoringView, context: Context) {
        nsView.onMouseDown = onMouseDown
    }

    static func dismantleNSView(_ nsView: MonitoringView, coordinator: ()) {
        nsView.removeMonitor()
    }

    final class MonitoringView: NSView {
        var onMouseDown: () -> Void = {}
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateMonitor()
        }

        private func updateMonitor() {
            removeMonitor()

            guard window != nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                guard let self,
                      event.window === window else {
                    return event
                }

                onMouseDown()
                return event
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
    }
}
#endif

private enum RepeatRuleSelection: String, CaseIterable, Identifiable {
    case none
    case daily
    case weekdays
    case weekly
    case monthly

    var id: String { rawValue }

    init(rule: RepeatRule, startDate: Date, calendar: Calendar) {
        switch rule {
        case .none:
            self = .none
        case .daily(let interval):
            self = interval == 1 ? .daily : .none
        case .weekly(let interval, let weekdays):
            guard interval == 1 else {
                self = .none
                return
            }

            let normalizedWeekdays = Set(weekdays)
            if normalizedWeekdays == Self.weekdaySet {
                self = .weekdays
            } else if normalizedWeekdays == [calendar.component(.weekday, from: startDate)] || weekdays.isEmpty {
                self = .weekly
            } else {
                self = .weekly
            }
        case .monthly(let interval):
            self = interval == 1 ? .monthly : .none
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .none:
            PlannerCopy.text(.repeatNone, language: language)
        case .daily:
            PlannerCopy.text(.repeatDaily, language: language)
        case .weekdays:
            PlannerCopy.text(.repeatWeekdays, language: language)
        case .weekly:
            PlannerCopy.text(.repeatWeekly, language: language)
        case .monthly:
            PlannerCopy.text(.repeatMonthly, language: language)
        }
    }

    func rule(for startDate: Date, calendar: Calendar) -> RepeatRule {
        switch self {
        case .none:
            .none
        case .daily:
            .daily(interval: 1)
        case .weekdays:
            .weekly(interval: 1, weekdays: Array(Self.weekdaySet).sorted())
        case .weekly:
            .weekly(interval: 1, weekdays: [calendar.component(.weekday, from: startDate)])
        case .monthly:
            .monthly(interval: 1)
        }
    }

    private static let weekdaySet: Set<Int> = [2, 3, 4, 5, 6]
}

private struct ScheduleDisplayTagFilterMenu: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedTagName: String?
    var tagNames: [String]

    var body: some View {
        Menu {
            tagButton(title: PlannerCopy.text(.allSchedules, language: appLanguage), tagName: nil)

            Divider()

            ForEach(tagNames, id: \.self) { tagName in
                tagButton(title: tagName, tagName: tagName)
            }
        } label: {
            Label {
                Text(PlannerCopy.text(.scheduleDisplay, language: appLanguage))
            } icon: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .foregroundStyle(MeowPlannerTheme.accentText)
        }
        .accessibilityLabel(PlannerCopy.text(.scheduleDisplay, language: appLanguage))
    }

    private func tagButton(title: String, tagName: String?) -> some View {
        Button {
            selectedTagName = tagName
        } label: {
            Label(title, systemImage: selectedTagName == tagName ? "checkmark.circle.fill" : "circle")
        }
    }
}

private struct TagSelectionSheet: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    var selectedTagName: String
    var tagNames: [String]
    var onSelect: (String) -> Void
    var onAddTag: () -> Void

    var body: some View {
        NavigationStack {
            List {
                tagRow(title: PlannerCopy.text(.noTag, language: appLanguage), tagName: "")

                ForEach(tagNames, id: \.self) { tagName in
                    tagRow(title: tagName, tagName: tagName)
                }

                Button {
                    onAddTag()
                    dismiss()
                } label: {
                    Label(PlannerCopy.text(.newTag, language: appLanguage), systemImage: "plus.circle")
                }
            }
            .scrollContentBackground(.hidden)
            .background(MeowPlannerTheme.plannerGradient)
            .navigationTitle(PlannerCopy.text(.selectTag, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 360, minHeight: 360)
    }

    private func tagRow(title: String, tagName: String) -> some View {
        Button {
            onSelect(tagName)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedTagName == tagName ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedTagName == tagName ? MeowPlannerTheme.caramel : .secondary)
                Text(title)
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct NewTagEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var tagName = ""

    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField(PlannerCopy.text(.tag, language: appLanguage), text: $tagName)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(MeowPlannerTheme.plannerGradient)
            .navigationTitle(PlannerCopy.text(.newTag, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(PlannerCopy.text(.save, language: appLanguage)) {
                        onSave(tagName)
                        dismiss()
                    }
                    .disabled(PlannerPreference.normalizedTagName(tagName).isEmpty)
                }
            }
            .padding()
        }
        .frame(minWidth: 320, minHeight: 180)
    }
}

struct PaletteColorEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var customColor: Color
    @State private var colorHexInput: String

    var originalColorHex: String?
    var canDelete: Bool
    var onSave: (String, String?) -> Void
    var onDelete: (String) -> Void

    init(
        initialColorHex: String,
        originalColorHex: String?,
        canDelete: Bool,
        onSave: @escaping (String, String?) -> Void,
        onDelete: @escaping (String) -> Void
    ) {
        let normalized = MeowPlannerTheme.normalizedHex(initialColorHex) ?? PlannerPreference.defaultEventColorHexes[0]
        _customColor = State(initialValue: MeowPlannerTheme.color(hex: normalized))
        _colorHexInput = State(initialValue: normalized)
        self.originalColorHex = originalColorHex
        self.canDelete = canDelete
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                ColorPicker(PlannerCopy.text(.color, language: appLanguage), selection: $customColor, supportsOpacity: false)

                HStack {
                    Text("HEX")
                        .foregroundStyle(.secondary)
                    TextField("#A66A4D", text: $colorHexInput)
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
                    Text("Use HEX format like #A66A4D")
                        .font(.caption)
                        .foregroundStyle(MeowPlannerTheme.blush)
                }

                if let originalColorHex {
                    Button(role: .destructive) {
                        onDelete(originalColorHex)
                        dismiss()
                    } label: {
                        Label(PlannerCopy.text(.deleteColor, language: appLanguage), systemImage: "trash")
                    }
                    .disabled(!canDelete)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(MeowPlannerTheme.plannerGradient)
            .onChange(of: customColor) { _, _ in
                syncColorFromPicker()
            }
            .onChange(of: colorHexInput) { _, _ in
                syncColorFromHexInput()
            }
            .navigationTitle(originalColorHex == nil ? PlannerCopy.text(.addColor, language: appLanguage) : PlannerCopy.text(.color, language: appLanguage))
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
        .frame(minWidth: 360, minHeight: 240)
    }

    private var normalizedColorHex: String? {
        MeowPlannerTheme.normalizedHex(colorHexInput)
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

struct ColorSwatchButton: View {
    @Environment(\.appLanguage) private var appLanguage

    var colorHex: String
    var isSelected: Bool
    var canDelete: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Circle()
                .fill(MeowPlannerTheme.color(hex: colorHex))
                .frame(width: 26, height: 26)
                .overlay {
                    Circle()
                        .stroke(isSelected ? MeowPlannerTheme.cocoa : Color.primary.opacity(0.14), lineWidth: isSelected ? 3 : 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(colorHex)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(PlannerCopy.text(.deleteColor, language: appLanguage), systemImage: "trash")
            }
            .disabled(!canDelete)
        }
    }
}
