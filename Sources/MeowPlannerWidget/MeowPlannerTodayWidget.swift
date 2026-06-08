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
    public let monthDays: [MonthPlannerDay]
    public let weekStartPreference: WeekStartPreference
    public let showChineseCalendar: Bool
    public let completedSchedulesUseStrikethrough: Bool

    public init(
        date: Date,
        visibleMonthDate: Date,
        scheduleCount: Int,
        todoCount: Int,
        habitCount: Int,
        monthDays: [MonthPlannerDay],
        weekStartPreference: WeekStartPreference,
        showChineseCalendar: Bool = true,
        completedSchedulesUseStrikethrough: Bool = true
    ) {
        self.date = date
        self.visibleMonthDate = visibleMonthDate
        self.scheduleCount = scheduleCount
        self.todoCount = todoCount
        self.habitCount = habitCount
        self.monthDays = monthDays
        self.weekStartPreference = weekStartPreference
        self.showChineseCalendar = showChineseCalendar
        self.completedSchedulesUseStrikethrough = completedSchedulesUseStrikethrough
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct MeowPlannerTodayProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> MeowPlannerTodayEntry {
        makeEntry(date: Date(), snapshot: nil, includeSamplePlans: true)
    }

    public func getSnapshot(in context: Context, completion: @escaping (MeowPlannerTodayEntry) -> Void) {
        let snapshot = Self.currentSnapshot()
        let shouldUseSample = context.isPreview && snapshot == nil
        completion(makeEntry(date: Date(), snapshot: snapshot, includeSamplePlans: shouldUseSample))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<MeowPlannerTodayEntry>) -> Void) {
        let snapshot = Self.currentSnapshot()
        let entry = makeEntry(date: Date(), snapshot: snapshot)
        completion(Timeline(entries: [entry], policy: .after(Self.nextRefreshDate(after: entry.date))))
    }

    static func currentSnapshot() -> WidgetPlannerSnapshot? {
        WidgetPlannerSnapshotStore.loadFromFiles()
    }

    private func makeEntry(date: Date, snapshot: WidgetPlannerSnapshot?, includeSamplePlans: Bool = false) -> MeowPlannerTodayEntry {
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

        return MeowPlannerTodayEntry(
            date: date,
            visibleMonthDate: visibleMonthDate,
            scheduleCount: events.count,
            todoCount: todos.count,
            habitCount: includeSamplePlans ? 1 : (snapshot?.habitCount ?? 0),
            monthDays: monthDays,
            weekStartPreference: weekStartPreference,
            showChineseCalendar: includeSamplePlans ? true : (snapshot?.showChineseCalendar ?? true),
            completedSchedulesUseStrikethrough: includeSamplePlans ? true : (snapshot?.completedSchedulesUseStrikethrough ?? true)
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

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MeowPlannerTodayProvider()) { entry in
            MeowPlannerTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("MeowPlanner")
        .description("See FuFu's monthly schedules, todos, and habits.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct MeowPlannerTodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: MeowPlannerTodayEntry

    var body: some View {
        Group {
            switch family {
            case .systemLarge, .systemExtraLarge:
                MonthWidgetView(entry: entry, family: family)
            default:
                SummaryWidgetView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.94, blue: 0.86),
                    Color(red: 0.93, green: 0.97, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(WidgetConstants.appLaunchURL)
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

            Label("\(entry.scheduleCount) schedules", systemImage: "calendar")
            Label("\(entry.todoCount) todos", systemImage: "checklist")
            Label("\(entry.habitCount) habits", systemImage: "checkmark.seal")
        }
        .font(.caption)
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct MonthWidgetView: View {
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

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
                fufuPawWatermark

                VStack(alignment: .leading, spacing: verticalSpacing) {
                    monthHeader
                        .frame(height: headerHeight)
                        .zIndex(1)

                    calendarGrid(rowHeight: rowHeight, weekdayHeight: weekdayHeight)
                }
                .padding(outerPadding)
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

    private var completedEventPillOpacity: Double {
        usesFullColorRendering ? 0.52 : 0.76
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
            .foregroundStyle(WidgetPalette.cocoa)

            Label(monthTitle, systemImage: "pawprint.fill")
                .font((family == .systemExtraLarge ? Font.subheadline : Font.caption2).weight(.bold))
                .foregroundStyle(WidgetPalette.cocoa)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Button(intent: ChangeWidgetMonthIntent(monthDelta: 1)) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(WidgetPalette.cocoa)

            Spacer(minLength: 4)

            Button(intent: RefreshWidgetTimelineIntent()) {
                fufuWidgetMascot(size: family == .systemExtraLarge ? 20 : 16)
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
                .stroke(WidgetPalette.caramel.opacity(0.18), lineWidth: 1)
        }
    }

    private var weekdaySeparatorColor: Color {
        WidgetPalette.caramel.opacity(0.12)
    }

    private func weekdayHeaderCell(_ weekday: String, height: CGFloat) -> some View {
        Text(weekday)
            .font(.caption2.weight(.bold))
            .foregroundStyle(WidgetPalette.caramel)
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
                    .foregroundStyle(day.isInSelectedMonth ? WidgetPalette.cocoa : .secondary)

                if entry.showChineseCalendar {
                    Text(day.chineseCalendarInfo.displayText)
                        .font(.caption2.weight(day.chineseCalendarInfo.isFestival ? .bold : .medium))
                        .foregroundStyle(day.chineseCalendarInfo.isFestival ? WidgetPalette.blush : WidgetPalette.caramel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)
                }

                if calendar.isDateInToday(day.date) {
                    Circle()
                        .fill(WidgetPalette.blush)
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
                .fill(WidgetPalette.caramel.opacity(0.12))
                .frame(height: 1)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(WidgetPalette.caramel.opacity(0.12))
                .frame(width: 1)
        }
    }

    private func dayBackground(_ day: MonthPlannerDay) -> some ShapeStyle {
        if calendar.isDateInToday(day.date) {
            return AnyShapeStyle(WidgetPalette.blue.opacity(0.18))
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
                    .widgetAccentable(!usesFullColorRendering)
            }
            .opacity(item.isCompleted ? completedEventPillOpacity : 1)
    }

    private func eventPillTitleColor() -> some ShapeStyle {
        if usesFullColorRendering {
            return AnyShapeStyle(WidgetPalette.cocoa)
        }

        return AnyShapeStyle(Color.primary)
    }

    private func eventPillBackground(_ item: MonthPlannerItem) -> some ShapeStyle {
        if usesFullColorRendering {
            return AnyShapeStyle(
                widgetColor(
                    hex: item.colorHex,
                    fallback: item.kind == .event ? WidgetPalette.blue : WidgetPalette.caramel
                )
            )
        }

        return AnyShapeStyle(Color.primary.opacity(0.14))
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
                    .foregroundStyle(WidgetPalette.caramel.opacity(0.10))
                Spacer()
            }

            Spacer()

            HStack {
                Spacer()
                Image(systemName: "pawprint.fill")
                    .font(.system(size: family == .systemExtraLarge ? 92 : 56, weight: .bold))
                    .rotationEffect(.degrees(18))
                    .foregroundStyle(WidgetPalette.blue.opacity(0.10))
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
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.14)
                #else
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
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

private enum WidgetPalette {
    static let cream = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let cocoa = Color(red: 0.24, green: 0.15, blue: 0.10)
    static let caramel = Color(red: 0.68, green: 0.45, blue: 0.27)
    static let blue = Color(red: 0.18, green: 0.45, blue: 0.68)
    static let blush = Color(red: 0.88, green: 0.58, blue: 0.51)
}
