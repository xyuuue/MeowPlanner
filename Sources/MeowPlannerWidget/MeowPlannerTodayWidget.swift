import MeowPlannerCore
import AppIntents
import SwiftUI
import WidgetKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerTodayEntry: TimelineEntry {
    public let date: Date
    public let visibleMonthDate: Date
    public let scheduleCount: Int
    public let todoCount: Int
    public let habitCount: Int
    public let showsEmptyState: Bool
    public let monthDays: [MonthPlannerDay]
    public let weekStartPreference: WeekStartPreference
    public let showChineseCalendar: Bool
    public let completedSchedulesUseStrikethrough: Bool
    public let scheduleDisplayRule: WidgetScheduleDisplayRule
    public let weeklyScheduleDays: [WidgetWeeklyScheduleDay]

    public init(
        date: Date,
        visibleMonthDate: Date,
        scheduleCount: Int,
        todoCount: Int,
        habitCount: Int,
        showsEmptyState: Bool = false,
        monthDays: [MonthPlannerDay],
        weekStartPreference: WeekStartPreference,
        showChineseCalendar: Bool = true,
        completedSchedulesUseStrikethrough: Bool = true,
        scheduleDisplayRule: WidgetScheduleDisplayRule = .nextSevenDays,
        weeklyScheduleDays: [WidgetWeeklyScheduleDay] = []
    ) {
        self.date = date
        self.visibleMonthDate = visibleMonthDate
        self.scheduleCount = scheduleCount
        self.todoCount = todoCount
        self.habitCount = habitCount
        self.showsEmptyState = showsEmptyState
        self.monthDays = monthDays
        self.weekStartPreference = weekStartPreference
        self.showChineseCalendar = showChineseCalendar
        self.completedSchedulesUseStrikethrough = completedSchedulesUseStrikethrough
        self.scheduleDisplayRule = scheduleDisplayRule
        self.weeklyScheduleDays = weeklyScheduleDays
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerTodayProvider: AppIntentTimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> MeowPlannerTodayEntry {
        makeEntry(date: Date(), snapshot: nil, configuration: MeowPlannerWidgetConfigurationIntent(), includeSamplePlans: true)
    }

    public func snapshot(
        for configuration: MeowPlannerWidgetConfigurationIntent,
        in context: Context
    ) async -> MeowPlannerTodayEntry {
        let snapshot = Self.currentSnapshot()
        let shouldUseSample = context.isPreview && snapshot == nil
        return makeEntry(
            date: Date(),
            snapshot: snapshot,
            configuration: configuration,
            includeSamplePlans: shouldUseSample
        )
    }

    public func timeline(
        for configuration: MeowPlannerWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<MeowPlannerTodayEntry> {
        let snapshot = Self.currentSnapshot()
        let entry = makeEntry(date: Date(), snapshot: snapshot, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(Self.nextRefreshDate(after: entry.date)))
    }

    static func currentSnapshot() -> WidgetPlannerSnapshot? {
        WidgetPlannerSnapshotStore.loadFromFiles()
    }

    private func makeEntry(
        date: Date,
        snapshot: WidgetPlannerSnapshot?,
        configuration: MeowPlannerWidgetConfigurationIntent,
        includeSamplePlans: Bool = false
    ) -> MeowPlannerTodayEntry {
        let weekStartPreference = includeSamplePlans ? .sunday : (snapshot?.weekStartPreference ?? .sunday)
        let calendar = weekStartPreference.configuredCalendar
        let visibleMonthDate = calendar.date(
            byAdding: .month,
            value: includeSamplePlans ? 0 : WidgetMonthSelectionStore.currentMonthOffset,
            to: date
        ) ?? date
        let allEvents = includeSamplePlans ? sampleEvents(anchor: visibleMonthDate) : (snapshot?.plannerEvents ?? [])
        let showCompletedSchedules = includeSamplePlans ? true : (snapshot?.showCompletedSchedules ?? true)
        let events = allEvents.filter { showCompletedSchedules || !$0.isCompleted }
        let todos = includeSamplePlans ? [] : (snapshot?.todoItems ?? [])
        let monthDays = MonthPlannerGridBuilder.days(
            for: visibleMonthDate,
            events: events,
            todos: todos,
            maxVisibleItems: 2,
            calendar: calendar
        )
        let weeklyScheduleDays = WidgetWeeklySchedulePlanner.days(
            anchorDate: date,
            displayRule: configuration.scheduleDisplayRule,
            events: allEvents.map(WidgetPlannerSnapshot.Event.init(event:)),
            weekStartPreference: weekStartPreference,
            showCompletedSchedules: showCompletedSchedules,
            weekOffset: includeSamplePlans ? 0 : WidgetWeekSelectionStore.currentWeekOffset,
            calendar: calendar
        )

        return MeowPlannerTodayEntry(
            date: date,
            visibleMonthDate: visibleMonthDate,
            scheduleCount: events.count,
            todoCount: todos.count,
            habitCount: includeSamplePlans ? 1 : (snapshot?.habitCount ?? 0),
            showsEmptyState: snapshot == nil && !includeSamplePlans,
            monthDays: monthDays,
            weekStartPreference: weekStartPreference,
            showChineseCalendar: includeSamplePlans ? true : (snapshot?.showChineseCalendar ?? true),
            completedSchedulesUseStrikethrough: includeSamplePlans ? true : (snapshot?.completedSchedulesUseStrikethrough ?? true),
            scheduleDisplayRule: configuration.scheduleDisplayRule,
            weeklyScheduleDays: weeklyScheduleDays
        )
    }

    private static func nextRefreshDate(after date: Date, calendar: Calendar = .current) -> Date {
        let shortRefreshDate = date.addingTimeInterval(60)
        let nextMidnightRefreshDate = calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? calendar.date(byAdding: .hour, value: 1, to: date) ?? date.addingTimeInterval(3600)
        return min(shortRefreshDate, nextMidnightRefreshDate)
    }

    private func sampleEvents(anchor: Date) -> [PlannerEvent] {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: anchor)?.start ?? anchor
        let sampleDays = [3, 10, 17, 24]

        return sampleDays.compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset - 1, to: monthStart) else {
                return nil
            }
            return PlannerEvent(title: "Nail Repair", startDate: date)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerTodayWidget: Widget {
    public let kind = WidgetConstants.todayKind

    private static var supportedFamilies: [WidgetFamily] {
        #if os(iOS)
        return [.systemSmall, .systemMedium, .systemLarge]
        #else
        return [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
        #endif
    }

    public init() {}

    public var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: MeowPlannerWidgetConfigurationIntent.self, provider: MeowPlannerTodayProvider()) { entry in
            MeowPlannerTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("MeowPlanner")
        .description("See FuFu's schedules and plans.")
        .supportedFamilies(Self.supportedFamilies)
        .contentMarginsDisabled()
        .containerBackgroundRemovable(WidgetPlannerPreferenceStore.widgetBackgroundStyle == .transparent)
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct MeowPlannerTodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: MeowPlannerTodayEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                #if os(iOS)
                WeeklyScheduleWidgetView(entry: entry)
                #else
                SummaryWidgetView(entry: entry)
                #endif
            case .systemLarge, .systemExtraLarge:
                MonthWidgetView(entry: entry, family: family)
            default:
                SummaryWidgetView(entry: entry)
            }
        }
        .meowPlannerWidgetContainerBackground()
        .widgetURL(WidgetConstants.appLaunchURL)
    }
}

