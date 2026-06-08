import Foundation
import Testing
@testable import MeowPlannerCore

@Suite("Month planner grid")
struct MonthPlannerGridTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("month grid covers complete visible weeks around selected month")
    func monthGridCoversCompleteVisibleWeeks() throws {
        let days = MonthPlannerGridBuilder.days(
            for: try dateOnly("2026-06-15"),
            events: [],
            todos: [],
            calendar: calendar
        )

        #expect(days.count == 35)
        #expect(calendar.isDate(days.first?.date ?? Date.distantPast, inSameDayAs: try dateOnly("2026-05-31")))
        #expect(calendar.isDate(days.last?.date ?? Date.distantPast, inSameDayAs: try dateOnly("2026-07-04")))
        #expect(days.filter(\.isInSelectedMonth).count == 30)
        #expect(days.allSatisfy { !$0.chineseCalendarInfo.displayText.isEmpty })
    }

    @Test("month grid exposes Chinese calendar festival metadata")
    func monthGridExposesChineseCalendarFestivalMetadata() throws {
        let targetDate = try dateOnly("2026-06-19")
        let day = try #require(MonthPlannerGridBuilder.days(
            for: targetDate,
            events: [],
            todos: [],
            calendar: calendar
        ).first { calendar.isDate($0.date, inSameDayAs: targetDate) })

        #expect(day.chineseCalendarInfo.festivalName == "端午节")
        #expect(day.chineseCalendarInfo.displayText == "端午节")
    }

    @Test("month grid respects Monday week start preference")
    func monthGridRespectsMondayWeekStartPreference() throws {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = WeekStartPreference.monday.calendarFirstWeekday

        let days = MonthPlannerGridBuilder.days(
            for: try dateOnly("2026-06-15"),
            events: [],
            todos: [],
            calendar: mondayCalendar
        )

        #expect(days.count == 35)
        #expect(mondayCalendar.isDate(days.first?.date ?? Date.distantPast, inSameDayAs: try dateOnly("2026-06-01")))
        #expect(mondayCalendar.isDate(days.last?.date ?? Date.distantPast, inSameDayAs: try dateOnly("2026-07-05")))
    }

    @Test("week start preference orders weekday symbols without duplicate identity")
    func weekStartPreferenceOrdersWeekdaySymbols() {
        #expect(WeekStartPreference.sunday.orderedVeryShortWeekdaySymbols(calendar: calendar) == ["S", "M", "T", "W", "T", "F", "S"])
        #expect(WeekStartPreference.monday.orderedVeryShortWeekdaySymbols(calendar: calendar) == ["M", "T", "W", "T", "F", "S", "S"])
    }

    @Test("day summaries include visible event and todo titles with overflow")
    func daySummariesIncludeVisibleTitlesWithOverflow() throws {
        let targetDate = try dateOnly("2026-06-03")
        let events = [
            PlannerEvent(title: "Nail Repair", startDate: try date("2026-06-03 09:00"), tagName: "Beauty", colorHex: "#D8898A"),
            PlannerEvent(title: "1v1 20:00", startDate: try date("2026-06-03 20:00"))
        ]
        let todos = [
            TodoItem(title: "Buy coffee", dueDate: try date("2026-06-03 12:00")),
            TodoItem(title: "Plan FuFu", dueDate: try date("2026-06-03 13:00"))
        ]

        let day = try #require(MonthPlannerGridBuilder.days(
            for: targetDate,
            events: events,
            todos: todos,
            maxVisibleItems: 3,
            calendar: calendar
        ).first { calendar.isDate($0.date, inSameDayAs: targetDate) })

        #expect(day.items.map(\.title) == ["Nail Repair", "1v1 20:00", "Buy coffee"])
        #expect(day.items.first?.tagName == "Beauty")
        #expect(day.items.first?.colorHex == "#D8898A")
        #expect(day.overflowCount == 1)
    }

    @Test("completed month grid items sort after active items")
    func completedMonthGridItemsSortAfterActiveItems() throws {
        let targetDate = try dateOnly("2026-06-03")
        let completedEvent = PlannerEvent(title: "Done early", startDate: try date("2026-06-03 08:00"))
        completedEvent.markCompleted(at: try date("2026-06-03 08:30"))
        let activeEvent = PlannerEvent(title: "Active later", startDate: try date("2026-06-03 10:00"))
        let completedTodo = TodoItem(title: "Done todo", dueDate: try date("2026-06-03 09:00"))
        completedTodo.markCompleted(at: try date("2026-06-03 09:30"))
        let activeTodo = TodoItem(title: "Active todo", dueDate: try date("2026-06-03 11:00"))

        let day = try #require(MonthPlannerGridBuilder.days(
            for: targetDate,
            events: [completedEvent, activeEvent],
            todos: [completedTodo, activeTodo],
            maxVisibleItems: 4,
            calendar: calendar
        ).first { calendar.isDate($0.date, inSameDayAs: targetDate) })

        #expect(day.items.map(\.title) == ["Active later", "Done early", "Active todo", "Done todo"])
    }

    @Test("month grid expands repeating events into visible days")
    func monthGridExpandsRepeatingEventsIntoVisibleDays() throws {
        let event = PlannerEvent(
            title: "FuFu Review",
            startDate: try date("2026-06-01 09:00"),
            repeatRule: .weekly(interval: 1, weekdays: [2]),
            tagName: "工作",
            colorHex: "#71B7ED"
        )

        let days = MonthPlannerGridBuilder.days(
            for: try dateOnly("2026-06-15"),
            events: [event],
            todos: [],
            calendar: calendar
        )

        let visibleDates = days
            .filter { $0.items.contains { $0.title == "FuFu Review" } }
            .map(\.date)

        #expect(visibleDates.count == 5)
        #expect(visibleDates.contains { calendar.isDate($0, inSameDayAs: try! dateOnly("2026-06-01")) })
        #expect(visibleDates.contains { calendar.isDate($0, inSameDayAs: try! dateOnly("2026-06-29")) })
        #expect(days.flatMap(\.items).first?.tagName == "工作")
        #expect(days.flatMap(\.items).first?.colorHex == "#71B7ED")
    }

    @Test("month grid shows multi-day all-day events across date range")
    func monthGridShowsMultiDayAllDayEventsAcrossDateRange() throws {
        let event = PlannerEvent(
            title: "Conference",
            startDate: try date("2026-06-02 00:00"),
            endDate: try date("2026-06-04 23:59"),
            isAllDay: true,
            tagName: "工作",
            colorHex: "#84C3B7"
        )

        let days = MonthPlannerGridBuilder.days(
            for: try dateOnly("2026-06-15"),
            events: [event],
            todos: [],
            calendar: calendar
        )

        let visibleDates = days
            .filter { $0.items.contains { $0.title == "Conference" } }
            .map(\.date)

        #expect(visibleDates.count == 3)
        #expect(visibleDates.contains { calendar.isDate($0, inSameDayAs: try! dateOnly("2026-06-02")) })
        #expect(visibleDates.contains { calendar.isDate($0, inSameDayAs: try! dateOnly("2026-06-03")) })
        #expect(visibleDates.contains { calendar.isDate($0, inSameDayAs: try! dateOnly("2026-06-04")) })
        #expect(days.flatMap(\.items).first?.tagName == "工作")
        #expect(days.flatMap(\.items).first?.colorHex == "#84C3B7")
    }

    @Test("multi-day all-day events sort after single-day schedule items")
    func multiDayAllDayEventsSortAfterSingleDayScheduleItems() throws {
        let multiDayEvent = PlannerEvent(
            title: "Vacation",
            startDate: try date("2026-06-02 00:00"),
            endDate: try date("2026-06-04 23:59"),
            isAllDay: true,
            colorHex: "#F57C6E"
        )
        let timedEvent = PlannerEvent(
            title: "Go Valley 1v1",
            startDate: try date("2026-06-03 20:00"),
            endDate: try date("2026-06-03 21:00"),
            tagName: "学习",
            colorHex: "#71B7ED"
        )

        let day = try #require(MonthPlannerGridBuilder.days(
            for: try dateOnly("2026-06-15"),
            events: [multiDayEvent, timedEvent],
            todos: [],
            maxVisibleItems: 3,
            calendar: calendar
        ).first { calendar.isDate($0.date, inSameDayAs: try dateOnly("2026-06-03")) })

        #expect(day.items.map(\.title) == ["Go Valley 1v1", "Vacation"])
    }

    private func date(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try #require(formatter.date(from: value))
    }

    private func dateOnly(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return try #require(formatter.date(from: value))
    }
}
