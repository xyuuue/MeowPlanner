import Foundation

public enum MonthPlannerItemKind: Sendable {
    case event
    case todo
}

public struct MonthPlannerItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let kind: MonthPlannerItemKind
    public let isCompleted: Bool
    public let tagName: String
    public let colorHex: String

    public init(
        id: UUID,
        title: String,
        kind: MonthPlannerItemKind,
        isCompleted: Bool,
        tagName: String = "",
        colorHex: String = PlannerPreference.defaultEventColorHexes[0]
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.isCompleted = isCompleted
        self.tagName = tagName
        self.colorHex = colorHex
    }
}

public struct MonthPlannerDay: Identifiable, Sendable, Equatable {
    public let date: Date
    public let isInSelectedMonth: Bool
    public let chineseCalendarInfo: ChineseCalendarDayInfo
    public let items: [MonthPlannerItem]
    public let overflowCount: Int

    public var id: Date { date }

    public init(
        date: Date,
        isInSelectedMonth: Bool,
        chineseCalendarInfo: ChineseCalendarDayInfo,
        items: [MonthPlannerItem],
        overflowCount: Int
    ) {
        self.date = date
        self.isInSelectedMonth = isInSelectedMonth
        self.chineseCalendarInfo = chineseCalendarInfo
        self.items = items
        self.overflowCount = overflowCount
    }
}

public enum MonthPlannerGridBuilder {
    public static func days(
        for selectedDate: Date,
        events: [PlannerEvent],
        todos: [TodoItem],
        maxVisibleItems: Int = 3,
        calendar: Calendar = .current
    ) -> [MonthPlannerDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1)) else {
            return []
        }

        var days: [MonthPlannerDay] = []
        var current = monthFirstWeek.start
        while current < monthLastWeek.end {
            let allItems = items(on: current, events: events, todos: todos, calendar: calendar)
            let visibleItems = Array(allItems.prefix(max(0, maxVisibleItems)))
            days.append(
                MonthPlannerDay(
                    date: current,
                    isInSelectedMonth: calendar.isDate(current, equalTo: selectedDate, toGranularity: .month),
                    chineseCalendarInfo: ChineseCalendarInfoProvider.info(for: current, calendar: calendar),
                    items: visibleItems,
                    overflowCount: max(0, allItems.count - visibleItems.count)
                )
            )
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? monthLastWeek.end
        }

        return days
    }

    private static func items(
        on date: Date,
        events: [PlannerEvent],
        todos: [TodoItem],
        calendar: Calendar
    ) -> [MonthPlannerItem] {
        let eventItems = events
            .compactMap { event -> (PlannerEvent, Date)? in
                guard let occurrenceDate = occurrenceDate(for: event, on: date, calendar: calendar) else {
                    return nil
                }
                return (event, occurrenceDate)
            }
            .sorted {
                if $0.0.isCompleted != $1.0.isCompleted {
                    return !$0.0.isCompleted
                }
                if isMultiDayAllDayEvent($0.0, calendar: calendar) != isMultiDayAllDayEvent($1.0, calendar: calendar) {
                    return !isMultiDayAllDayEvent($0.0, calendar: calendar)
                }
                return $0.1 < $1.1
            }
            .map { event, _ in
                MonthPlannerItem(
                    id: event.id,
                    title: event.title,
                    kind: .event,
                    isCompleted: event.isCompleted,
                    tagName: event.tagName,
                    colorHex: event.colorHex
                )
            }

        let matchingTodos = todos
            .filter {
                guard let dueDate = $0.dueDate else {
                    return false
                }
                return calendar.isDate(dueDate, inSameDayAs: date)
            }

        let todoItems = TodoListPlanner.visibleTodos(matchingTodos, filter: .all)
            .map {
                MonthPlannerItem(
                    id: $0.id,
                    title: $0.title,
                    kind: .todo,
                    isCompleted: $0.isCompleted,
                    tagName: "",
                    colorHex: "#B07A47"
                )
            }

        return eventItems + todoItems
    }

    private static func occurrenceDate(
        for event: PlannerEvent,
        on date: Date,
        calendar: Calendar
    ) -> Date? {
        event.occurs(on: date, calendar: calendar) ? event.startDate : nil
    }

    private static func isMultiDayAllDayEvent(_ event: PlannerEvent, calendar: Calendar) -> Bool {
        guard event.isAllDay,
              let endDate = event.endDate else {
            return false
        }

        return !calendar.isDate(event.startDate, inSameDayAs: endDate)
    }
}