@available(iOS 17.0, macOS 14.0, *)
private extension View {
    func meowPlannerWidgetContainerBackground() -> some View {
        containerBackground(for: .widget) {
            WidgetContainerBackgroundView()
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
@ViewBuilder
private func widgetFullColorImage(_ image: Image) -> some View {
    if #available(iOS 18.0, macOS 15.0, *) {
        image.widgetAccentedRenderingMode(.fullColor)
    } else {
        image
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct WidgetContainerBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    var body: some View {
        if shouldHideMeowPlannerBackground {
            Color.clear
        } else {
            switch WidgetPlannerPreferenceStore.widgetBackgroundStyle {
            case .defaultArtwork:
                defaultBackground
            case .customPhoto:
                if let image = WidgetBackgroundImageLoader.customBackgroundImage() {
                    #if os(iOS)
                    widgetFullColorImage(
                        Image(uiImage: image)
                            .resizable()
                    )
                        .scaledToFill()
                    #else
                    widgetFullColorImage(
                        Image(nsImage: image)
                            .resizable()
                    )
                        .scaledToFill()
                    #endif
                } else {
                    defaultBackground
                }
            case .transparent:
                Color.clear
            }
        }
    }

    private var shouldHideMeowPlannerBackground: Bool {
        !showsWidgetContainerBackground || WidgetPlannerPreferenceStore.widgetBackgroundStyle == .transparent
    }

    private var defaultBackground: some View {
        #if os(macOS)
        macOSSystemWidgetBackground
        #else
        defaultGradient
        #endif
    }

    #if os(macOS)
    private var macOSWidgetBackgroundIsDark: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: colorScheme == .dark)
    }

    private var macOSSystemWidgetBackground: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)

            WidgetPalette.macOSGlassBackgroundOverlay(isDark: macOSWidgetBackgroundIsDark)

