import MeowPlannerCore
import SwiftData
import SwiftUI

struct MonthGridView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    @Binding var monthTransitionDirection: Int
    var events: [PlannerEvent]
    var todos: [TodoItem]
    var completedSchedulesUseStrikethrough: Bool = true
    var showChineseCalendar: Bool = true
    var showsMonthHeader: Bool = true
    var onDayTap: (Date) -> Void = { _ in }
    var onDayDoubleClick: (Date) -> Void = { _ in }
    var onEventDoubleClick: (PlannerEvent) -> Void = { _ in }

    @State private var suppressNextDayDoubleClick = false
    @GestureState private var monthDragTranslation: CGFloat = 0

    @Query private var preferences: [PlannerPreference]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let desktopMultiDaySegmentHeight: CGFloat = 20
    private let desktopDayCellHorizontalPadding: CGFloat = 8
    private let desktopMonthGridContentPadding: CGFloat = 16
    private let desktopMonthGridHeaderHeight: CGFloat = 34
    private let desktopMonthGridContentSpacing: CGFloat = 14
    private let desktopWeekdayHeaderHeight: CGFloat = 34
    private let desktopDayCellVerticalPadding: CGFloat = 8
    private let desktopDayDateHeaderHeight: CGFloat = 24
    private let desktopDayContentSpacing: CGFloat = 2
    private let desktopPlannerItemRowHeight: CGFloat = 20
    private let desktopPlannerItemListSpacing: CGFloat = 4
    private let iosMultiDaySegmentHeight: CGFloat = 14
    private let iosDayCellHorizontalPadding: CGFloat = 3
    private let iosMonthGridContentPadding: CGFloat = 8
    private let iosMonthGridHeaderHeight: CGFloat = 30
    private let iosMonthGridContentSpacing: CGFloat = 8
    private let iosWeekdayHeaderHeight: CGFloat = 26
    private let iosDayCellVerticalPadding: CGFloat = 4
    private let iosDayDateHeaderHeight: CGFloat = 18
    private let iosDayContentSpacing: CGFloat = 1
    private let iosPlannerItemRowHeight: CGFloat = 14
    private let iosPlannerItemListSpacing: CGFloat = 2
    private let minimumVisiblePlannerItemRows: CGFloat = 1

    private var multiDaySegmentHeight: CGFloat {
        #if os(iOS)
        return iosMultiDaySegmentHeight
        #else
        return desktopMultiDaySegmentHeight
        #endif
    }

    private var monthGridContentPadding: CGFloat {
        #if os(iOS)
        return iosMonthGridContentPadding
        #else
        return desktopMonthGridContentPadding
        #endif
    }

    private var monthGridHeaderHeight: CGFloat {
        #if os(iOS)
        return iosMonthGridHeaderHeight
        #else
        return desktopMonthGridHeaderHeight
        #endif
    }

    private var monthGridContentSpacing: CGFloat {
        #if os(iOS)
        return iosMonthGridContentSpacing
        #else
        return desktopMonthGridContentSpacing
        #endif
    }

    private var weekdayHeaderHeight: CGFloat {
        #if os(iOS)
        return iosWeekdayHeaderHeight
        #else
        return desktopWeekdayHeaderHeight
        #endif
    }

    private var dayCellVerticalPadding: CGFloat {
        #if os(iOS)
        return iosDayCellVerticalPadding
        #else
        return desktopDayCellVerticalPadding
        #endif
    }

    private var dayDateHeaderHeight: CGFloat {
        #if os(iOS)
        return iosDayDateHeaderHeight
        #else
        return desktopDayDateHeaderHeight
        #endif
    }

    private var dayContentSpacing: CGFloat {
        #if os(iOS)
        return iosDayContentSpacing
        #else
        return desktopDayContentSpacing
        #endif
    }

    private var plannerItemRowHeight: CGFloat {
        #if os(iOS)
        return iosPlannerItemRowHeight
        #else
        return desktopPlannerItemRowHeight
        #endif
    }

    private var plannerItemListSpacing: CGFloat {
        #if os(iOS)
        return iosPlannerItemListSpacing
        #else
        return desktopPlannerItemListSpacing
        #endif
    }

    private var dayCellHorizontalInset: CGFloat {
        #if os(iOS)
        return iosDayCellHorizontalPadding
        #else
        return desktopDayCellHorizontalPadding
        #endif
    }

    private var monthHeaderFont: Font {
        #if os(iOS)
        return .headline.weight(.bold)
        #else
        return .title3.bold()
        #endif
    }

    private var weekdayHeaderFont: Font {
        #if os(iOS)
        return .system(size: 11, weight: .semibold)
        #else
        return .callout.weight(.semibold)
        #endif
    }

    private var weekdayHeaderVerticalPadding: CGFloat {
        #if os(iOS)
        return 5
        #else
        return 8
        #endif
    }

    private var dayDateHeaderSpacing: CGFloat {
        #if os(iOS)
        return 2
        #else
        return 4
        #endif
    }

    private var todayBadgeSize: CGFloat {
        #if os(iOS)
        return 18
        #else
        return 24
        #endif
    }

    private var plannerItemShowsTitle: Bool {
        #if os(iOS)
        return true
        #else
        return true
        #endif
    }

    private var plannerItemSpacing: CGFloat {
        0
    }

    private var plannerItemTextFont: Font {
        #if os(iOS)
        return .system(size: 8, weight: .semibold)
        #else
        return .caption.weight(.semibold)
        #endif
    }

    private var plannerItemHorizontalPadding: CGFloat {
        #if os(iOS)
        return 3
        #else
        return 6
        #endif
    }

    private var plannerItemConnectedHorizontalPadding: CGFloat {
        #if os(iOS)
        return 1
        #else
        return 2
        #endif
    }

    private var plannerItemVerticalPadding: CGFloat {
        #if os(iOS)
        return 1
        #else
        return 3
        #endif
    }

    private var plannerItemContentAlignment: Alignment {
        plannerItemShowsTitle ? .leading : .center
    }

    private var chineseCalendarFont: Font {
        #if os(iOS)
        return .system(size: 9, weight: .medium)
        #else
        return .caption2.weight(.medium)
        #endif
    }

    private var chineseCalendarFestivalFont: Font {
        #if os(iOS)
        return .system(size: 9, weight: .bold)
        #else
        return .caption2.weight(.bold)
        #endif
    }

    private struct MonthGridLayoutMetrics {
        let contentPadding: CGFloat
        let contentSpacing: CGFloat
        let headerHeight: CGFloat
        let weekdayHeaderHeight: CGFloat
        let rowCount: CGFloat
        let dayCellHeight: CGFloat
        let plannerItemListHeight: CGFloat

        var gridHeight: CGFloat {
            weekdayHeaderHeight + rowCount * dayCellHeight
        }
    }

    private enum MultiDaySegmentPosition {
        case single
        case leading
        case middle
        case trailing

        var showsTitle: Bool {
            self == .single || self == .leading
        }

        var leadingRadius: CGFloat {
            switch self {
            case .single, .leading:
                4
            case .middle, .trailing:
                0
            }
        }

        var trailingRadius: CGFloat {
            switch self {
            case .single, .trailing:
                4
            case .leading, .middle:
                0
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let visiblePlannerDays = plannerDays(maxVisibleItems: Int.max)
            let layoutMetrics = monthGridLayoutMetrics(for: proxy.size, dayCount: visiblePlannerDays.count)

            ZStack {
                calendarWatermark

                VStack(alignment: .leading, spacing: layoutMetrics.contentSpacing) {
                    if showsMonthHeader {
                        HStack(spacing: 10) {
                            Button {
                                moveMonth(by: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .buttonStyle(.borderless)

                            Label(monthTitle, systemImage: "pawprint.fill")
                                .font(monthHeaderFont)
                                .foregroundStyle(MeowPlannerTheme.cocoa)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            Button {
                                moveMonth(by: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                            }
                            .buttonStyle(.borderless)

                            Spacer(minLength: 0)

                            Button {
                                resetToToday()
                            } label: {
                                Label(PlannerCopy.text(.today, language: appLanguage), systemImage: "calendar.badge.clock")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(MeowPlannerTheme.caramel)
                        }
                        .frame(height: layoutMetrics.headerHeight, alignment: .center)
                    }

                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                            weekdayHeaderCell(symbol, height: layoutMetrics.weekdayHeaderHeight)
                        }

                        ForEach(visiblePlannerDays) { day in
                            dayCell(
                                day,
                                height: layoutMetrics.dayCellHeight,
                                plannerItemListHeight: layoutMetrics.plannerItemListHeight,
                                visibleDays: visiblePlannerDays
                            )
                        }
                    }
                    .id(displayedMonth)
                    .offset(x: monthDragTranslation)
                    .transition(monthGridTransition)
                    .frame(height: layoutMetrics.gridHeight, alignment: .top)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(MeowPlannerTheme.monthGridDivider.opacity(0.38), lineWidth: 1)
                    }
                }
            }
            .padding(layoutMetrics.contentPadding)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .background(
            LinearGradient(
                colors: [
                    MeowPlannerTheme.fufuCalendarBackground.opacity(0.92),
                    MeowPlannerTheme.fufuPlannerBackground.opacity(0.74),
                    MeowPlannerTheme.blush.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(MeowPlannerTheme.blush.opacity(0.18), lineWidth: 1)
        }
        .background {
            HorizontalSwipeScrollDetector { horizontal in
                moveMonth(by: horizontal < 0 ? 1 : -1)
            }
        }
        #if os(iOS)
        .simultaneousGesture(monthSwipeGesture)
        #endif
        .animation(.snappy(duration: 0.22), value: displayedMonth)
        .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.86), value: monthDragTranslation)
        .onAppear {
            displayedMonth = monthStart(for: selectedDate)
        }
    }

    private func monthGridLayoutMetrics(for availableSize: CGSize, dayCount: Int) -> MonthGridLayoutMetrics {
        let rowCount = CGFloat(max(1, (max(dayCount, 1) + 6) / 7))
        let availableHeight = availableSize.height.isFinite ? max(0, availableSize.height) : 0
        let fixedHeaderHeight = showsMonthHeader ? monthGridHeaderHeight + monthGridContentSpacing : 0
        let fixedHeight = monthGridContentPadding * 2 + fixedHeaderHeight + weekdayHeaderHeight
        let proposedDayCellHeight = (availableHeight - fixedHeight) / rowCount
        let minimumDayCellHeight = dayCellVerticalPadding * 2
            + dayDateHeaderHeight
            + dayContentSpacing
            + plannerItemListHeight(for: minimumVisiblePlannerItemRows)
        let dayCellHeight = max(minimumDayCellHeight, proposedDayCellHeight.rounded(.down))
        let plannerItemListHeight = max(
            plannerItemListHeight(for: minimumVisiblePlannerItemRows),
            dayCellHeight - dayCellVerticalPadding * 2 - dayDateHeaderHeight - dayContentSpacing
        )

        return MonthGridLayoutMetrics(
            contentPadding: monthGridContentPadding,
            contentSpacing: monthGridContentSpacing,
            headerHeight: showsMonthHeader ? monthGridHeaderHeight : 0,
            weekdayHeaderHeight: weekdayHeaderHeight,
            rowCount: rowCount,
            dayCellHeight: dayCellHeight,
            plannerItemListHeight: plannerItemListHeight
        )
    }

    private func plannerItemListHeight(for visibleRows: CGFloat) -> CGFloat {
        plannerItemRowHeight * visibleRows + plannerItemListSpacing * max(0, visibleRows - 1)
    }

    private var monthGridTransition: AnyTransition {
        #if os(iOS)
        let insertionEdge: Edge = monthTransitionDirection >= 0 ? .trailing : .leading
        let removalEdge: Edge = monthTransitionDirection >= 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
        #else
        return .identity
        #endif
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var weekStartPreference: WeekStartPreference {
        preferences.first?.weekStartPreference ?? .sunday
    }

    private var calendar: Calendar {
        weekStartPreference.configuredCalendar
    }

    private var weekdaySymbols: [String] {
        weekStartPreference.orderedShortWeekdaySymbols(calendar: calendar)
    }

    private func plannerDays(maxVisibleItems: Int) -> [MonthPlannerDay] {
        MonthPlannerGridBuilder.days(
            for: displayedMonth,
            events: events,
            todos: todos,
            maxVisibleItems: maxVisibleItems,
            calendar: calendar
        )
    }

    private var calendarWatermark: some View {
        VStack {
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 54, weight: .bold))
                    .rotationEffect(.degrees(-14))
                    .foregroundStyle(MeowPlannerTheme.caramel.opacity(0.07))
                Spacer()
            }

            Spacer()

            HStack {
                Spacer()
                pawWatermark
            }
        }
        .padding(24)
        .allowsHitTesting(false)
    }

    private var pawWatermark: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 96, weight: .bold))
            .foregroundStyle(MeowPlannerTheme.warmCream.opacity(0.16))
            .rotationEffect(.degrees(10))
    }

    private func weekdayHeaderCell(_ symbol: String, height: CGFloat) -> some View {
        Text(symbol)
            .font(weekdayHeaderFont)
            .foregroundStyle(MeowPlannerTheme.accentText)
            .padding(.vertical, weekdayHeaderVerticalPadding)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(MeowPlannerTheme.monthGridHeaderBackground)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(MeowPlannerTheme.monthGridDivider.opacity(0.34))
                    .frame(height: 1)
            }
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(MeowPlannerTheme.monthGridDivider.opacity(0.34))
                    .frame(width: 1)
            }
    }

    private func dayCell(
        _ day: MonthPlannerDay,
        height: CGFloat,
        plannerItemListHeight: CGFloat,
        visibleDays: [MonthPlannerDay]
    ) -> some View {
        let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day.date)

        return Button {
            selectDate(day.date)
        } label: {
            VStack(alignment: .leading, spacing: dayContentSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: dayDateHeaderSpacing) {
                    dayNumberLabel(day.date, isToday: isToday, isSelected: isSelected, isInSelectedMonth: day.isInSelectedMonth)

                    if showChineseCalendar {
                        chineseCalendarBadge(day.chineseCalendarInfo)
                            .layoutPriority(0)
                    }

                    Spacer(minLength: 0)
                }
                .frame(height: dayDateHeaderHeight, alignment: .top)

                plannerItemList(day, height: plannerItemListHeight, visibleDays: visibleDays)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, dayCellHorizontalInset)
            .padding(.vertical, dayCellVerticalPadding)
            .frame(height: height, alignment: .top)
            .frame(maxWidth: .infinity)
            .background(dayCellGridBackground(isSelected: isSelected, isToday: isToday, isInSelectedMonth: day.isInSelectedMonth))
        }
        .zIndex(dayStartsMultiDaySpan(day) ? 2 : 0)
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    guard !suppressNextDayDoubleClick else {
                        suppressNextDayDoubleClick = false
                        return
                    }

                    selectDate(day.date)
                    onDayDoubleClick(day.date)
            }
        )
    }

    private func plannerItemList(_ day: MonthPlannerDay, height: CGFloat, visibleDays: [MonthPlannerDay]) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: plannerItemListSpacing) {
                ForEach(day.items) { item in
                    if let event = multiDayEvent(for: item) {
                        if let position = multiDaySegmentPosition(for: event, on: day.date),
                           let span = multiDayEventSpan(for: event, on: day.date) {
                            multiDayTopSpacingPlaceholders(
                                count: multiDaySpanTopSpacerCount(for: event, on: day.date, in: day, visibleDays: visibleDays)
                            )
                            multiDayEventSegment(item, position: position, span: span)
                        } else {
                            multiDayContinuationPlaceholder(item)
                        }
                    } else {
                        plannerItemRow(item)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .hiddenVerticalScrollIndicatorsOnMac()
        }
        .scrollIndicators(.hidden)
        .frame(height: height, alignment: .top)
    }

    private func multiDayEventSegment(_ item: MonthPlannerItem, position: MultiDaySegmentPosition, span: Int) -> some View {
        GeometryReader { proxy in
            multiDayEventSegmentContent(item, position: position)
                .frame(width: multiDaySpanWidth(cellContentWidth: proxy.size.width, span: span), alignment: .leading)
        }
        .frame(height: multiDaySegmentHeight)
        .zIndex(3)
        .accessibilityLabel(item.title)
        .highPriorityGesture(eventDoubleClickGesture(for: item))
    }

    private func multiDayEventSegmentContent(_ item: MonthPlannerItem, position: MultiDaySegmentPosition) -> some View {
        HStack(spacing: plannerItemSpacing) {
            if position.showsTitle {
                if plannerItemShowsTitle {
                    Text(item.title)
                        .font(plannerItemTextFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .allowsTightening(true)
                        .strikethrough(item.isCompleted && completedSchedulesUseStrikethrough)
                }
            } else {
                segmentPlaceholder
            }
        }
        .foregroundStyle(Color.white)
        .padding(.leading, position.leadingRadius == 0 ? plannerItemConnectedHorizontalPadding : plannerItemHorizontalPadding)
        .padding(.trailing, position.trailingRadius == 0 ? plannerItemConnectedHorizontalPadding : plannerItemHorizontalPadding)
        .frame(height: multiDaySegmentHeight, alignment: plannerItemContentAlignment)
        .frame(maxWidth: .infinity, alignment: plannerItemContentAlignment)
        .background(
            MeowPlannerTheme.color(hex: item.colorHex).opacity(0.88),
            in: UnevenRoundedRectangle(
                topLeadingRadius: position.leadingRadius,
                bottomLeadingRadius: position.leadingRadius,
                bottomTrailingRadius: position.trailingRadius,
                topTrailingRadius: position.trailingRadius
            )
        )
        .opacity(item.isCompleted ? 0.52 : 1)
    }

    private var segmentPlaceholder: some View {
        Text(" ")
            .font(plannerItemTextFont)
            .lineLimit(1)
            .opacity(0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)
    }

    private func multiDayContinuationPlaceholder(_ item: MonthPlannerItem) -> some View {
        segmentPlaceholder
            .frame(height: multiDaySegmentHeight)
            .accessibilityLabel(item.title)
            .accessibilityHidden(true)
    }

    private func multiDayTopSpacingPlaceholders(count: Int) -> some View {
        ForEach(0..<count, id: \.self) { _ in
            segmentPlaceholder
                .frame(height: multiDaySegmentHeight)
        }
    }

    private func plannerItemRow(_ item: MonthPlannerItem) -> some View {
        HStack(spacing: plannerItemSpacing) {
            if plannerItemShowsTitle {
                Text(item.title)
                    .font(plannerItemTextFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                    .allowsTightening(true)
                    .strikethrough(item.isCompleted && completedSchedulesUseStrikethrough)
            }
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, plannerItemHorizontalPadding)
        .padding(.vertical, plannerItemVerticalPadding)
        .frame(height: plannerItemRowHeight, alignment: plannerItemContentAlignment)
        .frame(maxWidth: .infinity, alignment: plannerItemContentAlignment)
        .background(itemBackground(item), in: RoundedRectangle(cornerRadius: 4))
        .opacity(item.isCompleted ? 0.52 : 1)
        .accessibilityLabel(item.title)
        .highPriorityGesture(eventDoubleClickGesture(for: item))
    }

    private func eventDoubleClickGesture(for item: MonthPlannerItem) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                guard let event = event(for: item) else {
                    return
                }

                suppressNextDayDoubleClick = true
                onEventDoubleClick(event)

                DispatchQueue.main.async {
                    suppressNextDayDoubleClick = false
                }
            }
    }

    private func chineseCalendarBadge(_ info: ChineseCalendarDayInfo) -> some View {
        Text(info.displayText)
            .font(info.isFestival ? chineseCalendarFestivalFont : chineseCalendarFont)
            .foregroundStyle(info.isFestival ? MeowPlannerTheme.blush : MeowPlannerTheme.accentText.opacity(0.86))
            .lineLimit(1)
            .minimumScaleFactor(0.60)
            .allowsTightening(true)
    }

    @ViewBuilder
    private func dayNumberLabel(_ date: Date, isToday: Bool, isSelected: Bool, isInSelectedMonth: Bool) -> some View {
        if isToday {
            Text(date.formatted(.dateTime.day()))
                .font(dayNumberFont(isSelected: isSelected, isToday: isToday))
                .foregroundStyle(isToday ? .white : (isInSelectedMonth ? MeowPlannerTheme.cocoa : .secondary))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: todayBadgeSize, height: todayBadgeSize)
                .background(MeowPlannerTheme.pawButtonBrown, in: Circle())
                .layoutPriority(2)
        } else {
            Text(date.formatted(.dateTime.day()))
                .font(dayNumberFont(isSelected: isSelected, isToday: isToday))
                .foregroundStyle(isToday ? .white : (isInSelectedMonth ? MeowPlannerTheme.cocoa : .secondary))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(2)
        }
    }

    private func dayNumberFont(isSelected: Bool, isToday: Bool) -> Font {
        #if os(iOS)
        return .system(size: 15, weight: (isSelected || isToday) ? .bold : .semibold)
        #else
        return .title3.weight((isSelected || isToday) ? .bold : .medium)
        #endif
    }

    private func dayBackground(isSelected: Bool, isToday: Bool, isInSelectedMonth: Bool) -> some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(MeowPlannerTheme.monthGridSelectedDayBackground)
        }
        if isInSelectedMonth {
            return AnyShapeStyle(MeowPlannerTheme.monthGridCurrentMonthCellBackground)
        }
        return AnyShapeStyle(MeowPlannerTheme.monthGridOutsideMonthCellBackground)
    }

    private func dayCellGridBackground(isSelected: Bool, isToday: Bool, isInSelectedMonth: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(dayBackground(isSelected: isSelected, isToday: isToday, isInSelectedMonth: isInSelectedMonth))

            Rectangle()
                .fill(MeowPlannerTheme.monthGridDivider.opacity(0.30))
                .frame(height: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            Rectangle()
                .fill(MeowPlannerTheme.monthGridDivider.opacity(0.30))
                .frame(width: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
    }

    private func itemBackground(_ item: MonthPlannerItem) -> some ShapeStyle {
        switch item.kind {
        case .event:
            return AnyShapeStyle(MeowPlannerTheme.color(hex: item.colorHex).opacity(0.88))
        case .todo:
            return AnyShapeStyle(MeowPlannerTheme.caramel.opacity(0.78))
        }
    }

    private func multiDayEvent(for item: MonthPlannerItem) -> PlannerEvent? {
        guard let event = event(for: item),
              isMultiDayAllDayEvent(event) else {
            return nil
        }

        return event
    }

    private func event(for item: MonthPlannerItem) -> PlannerEvent? {
        guard item.kind == .event,
              let event = events.first(where: { $0.id == item.id }) else {
            return nil
        }
        return event
    }

    private func isMultiDayAllDayEvent(_ event: PlannerEvent) -> Bool {
        guard event.isAllDay,
              let endDate = event.endDate else {
            return false
        }

        return !calendar.isDate(event.startDate, inSameDayAs: endDate)
    }

    private func dayStartsMultiDaySpan(_ day: MonthPlannerDay) -> Bool {
        day.items.contains { item in
            guard let event = multiDayEvent(for: item) else {
                return false
            }
            return multiDayEventSpan(for: event, on: day.date) != nil
        }
    }

    private func multiDayEventSpan(for event: PlannerEvent, on date: Date) -> Int? {
        guard isMultiDayAllDayEvent(event),
              let endDate = event.endDate,
              event.occurs(on: date, calendar: calendar),
              let weekInterval = calendar.dateInterval(of: .weekOfMonth, for: date) else {
            return nil
        }

        let weekStart = calendar.startOfDay(for: weekInterval.start)
        let actualStart = calendar.startOfDay(for: event.startDate)
        let currentDay = calendar.startOfDay(for: date)
        guard currentDay == actualStart || currentDay == weekStart else {
            return nil
        }

        let weekEnd = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? date
        let segmentEnd = earlierDay(endDate, weekEnd)
        let dayCount = calendar.dateComponents(
            [.day],
            from: currentDay,
            to: calendar.startOfDay(for: segmentEnd)
        ).day ?? 0

        return max(1, min(7, dayCount + 1))
    }

    private func multiDaySpanTopSpacerCount(
        for event: PlannerEvent,
        on date: Date,
        in day: MonthPlannerDay,
        visibleDays: [MonthPlannerDay]
    ) -> Int {
        guard let span = multiDayEventSpan(for: event, on: date),
              let currentIndex = day.items.firstIndex(where: { $0.id == event.id }) else {
            return 0
        }

        let maxCoveredIndex = (0..<span).reduce(currentIndex) { result, offset in
            guard let coveredDate = calendar.date(byAdding: .day, value: offset, to: date),
                  let coveredDay = visibleDays.first(where: { calendar.isDate($0.date, inSameDayAs: coveredDate) }) else {
                return result
            }

            if let coveredIndex = coveredDay.items.firstIndex(where: { $0.id == event.id }) {
                return max(result, coveredIndex)
            }

            return event.occurs(on: coveredDate, calendar: calendar) ? max(result, coveredDay.items.count) : result
        }

        return max(0, maxCoveredIndex - currentIndex)
    }

    private func multiDaySpanWidth(cellContentWidth: CGFloat, span: Int) -> CGFloat {
        let connectingCellPadding = dayCellHorizontalInset * 2 * CGFloat(max(0, span - 1))
        return cellContentWidth * CGFloat(span) + connectingCellPadding
    }

    private func multiDaySegmentPosition(for event: PlannerEvent, on date: Date) -> MultiDaySegmentPosition? {
        guard isMultiDayAllDayEvent(event),
              let endDate = event.endDate,
              let weekInterval = calendar.dateInterval(of: .weekOfMonth, for: date),
              multiDayEventSpan(for: event, on: date) != nil else {
            return nil
        }

        let isActualStart = calendar.isDate(date, inSameDayAs: event.startDate)
        let weekEnd = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? date
        let segmentEnd = earlierDay(endDate, weekEnd)
        let endsAtActualEnd = calendar.isDate(segmentEnd, inSameDayAs: endDate)

        switch (isActualStart, endsAtActualEnd) {
        case (true, true):
            return .single
        case (true, false):
            return .leading
        case (false, true):
            return .trailing
        case (false, false):
            return .middle
        }
    }

    private func earlierDay(_ lhs: Date, _ rhs: Date) -> Date {
        calendar.startOfDay(for: lhs) <= calendar.startOfDay(for: rhs) ? lhs : rhs
    }

    private func moveMonth(by value: Int) {
        let targetMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
        monthTransitionDirection = value < 0 ? -1 : 1
        withAnimation(.snappy(duration: 0.26)) {
            displayedMonth = monthStart(for: targetMonth)
        }
    }

    private func selectDate(_ date: Date) {
        selectedDate = date
        let targetMonth = monthStart(for: date)
        if !calendar.isDate(targetMonth, equalTo: displayedMonth, toGranularity: .month) {
            monthTransitionDirection = targetMonth < displayedMonth ? -1 : 1
        }
        displayedMonth = targetMonth
        onDayTap(date)
    }

    private func resetToToday() {
        let today = Date()
        selectedDate = today
        let targetMonth = monthStart(for: today)
        monthTransitionDirection = targetMonth < displayedMonth ? -1 : 1
        withAnimation(.snappy(duration: 0.26)) {
            displayedMonth = targetMonth
        }
    }

    #if os(iOS)
    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .updating($monthDragTranslation) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else {
                    return
                }
                state = value.translation.width
            }
            .onEnded { value in
                handleMonthSwipe(value)
            }
    }

    private func handleMonthSwipe(_ value: DragGesture.Value) {
        guard abs(value.translation.width) > abs(value.translation.height),
              abs(value.translation.width) > 52 else {
            return
        }

        moveMonth(by: value.translation.width < 0 ? 1 : -1)
    }
    #endif

    private func monthStart(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

}
