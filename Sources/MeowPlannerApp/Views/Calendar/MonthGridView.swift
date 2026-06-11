import MeowPlannerCore
import SwiftData
import SwiftUI

struct MonthGridView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var selectedDate: Date
    var events: [PlannerEvent]
    var todos: [TodoItem]
    var completedSchedulesUseStrikethrough: Bool = true
    var showChineseCalendar: Bool = true
    var onDayDoubleClick: (Date) -> Void = { _ in }
    var onEventDoubleClick: (PlannerEvent) -> Void = { _ in }

    @State private var suppressNextDayDoubleClick = false
    @State private var displayedMonth = Date()

    @Query private var preferences: [PlannerPreference]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let multiDaySegmentHeight: CGFloat = 18
    private let dayCellHorizontalPadding: CGFloat = 8

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
            let dayCellMinHeight = adaptiveDayCellMinHeight(for: proxy.size)

            ZStack {
                calendarWatermark

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Button {
                            moveMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.borderless)

                        Label(monthTitle, systemImage: "pawprint.fill")
                            .font(.title3.bold())
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

                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                            weekdayHeaderCell(symbol)
                        }

                        ForEach(plannerDays) { day in
                            dayCell(day, minHeight: dayCellMinHeight)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(MeowPlannerTheme.monthGridDivider.opacity(0.38), lineWidth: 1)
                    }
                }
            }
            .padding()
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
        .onAppear {
            displayedMonth = monthStart(for: selectedDate)
        }
    }

    private func adaptiveDayCellMinHeight(for availableSize: CGSize) -> CGFloat {
        let nonGridHeight: CGFloat = 116
        let rowCount: CGFloat = 6
        return max(44, (availableSize.height - nonGridHeight) / rowCount)
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

    private var plannerDays: [MonthPlannerDay] {
        MonthPlannerGridBuilder.days(
            for: displayedMonth,
            events: events,
            todos: todos,
            maxVisibleItems: 3,
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

    private func weekdayHeaderCell(_ symbol: String) -> some View {
        Text(symbol)
            .font(.callout.weight(.semibold))
            .foregroundStyle(MeowPlannerTheme.accentText)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
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

    private func dayCell(_ day: MonthPlannerDay, minHeight: CGFloat) -> some View {
        let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)

        return Button {
            selectDate(day.date)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(day.date.formatted(.dateTime.day()))
                        .font(.title3.weight(isSelected ? .bold : .medium))
                        .foregroundStyle(day.isInSelectedMonth ? MeowPlannerTheme.cocoa : .secondary)

                    if showChineseCalendar {
                        chineseCalendarBadge(day.chineseCalendarInfo)
                    }

                    if calendar.isDateInToday(day.date) {
                        Circle()
                            .fill(MeowPlannerTheme.blush)
                            .frame(width: 6, height: 6)
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(day.items) { item in
                        if let event = multiDayEvent(for: item) {
                            if let position = multiDaySegmentPosition(for: event, on: day.date),
                               let span = multiDayEventSpan(for: event, on: day.date) {
                                multiDayTopSpacingPlaceholders(
                                    count: multiDaySpanTopSpacerCount(for: event, on: day.date, in: day)
                                )
                                multiDayEventSegment(item, position: position, span: span)
                            } else {
                                multiDayContinuationPlaceholder(item)
                            }
                        } else {
                            plannerItemRow(item)
                        }
                    }

                    if day.overflowCount > 0 {
                        Text("+\(day.overflowCount)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(MeowPlannerTheme.accentText)
                            .padding(.horizontal, 6)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(8)
            #if os(macOS)
            .frame(minHeight: minHeight, alignment: .top)
            #else
            .frame(minHeight: 58, alignment: .top)
            #endif
            .frame(maxWidth: .infinity)
            .background(dayCellGridBackground(isSelected: isSelected, isInSelectedMonth: day.isInSelectedMonth))
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
        HStack(spacing: 4) {
            if position.showsTitle {
                Image(systemName: "calendar")
                    .font(.system(size: 9, weight: .bold))

                Text(item.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .strikethrough(item.isCompleted && completedSchedulesUseStrikethrough)
            } else {
                segmentPlaceholder
            }
        }
        .foregroundStyle(Color.white)
        .padding(.leading, position.leadingRadius == 0 ? 2 : 6)
        .padding(.trailing, position.trailingRadius == 0 ? 2 : 6)
        .frame(height: multiDaySegmentHeight, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            .font(.caption2.weight(.semibold))
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
        HStack(spacing: 4) {
            Image(systemName: item.kind == .event ? "calendar" : "checkmark.circle")
                .font(.system(size: 9, weight: .bold))

            Text(item.title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .strikethrough(item.isCompleted && completedSchedulesUseStrikethrough)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            .font(.caption2.weight(info.isFestival ? .bold : .medium))
            .foregroundStyle(info.isFestival ? MeowPlannerTheme.blush : MeowPlannerTheme.accentText.opacity(0.86))
            .lineLimit(1)
            .minimumScaleFactor(0.70)
    }

    private func dayBackground(isSelected: Bool, isInSelectedMonth: Bool) -> some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(MeowPlannerTheme.monthGridSelectedDayBackground)
        }
        if isInSelectedMonth {
            return AnyShapeStyle(MeowPlannerTheme.monthGridCurrentMonthCellBackground)
        }
        return AnyShapeStyle(MeowPlannerTheme.monthGridOutsideMonthCellBackground)
    }

    private func dayCellGridBackground(isSelected: Bool, isInSelectedMonth: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(dayBackground(isSelected: isSelected, isInSelectedMonth: isInSelectedMonth))

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

    private func multiDaySpanTopSpacerCount(for event: PlannerEvent, on date: Date, in day: MonthPlannerDay) -> Int {
        guard let span = multiDayEventSpan(for: event, on: date),
              let currentIndex = day.items.firstIndex(where: { $0.id == event.id }) else {
            return 0
        }

        let maxCoveredIndex = (0..<span).reduce(currentIndex) { result, offset in
            guard let coveredDate = calendar.date(byAdding: .day, value: offset, to: date),
                  let coveredDay = plannerDays.first(where: { calendar.isDate($0.date, inSameDayAs: coveredDate) }) else {
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
        let connectingCellPadding = dayCellHorizontalPadding * 2 * CGFloat(max(0, span - 1))
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
        displayedMonth = monthStart(for: targetMonth)
    }

    private func selectDate(_ date: Date) {
        selectedDate = date
        displayedMonth = monthStart(for: date)
    }

    private func resetToToday() {
        let today = Date()
        selectedDate = today
        displayedMonth = monthStart(for: today)
    }

    private func monthStart(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

}