            WidgetPalette.macOSGlassBackgroundWash(isDark: macOSWidgetBackgroundIsDark)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(WidgetPalette.macOSGlassBackgroundBorder(isDark: macOSWidgetBackgroundIsDark), lineWidth: 1)
        }
    }
    #endif

    private var defaultGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.94, blue: 0.86),
                Color(red: 0.93, green: 0.97, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct WeeklyScheduleWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    var entry: MeowPlannerTodayEntry

    private let cardCornerRadius: CGFloat = 26

    private var isDarkBackground: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: colorScheme == .dark)
    }

    private var weeklyScheduleCardFill: Color {
        usesTransparentWidgetBackground ? Color.clear : WidgetPalette.weeklyGlassFill(isDark: isDarkBackground)
    }

    private var weeklyScheduleCardStroke: Color {
        usesTransparentWidgetBackground
            ? WidgetPalette.weeklyTransparentSeparator(isDark: isDarkBackground)
            : WidgetPalette.weeklyGlassStroke(isDark: isDarkBackground)
    }

    private var primaryTextColor: Color {
        WidgetPalette.weeklyPrimaryText(isDark: isDarkBackground)
    }

    private var secondaryTextColor: Color {
        WidgetPalette.weeklySecondaryText(isDark: isDarkBackground)
    }

    private var separatorColor: Color {
        usesTransparentWidgetBackground ? WidgetPalette.weeklyTransparentSeparator(isDark: isDarkBackground) : WidgetPalette.weeklySeparator(isDark: isDarkBackground)
    }

    private var usesTransparentWidgetBackground: Bool {
        !showsWidgetContainerBackground || WidgetPlannerPreferenceStore.widgetBackgroundStyle == .transparent
    }

    private var hasSchedules: Bool {
        entry.weeklyScheduleDays.contains { !$0.events.isEmpty }
    }

    private var calendar: Calendar {
        entry.weekStartPreference.configuredCalendar
    }

    private var monthTitle: String {
        guard let firstDate = entry.weeklyScheduleDays.first?.date else {
            return entry.date.formatted(.dateTime.month(.wide))
        }

        let firstMonth = calendar.component(.month, from: firstDate)
        guard let lastDate = entry.weeklyScheduleDays.last?.date else {
            return "\(firstMonth)月"
        }

        let lastMonth = calendar.component(.month, from: lastDate)
        return firstMonth == lastMonth ? "\(firstMonth)月" : "\(firstMonth)-\(lastMonth)月"
    }

    var body: some View {
        ZStack {
            WidgetScheduleBackgroundView()

            VStack(spacing: 0) {
                header
                    .frame(height: 28)

                weekdayStrip
                    .frame(height: 18)

                calendarColumns
                    .overlay(alignment: .bottom) {
                        if !hasSchedules && !usesTransparentWidgetBackground {
                            Text("No schedules this week")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(secondaryTextColor)
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WidgetPalette.weeklyBadgeFill(isDark: isDarkBackground), in: Capsule())
                                .padding(.bottom, 4)
                        }
                    }
            }
            .background(weeklyScheduleCardFill, in: RoundedRectangle(cornerRadius: cardCornerRadius))
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(weeklyScheduleCardStroke, lineWidth: 1)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .clipped()
    }

    private var header: some View {
        HStack(spacing: 5) {
            weekNavigationButton(delta: -1, systemImage: "chevron.left")

            Text(monthTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(primaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(minWidth: 31, alignment: .center)

            weekNavigationButton(delta: 1, systemImage: "chevron.right")

            Spacer(minLength: 4)

            Link(destination: WidgetConstants.newScheduleURL) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 22, height: 22)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(primaryTextColor)

            Button(intent: RefreshWidgetTimelineIntent()) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 22, height: 22)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(primaryTextColor)
            .accessibilityLabel("刷新小组件")
        }
        .padding(.horizontal, 9)
    }

    private func weekNavigationButton(delta: Int, systemImage: String) -> some View {
        Button(intent: ChangeWidgetWeekIntent(weekDelta: delta)) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 22, height: 22)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(primaryTextColor)
    }

    private var weekdayStrip: some View {
        HStack(spacing: 0) {
            ForEach(entry.weeklyScheduleDays) { day in
                Text(weekdayText(for: day.date))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(weekdayColor(for: day.date))
                    .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(separatorColor)
                .frame(height: 1)
        }
    }

    private var calendarColumns: some View {
        HStack(spacing: 0) {
            ForEach(entry.weeklyScheduleDays) { day in
                WeeklyScheduleCalendarDayColumn(
                    entry: entry,
                    day: day,
                    calendar: calendar,
                    usesTransparentBackground: usesTransparentWidgetBackground
                )
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(separatorColor)
                        .frame(width: 1)
                }
            }
        }
    }

    private func weekdayText(for date: Date) -> String {
        let symbols = ["日", "一", "二", "三", "四", "五", "六"]
        let index = max(1, min(7, calendar.component(.weekday, from: date))) - 1
        return symbols[index]
    }

    private func weekdayColor(for date: Date) -> Color {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 {
            return primaryTextColor
        }

        return secondaryTextColor
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct WidgetScheduleBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    private var isDarkBackground: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: colorScheme == .dark)
    }

    var body: some View {
        GeometryReader { proxy in
            Group {
                if shouldHideMeowPlannerBackground {
                    Color.clear
                } else if let image = WidgetBackgroundImageLoader.image(
                    style: WidgetPlannerPreferenceStore.widgetBackgroundStyle,
                    isDark: isDarkBackground
                ) {
                    #if os(iOS)
                    widgetFullColorImage(
                        Image(uiImage: image)
                            .resizable()
                    )
                        .scaledToFill()
                    #else
                    widgetFullColorImage(
                        Image(nsImage: image)
                            .resizable()
                    )
                        .scaledToFill()
                    #endif
                } else {
                    WidgetPalette.weeklyFallbackBackground(isDark: isDarkBackground)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var shouldHideMeowPlannerBackground: Bool {
        !showsWidgetContainerBackground || WidgetPlannerPreferenceStore.widgetBackgroundStyle == .transparent
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct WeeklyScheduleCalendarDayColumn: View {
    @Environment(\.colorScheme) private var colorScheme

    var entry: MeowPlannerTodayEntry
    var day: WidgetWeeklyScheduleDay
    var calendar: Calendar
    var usesTransparentBackground: Bool

    private let eventTextSize: CGFloat = 8
    private let eventRowHeight: CGFloat = 16
    private let eventRowSpacing: CGFloat = 3
    private let dayHeaderHeight: CGFloat = 19
    private let headerToEventsSpacing: CGFloat = 5
    private let columnTopPadding: CGFloat = 6
    private let columnHorizontalPadding: CGFloat = 4
    private let columnBottomInset: CGFloat = 6

    private var isDarkBackground: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: colorScheme == .dark)
    }

    private var primaryTextColor: Color {
        WidgetPalette.weeklyPrimaryText(isDark: isDarkBackground)
    }

    private var secondaryTextColor: Color {
        WidgetPalette.weeklySecondaryText(isDark: isDarkBackground)
    }

    private var isToday: Bool {
        calendar.isDate(day.date, inSameDayAs: entry.date)
    }

    private var chineseCalendarInfo: ChineseCalendarDayInfo {
        ChineseCalendarInfoProvider.info(for: day.date, calendar: calendar)
    }

    var body: some View {
        GeometryReader { proxy in
            let visibleRows = visibleEventRows(for: proxy.size.height)
            let visibleEvents = visibleEvents(for: visibleRows)
            let overflowCount = day.events.count - visibleEvents.count

            VStack(alignment: .leading, spacing: headerToEventsSpacing) {
                dayHeader
                    .frame(height: dayHeaderHeight, alignment: .topLeading)

                VStack(alignment: .leading, spacing: eventRowSpacing) {
                    ForEach(visibleEvents, id: \.id) { event in
                        eventPill(event)
                    }

                    if overflowCount > 0 {
                        overflowIndicator(overflowCount)
                    }

                    if day.events.isEmpty && !usesTransparentBackground {
                        emptySkeleton
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, columnHorizontalPadding)
            .padding(.top, columnTopPadding)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var dayHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if isToday && !usesTransparentBackground {
                Text("今")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(WidgetPalette.orange, in: Circle())
            } else {
                Text("\(calendar.component(.day, from: day.date))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            if entry.showChineseCalendar {
                Text(chineseCalendarInfo.displayText)
                    .font(.system(size: 8, weight: chineseCalendarInfo.isFestival ? .bold : .medium))
                    .foregroundStyle(chineseCalendarInfo.isFestival ? WidgetPalette.weeklyFestivalText(isDark: isDarkBackground) : secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
    }

    private var emptySkeleton: some View {
        VStack(alignment: .leading, spacing: 5) {
            Capsule()
                .fill(WidgetPalette.weeklySkeletonFill(isDark: isDarkBackground, strong: true))
                .frame(maxWidth: .infinity)
                .frame(height: 4)

            Capsule()
                .fill(WidgetPalette.weeklySkeletonFill(isDark: isDarkBackground, strong: false))
                .frame(width: 22, height: 4)
        }
        .padding(.top, 2)
    }

    private func visibleEvents(for visibleRows: Int) -> [WidgetPlannerSnapshot.Event] {
        guard visibleRows > 0 else {
            return []
        }

        guard day.events.count > visibleRows else {
            return day.events
        }

        return Array(day.events.prefix(max(0, visibleRows - 1)))
    }

    private func visibleEventRows(for columnHeight: CGFloat) -> Int {
        let availableHeight = max(
            0,
            columnHeight - columnTopPadding - dayHeaderHeight - headerToEventsSpacing - columnBottomInset
        )
        let fullRowHeight = eventRowHeight + eventRowSpacing
        return max(0, Int((availableHeight + eventRowSpacing) / fullRowHeight))
    }

    private func eventPill(_ event: WidgetPlannerSnapshot.Event) -> some View {
        Text(event.title)
            .font(.system(size: eventTextSize, weight: .medium))
            .foregroundStyle(primaryTextColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .strikethrough(event.isCompleted && entry.completedSchedulesUseStrikethrough)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: eventRowHeight, maxHeight: eventRowHeight, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(eventColor(hex: event.colorHex).opacity(event.isCompleted ? completedEventOpacity : activeEventOpacity))
            }
            .opacity(event.isCompleted ? 0.68 : 1)
    }

    private func overflowIndicator(_ count: Int) -> some View {
        Text("+\(count)")
            .font(.system(size: eventTextSize, weight: .bold))
            .foregroundStyle(isDarkBackground ? Color.white.opacity(0.78) : WidgetPalette.blue)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: eventRowHeight, maxHeight: eventRowHeight, alignment: .leading)
    }

    private var activeEventOpacity: Double {
        isDarkBackground ? 0.36 : 0.22
    }

    private var completedEventOpacity: Double {
        isDarkBackground ? 0.18 : 0.10
    }

    private func eventColor(hex: String) -> Color {
        let normalizedHex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        guard normalizedHex.count == 6,
              let rawValue = UInt64(normalizedHex, radix: 16) else {
            return WidgetPalette.blue
        }

        let red = Double((rawValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rawValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rawValue & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct SummaryWidgetView: View {
    var entry: MeowPlannerTodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(WidgetPalette.blue)
                Text("MeowPlanner")
                    .font(.headline)
            }

            if entry.showChineseCalendar {
                let info = ChineseCalendarInfoProvider.info(for: entry.date, calendar: entry.weekStartPreference.configuredCalendar)
                Text(info.displayText)
                    .font(.caption.weight(info.isFestival ? .bold : .medium))
                    .foregroundStyle(info.isFestival ? WidgetPalette.blush : WidgetPalette.caramel)
                    .lineLimit(1)
            }

            Spacer()

            if entry.showsEmptyState {
                emptyStateSummary
            } else {
                Label("\(entry.scheduleCount) schedules", systemImage: "calendar")
                Label("\(entry.todoCount) todos", systemImage: "checklist")
                Label("\(entry.habitCount) habits", systemImage: "checkmark.seal")
            }
        }
        .font(.caption)
    }

    private var emptyStateSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(WidgetPalette.blue)

                Text("No plans yet")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(WidgetPalette.cocoa)

            Text("Open MeowPlanner to sync")
                .font(.caption2.weight(.medium))
                .foregroundStyle(WidgetPalette.caramel)
                .lineLimit(2)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct MonthWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

    var entry: MeowPlannerTodayEntry
    var family: WidgetFamily

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        GeometryReader { proxy in
            let outerPadding: CGFloat = family == .systemExtraLarge ? 7 : 5
            let headerHeight: CGFloat = family == .systemExtraLarge ? 22 : 20
            let weekdayHeight: CGFloat = 15
            let verticalSpacing: CGFloat = 2
            let rowCount = max(1, entry.monthDays.count / 7)
            let rowHeight = floor(max(
                16,
                (proxy.size.height - (outerPadding * 2) - headerHeight - weekdayHeight - verticalSpacing) / CGFloat(rowCount)
            ))

            ZStack(alignment: .bottomTrailing) {
                if showsWidgetContainerBackground && WidgetPlannerPreferenceStore.widgetBackgroundStyle == .defaultArtwork {
                    fufuPawWatermark
                }

                VStack(alignment: .leading, spacing: verticalSpacing) {
                    monthHeader
                        .frame(height: headerHeight)
                        .zIndex(1)

                    calendarGrid(rowHeight: rowHeight, weekdayHeight: weekdayHeight)
                }
                .padding(outerPadding)

                if entry.showsEmptyState {
                    emptyStateOverlay
                }
            }
        }
    }

    private var monthTitle: String {
        entry.visibleMonthDate.formatted(.dateTime.month(.abbreviated).year())
    }

    private var calendar: Calendar {
        entry.weekStartPreference.configuredCalendar
    }

    private var weekdaySymbols: [String] {
        entry.weekStartPreference.orderedVeryShortWeekdaySymbols(calendar: calendar)
    }

    private var usesFullColorRendering: Bool {
        widgetRenderingMode == .fullColor
    }

    private var usesMacOSGlassBackground: Bool {
        #if os(macOS)
        showsWidgetContainerBackground && WidgetPlannerPreferenceStore.widgetBackgroundStyle == .defaultArtwork
        #else
        false
        #endif
    }

    private var isDarkBackground: Bool {
        WidgetPlannerPreferenceStore.isDarkWidgetAppearance(systemIsDark: colorScheme == .dark)
    }

    private var monthPrimaryTextColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassPrimaryText(isDark: isDarkBackground) : WidgetPalette.cocoa
    }

    private var monthSecondaryTextColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassSecondaryText(isDark: isDarkBackground) : WidgetPalette.caramel
    }

    private var monthMutedTextColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassMutedText(isDark: isDarkBackground) : Color.secondary
    }

    private var monthFestivalTextColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassFestivalText(isDark: isDarkBackground) : WidgetPalette.blush
    }

    private var monthGridLineColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassGridLine(isDark: isDarkBackground) : WidgetPalette.caramel.opacity(0.12)
    }

    private var monthGridBorderColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassGridBorder(isDark: isDarkBackground) : WidgetPalette.caramel.opacity(0.18)
    }

    private var monthTodayIndicatorColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassTodayIndicator(isDark: isDarkBackground) : WidgetPalette.blush
    }

    private var monthTodayBackgroundColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassTodayBackground(isDark: isDarkBackground) : WidgetPalette.blue.opacity(0.18)
    }

    private var fufuPawPrimaryWatermarkColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassPawPrimary(isDark: isDarkBackground) : WidgetPalette.caramel.opacity(0.10)
    }

    private var fufuPawSecondaryWatermarkColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassPawSecondary(isDark: isDarkBackground) : WidgetPalette.blue.opacity(0.10)
    }

    private var completedEventPillOpacity: Double {
        usesFullColorRendering ? 0.52 : 0.76
    }

    private var activeEventPillDarkeningOpacity: Double {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassActiveEventPillDarkeningOpacity(isDark: isDarkBackground) : 0
    }

    private var emptyStateBackgroundColor: Color {
        usesMacOSGlassBackground ? WidgetPalette.macOSGlassEmptyStateFill(isDark: isDarkBackground) : WidgetPalette.cream.opacity(0.84)
    }

    private var emptyStateOverlay: some View {
        VStack(spacing: 4) {
            fufuWidgetMascot(size: family == .systemExtraLarge ? 28 : 24)

            Text("No plans yet")
                .font(.caption.weight(.semibold))
                .foregroundStyle(monthPrimaryTextColor)

            Text("Open MeowPlanner to sync")
                .font(.caption2.weight(.medium))
                .foregroundStyle(monthSecondaryTextColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(emptyStateBackgroundColor, in: RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(monthGridBorderColor, lineWidth: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .allowsHitTesting(false)
    }

    private var monthHeader: some View {
        HStack(spacing: 5) {
            Button(intent: ChangeWidgetMonthIntent(monthDelta: -1)) {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(monthPrimaryTextColor)

            Label(monthTitle, systemImage: "pawprint.fill")
                .font((family == .systemExtraLarge ? Font.subheadline : Font.caption2).weight(.bold))
                .foregroundStyle(monthPrimaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Button(intent: ChangeWidgetMonthIntent(monthDelta: 1)) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(monthPrimaryTextColor)

            Spacer(minLength: 4)

            Button(intent: RefreshWidgetTimelineIntent()) {
                Image(systemName: "pawprint.fill")
                    .font((family == .systemExtraLarge ? Font.body : Font.caption).weight(.bold))
                    .foregroundStyle(monthPrimaryTextColor)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 2)
    }

    private func calendarGrid(rowHeight: CGFloat, weekdayHeight: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, weekday in
                weekdayHeaderCell(weekday, height: weekdayHeight)
            }

            ForEach(entry.monthDays) { day in
                dayCell(day, rowHeight: rowHeight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(monthGridBorderColor, lineWidth: 1)
        }
    }

    private var weekdaySeparatorColor: Color {
        monthGridLineColor
    }

    private func weekdayHeaderCell(_ weekday: String, height: CGFloat) -> some View {
        Text(weekday)
            .font(.caption2.weight(.bold))
            .foregroundStyle(monthSecondaryTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(weekdaySeparatorColor)
                    .frame(height: 1)
            }
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(weekdaySeparatorColor)
                    .frame(width: 1)
            }
    }

    private func dayCell(_ day: MonthPlannerDay, rowHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Text(day.date.formatted(.dateTime.day()))
                    .font(.caption.weight(calendar.isDate(day.date, inSameDayAs: entry.date) ? .bold : .semibold))
                    .foregroundStyle(day.isInSelectedMonth ? monthPrimaryTextColor : monthMutedTextColor)

                if entry.showChineseCalendar {
                    Text(day.chineseCalendarInfo.displayText)
                        .font(.caption2.weight(day.chineseCalendarInfo.isFestival ? .bold : .medium))
                        .foregroundStyle(day.chineseCalendarInfo.isFestival ? monthFestivalTextColor : monthSecondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)
                }

                if calendar.isDateInToday(day.date) {
                    Circle()
                        .fill(monthTodayIndicatorColor)
                        .frame(width: 4, height: 4)
                }

                Spacer(minLength: 0)
            }

            let maxVisibleItems: Int = family == .systemExtraLarge ? 2 : 1
            ForEach(day.items.prefix(maxVisibleItems)) { item in
                eventPill(item)
            }

            Spacer(minLength: 0)
        }
        .padding(5)
        .frame(height: rowHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(dayBackground(day), in: Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(weekdaySeparatorColor)
                .frame(height: 1)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(weekdaySeparatorColor)
                .frame(width: 1)
        }
    }

    private func dayBackground(_ day: MonthPlannerDay) -> some ShapeStyle {
        if calendar.isDateInToday(day.date) {
            return AnyShapeStyle(monthTodayBackgroundColor)
        }
        return AnyShapeStyle(Color.clear)
    }

    private func eventPill(_ item: MonthPlannerItem) -> some View {
        Text(item.title)
            .font(.caption2.weight(.medium))
            .foregroundStyle(eventPillTitleColor())
            .lineLimit(1)
            .strikethrough(item.isCompleted && entry.completedSchedulesUseStrikethrough)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 3)
                    .fill(eventPillBackground(item))
                    .overlay {
                        if !item.isCompleted && activeEventPillDarkeningOpacity > 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.black.opacity(activeEventPillDarkeningOpacity))
                        }
                    }
            }
            .opacity(item.isCompleted ? completedEventPillOpacity : 1)
    }

    private func eventPillTitleColor() -> some ShapeStyle {
        usesMacOSGlassBackground ? AnyShapeStyle(WidgetPalette.macOSGlassEventPillText(isDark: isDarkBackground)) : AnyShapeStyle(WidgetPalette.cocoa)
    }

    private func eventPillBackground(_ item: MonthPlannerItem) -> some ShapeStyle {
        AnyShapeStyle(
            widgetColor(
                hex: item.colorHex,
                fallback: item.kind == .event ? WidgetPalette.blue : WidgetPalette.caramel
            )
        )
    }

    private func widgetColor(hex: String, fallback: Color) -> Color {
        let normalizedHex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
        guard normalizedHex.count == 6,
              let rawValue = UInt64(normalizedHex, radix: 16) else {
            return fallback
        }

        let red = Double((rawValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rawValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rawValue & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }

    private var fufuPawWatermark: some View {
        VStack {
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: family == .systemExtraLarge ? 74 : 46, weight: .bold))
                    .rotationEffect(.degrees(-16))
                    .foregroundStyle(fufuPawPrimaryWatermarkColor)
                Spacer()
            }

            Spacer()

            HStack {
                Spacer()
                Image(systemName: "pawprint.fill")
                    .font(.system(size: family == .systemExtraLarge ? 92 : 56, weight: .bold))
                    .rotationEffect(.degrees(18))
                    .foregroundStyle(fufuPawSecondaryWatermarkColor)
            }
        }
        .allowsHitTesting(false)
    }

    private func fufuWidgetMascot(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(WidgetPalette.cream.opacity(0.72))

            if let image = WidgetFuFuImageLoader.image() {
                #if os(macOS)
                widgetFullColorImage(
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                )
                    .scaledToFit()
                    .padding(size * 0.14)
                #else
                widgetFullColorImage(
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                )
                    .scaledToFit()
                    .padding(size * 0.14)
                #endif
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.48, weight: .bold))
                    .foregroundStyle(WidgetPalette.caramel)
            }
        }
        .frame(width: size, height: size)
    }
}

private enum WidgetFuFuImageLoader {
    #if os(macOS)
    static func image() -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: "fufu-idle",
            withExtension: "png",
            subdirectory: "FuFu"
        ) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
    #else
    static func image() -> UIImage? {
        guard let url = Bundle.main.url(
            forResource: "fufu-idle",
            withExtension: "png",
            subdirectory: "FuFu"
        ) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
    #endif
}

private enum WidgetResourceBundle {
    static func url(forResource name: String, withExtension extensionName: String, subdirectory: String? = nil) -> URL? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(
            forResource: name,
            withExtension: extensionName,
            subdirectory: subdirectory
        ) {
            return url
        }
        #endif

        return Bundle.main.url(
            forResource: name,
            withExtension: extensionName,
            subdirectory: subdirectory
        )
    }
}

private enum WidgetBackgroundImageLoader {
    #if os(iOS)
    static func image(style: WidgetBackgroundStyle, isDark: Bool) -> UIImage? {
        switch style {
        case .defaultArtwork:
            bundledImage(isDark: isDark)
        case .customPhoto:
            customBackgroundImage()
        case .transparent:
            nil
        }
    }

    static func bundledImage(isDark: Bool) -> UIImage? {
        guard let url = WidgetResourceBundle.url(
            forResource: isDark ? "WidgetBackgroundDark" : "WidgetBackgroundLight",
            withExtension: "png"
        ) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    static func customBackgroundImage() -> UIImage? {
        guard let url = WidgetPlannerPreferenceStore.customBackgroundImageURL,
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return UIImage(data: data)
    }
    #else
    static func image(style: WidgetBackgroundStyle, isDark: Bool) -> NSImage? {
        switch style {
        case .defaultArtwork:
            bundledImage(isDark: isDark)
        case .customPhoto:
            customBackgroundImage()
        case .transparent:
            nil
        }
    }

    static func bundledImage(isDark: Bool) -> NSImage? {
        guard let url = WidgetResourceBundle.url(
            forResource: isDark ? "WidgetBackgroundDark" : "WidgetBackgroundLight",
            withExtension: "png"
        ) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    static func customBackgroundImage() -> NSImage? {
        guard let url = WidgetPlannerPreferenceStore.customBackgroundImageURL,
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return NSImage(data: data)
    }
    #endif
}

private enum WidgetPalette {
    static let cream = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let cocoa = Color(red: 0.24, green: 0.15, blue: 0.10)
    static let caramel = Color(red: 0.68, green: 0.45, blue: 0.27)
    static let blue = Color(red: 0.18, green: 0.45, blue: 0.68)
    static let blush = Color(red: 0.88, green: 0.58, blue: 0.51)
    static let orange = Color(red: 1.00, green: 0.53, blue: 0.04)

    static func macOSGlassBackgroundOverlay(isDark: Bool) -> LinearGradient {
        LinearGradient(
            colors: isDark
                ? [
                    Color(red: 0.10, green: 0.11, blue: 0.11).opacity(0.78),
                    Color(red: 0.18, green: 0.19, blue: 0.18).opacity(0.56),
                    Color(red: 0.04, green: 0.05, blue: 0.05).opacity(0.62)
                ]
                : [
                    Color.white.opacity(0.74),
                    Color(red: 0.91, green: 0.91, blue: 0.88).opacity(0.56),
                    Color(red: 0.78, green: 0.79, blue: 0.77).opacity(0.34)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func macOSGlassBackgroundWash(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.16) : Color.white.opacity(0.18)
    }

    static func macOSGlassBackgroundBorder(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.12)
    }

    static func macOSGlassPrimaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.86) : Color.black.opacity(0.68)
    }

    static func macOSGlassSecondaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.64) : Color.black.opacity(0.50)
    }

    static func macOSGlassMutedText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.42) : Color.black.opacity(0.34)
    }

    static func macOSGlassFestivalText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.84) : Color.black.opacity(0.62)
    }

    static func macOSGlassGridLine(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.12)
    }

    static func macOSGlassGridBorder(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.26) : Color.black.opacity(0.18)
    }

    static func macOSGlassTodayIndicator(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.78) : Color.black.opacity(0.46)
    }

    static func macOSGlassTodayBackground(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    static func macOSGlassEventPillText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.86) : Color.black.opacity(0.70)
    }

    static func macOSGlassActiveEventPillDarkeningOpacity(isDark: Bool) -> Double {
        isDark ? 0.26 : 0.18
    }

    static func macOSGlassPawPrimary(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    static func macOSGlassPawSecondary(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    static func macOSGlassEmptyStateFill(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.24) : Color.white.opacity(0.64)
    }

    static func weeklyGlassFill(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.46) : Color.white.opacity(0.72)
    }

    static func weeklyGlassStroke(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.16) : caramel.opacity(0.18)
    }

    static func weeklyPrimaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.92) : cocoa
    }

    static func weeklySecondaryText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.62) : caramel.opacity(0.82)
    }

    static func weeklyFestivalText(isDark: Bool) -> Color {
        isDark ? Color(red: 1.0, green: 0.70, blue: 0.63) : blush
    }

    static func weeklySeparator(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.12) : caramel.opacity(0.12)
    }

    static func weeklyTransparentSeparator(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.20) : caramel.opacity(0.20)
    }

    static func weeklyBadgeFill(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.26) : cream.opacity(0.72)
    }

    static func weeklySkeletonFill(isDark: Bool, strong: Bool) -> Color {
        if isDark {
            return Color.white.opacity(strong ? 0.16 : 0.10)
        }
        return caramel.opacity(strong ? 0.12 : 0.07)
    }

    static func weeklyFallbackBackground(isDark: Bool) -> LinearGradient {
        LinearGradient(
            colors: isDark
                ? [
                    Color(red: 0.12, green: 0.13, blue: 0.14),
                    Color(red: 0.05, green: 0.06, blue: 0.07)
                ]
                : [
                    Color(red: 0.99, green: 0.92, blue: 0.86),
                    Color(red: 0.98, green: 0.97, blue: 0.93)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
