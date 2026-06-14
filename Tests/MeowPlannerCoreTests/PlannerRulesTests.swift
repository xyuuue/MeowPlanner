import Foundation
import Testing
@testable import MeowPlannerCore

@Suite("Planner domain rules")
struct PlannerRulesTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test("daily repeat expands inclusive occurrences")
    func dailyRepeatExpandsInclusiveOccurrences() throws {
        let start = try date("2026-06-01 09:00")
        let end = try date("2026-06-05 09:00")
        let rule = RepeatRule.daily(interval: 2)

        let occurrences = rule.occurrences(startingAt: start, until: end, calendar: calendar)

        #expect(occurrences == [
            start,
            try date("2026-06-03 09:00"),
            try date("2026-06-05 09:00")
        ])
    }

    @Test("event reminder date is offset before start")
    func eventReminderDateIsOffsetBeforeStart() throws {
        let expectedReminderDate = try date("2026-06-01 14:10")
        let event = PlannerEvent(
            title: "Portfolio review",
            startDate: try date("2026-06-01 14:30"),
            endDate: try date("2026-06-01 15:30"),
            reminderOffsetMinutes: 20,
            tagName: "Portfolio",
            colorHex: "#7B8FD6"
        )

        #expect(event.reminderDate == expectedReminderDate)
        #expect(event.tagName == "Portfolio")
        #expect(event.colorHex == "#7B8FD6")
    }

    @Test("event defaults include FuFu tag color metadata")
    func eventDefaultsIncludeFuFuTagColorMetadata() throws {
        let event = PlannerEvent(title: "Nail Repair", startDate: try date("2026-06-01 09:00"))

        #expect(event.tagName.isEmpty)
        #expect(event.colorHex == "#F57C6E")
    }

    @Test("all-day event stores no end date and reports all-day summary")
    func allDayEventStoresNoEndDateAndReportsAllDaySummary() throws {
        let event = PlannerEvent(
            title: "Portfolio day",
            startDate: try date("2026-06-01 09:00"),
            endDate: try date("2026-06-01 17:00"),
            isAllDay: true
        )

        #expect(event.isAllDay)
        #expect(event.endDate == nil)
        #expect(event.timeSummary(calendar: calendar) == "全天计划")
    }

    @Test("multi-day all-day event keeps deadline date")
    func multiDayAllDayEventKeepsDeadlineDate() throws {
        let deadline = try date("2026-06-04 23:59")
        let event = PlannerEvent(
            title: "Trip planning",
            startDate: try date("2026-06-02 00:00"),
            endDate: deadline,
            isAllDay: true
        )

        #expect(event.isAllDay)
        #expect(event.endDate == deadline)
        #expect(event.timeSummary(calendar: calendar) == "全天计划")
    }

    @Test("todo completion stores completed date")
    func todoCompletionStoresCompletedDate() throws {
        let completedAt = try date("2026-06-01 18:00")
        let todo = TodoItem(title: "Plan FuFu widget", dueDate: try date("2026-06-02 09:00"))

        todo.markCompleted(at: completedAt)

        #expect(todo.isCompleted)
        #expect(todo.completedAt == completedAt)
    }

    @Test("habit streak counts consecutive days ending at reference date")
    func habitStreakCountsConsecutiveDays() throws {
        let checkIns = [
            HabitCheckIn(habitID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, date: try dateOnly("2026-05-30")),
            HabitCheckIn(habitID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, date: try dateOnly("2026-05-31")),
            HabitCheckIn(habitID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, date: try dateOnly("2026-06-01"))
        ]

        let streak = HabitStreakCalculator.currentStreak(
            from: checkIns,
            endingOn: try dateOnly("2026-06-01"),
            calendar: calendar
        )

        #expect(streak == 3)
    }

    @Test("focus timer reports elapsed active time without paused gap")
    func focusTimerReportsElapsedActiveTimeWithoutPausedGap() throws {
        var timer = FocusTimerState(durationSeconds: 1_500)
        timer.start(at: try date("2026-06-01 09:00"))
        timer.pause(at: try date("2026-06-01 09:05"))
        timer.resume(at: try date("2026-06-01 09:15"))

        #expect(timer.elapsedSeconds(at: try date("2026-06-01 09:20")) == 600)
        #expect(timer.remainingSeconds(at: try date("2026-06-01 09:20")) == 900)
    }

    @Test("default preferences match MeowPlanner product defaults")
    func defaultPreferencesMatchProductDefaults() {
        let preferences = PlannerPreference.defaults

        #expect(preferences.localeIdentifier == "en")
        #expect(preferences.defaultFocusMinutes == 25)
        #expect(preferences.weekStartPreference == .sunday)
        #expect(preferences.localRemindersEnabled)
        #expect(!preferences.defaultEventIsAllDay)
        #expect(preferences.showCompletedSchedules)
        #expect(preferences.completedSchedulesUseStrikethrough)
        #expect(preferences.showChineseCalendar)
        #expect(preferences.scheduleTimeCollapseEnabled)
        #expect(preferences.scheduleCollapsedStartHour == 0)
        #expect(preferences.scheduleCollapsedEndHour == 6)
        #expect(preferences.timeDisplayPreference == .twentyFourHour)
        #expect(preferences.eventTagNames == [
            "工作",
            "生活",
            "旅行",
            "学习",
            "作业"
        ])
        #expect(preferences.eventColorHexes == [
            "#F57C6E",
            "#F2B56F",
            "#FAE69E",
            "#84C3B7",
            "#88D8DB",
            "#71B7ED",
            "#B8AEEB",
            "#F2A7DA"
        ])
        #expect(preferences.cloudKitContainerIdentifier == "iCloud.com.yuelingqiu.MeowPlanner")
        #expect(preferences.showFuFuTheme)
    }

    @Test("event tag options include tags already assigned to schedules")
    func eventTagOptionsIncludeTagsAlreadyAssignedToSchedules() {
        let options = PlannerPreference.eventTagOptions(
            configuredTags: ["工作", "学习"],
            assignedTagNames: [" Coursera ", "工作", ""]
        )

        #expect(options == ["工作", "学习", "Coursera"])
    }

    @Test("course timetable generates default class periods")
    func courseTimetableGeneratesDefaultClassPeriods() throws {
        let timetable = CourseTimetable(
            name: "Spring 2026",
            semesterStartDate: try date("2026-01-20 00:00"),
            semesterWeeks: 16,
            periodsPerDay: 3,
            lessonDurationMinutes: 90,
            breakDurationMinutes: 10
        )

        let periods = CourseTimetablePlanner.defaultPeriods(for: timetable, firstStartMinutes: 9 * 60)

        #expect(periods.count == 3)
        #expect(periods[0].index == 1)
        #expect(periods[0].startMinutesFromMidnight == 540)
        #expect(periods[0].endMinutesFromMidnight == 630)
        #expect(periods[1].startMinutesFromMidnight == 640)
        #expect(periods[2].endMinutesFromMidnight == 830)
    }

    @Test("course timetable defaults match setup defaults")
    func courseTimetableDefaultsMatchSetupDefaults() throws {
        let timetable = CourseTimetable(
            name: "   ",
            semesterStartDate: try date("2026-01-20 00:00")
        )
        let session = CourseSession(
            courseID: UUID(),
            weekday: 3,
            startPeriodIndex: 2,
            endPeriodIndex: 3
        )

        #expect(timetable.name == "Spring 2026")
        #expect(timetable.semesterWeeks == 16)
        #expect(timetable.periodsPerDay == 6)
        #expect(timetable.lessonDurationMinutes == 90)
        #expect(timetable.breakDurationMinutes == 10)
        #expect(timetable.skipHolidays)
        #expect(session.startWeek == 1)
        #expect(session.endWeek == 16)
    }

    @Test("course timetable normalizes out-of-range values")
    func courseTimetableNormalizesOutOfRangeValues() throws {
        let timetable = CourseTimetable(
            name: "Summer",
            semesterStartDate: try date("2026-01-20 00:00"),
            semesterWeeks: 99,
            periodsPerDay: 99,
            lessonDurationMinutes: 999,
            breakDurationMinutes: 999
        )
        let period = CoursePeriod(
            timetableID: timetable.id,
            index: -3,
            startMinutesFromMidnight: -200,
            endMinutesFromMidnight: -100
        )
        let session = CourseSession(
            courseID: UUID(),
            weekday: 99,
            startPeriodIndex: -4,
            endPeriodIndex: -1,
            startWeek: -2,
            endWeek: -1
        )

        #expect(timetable.semesterWeeks == 30)
        #expect(timetable.periodsPerDay == 12)
        #expect(timetable.lessonDurationMinutes == 240)
        #expect(timetable.breakDurationMinutes == 120)
        #expect(period.index == 1)
        #expect(period.startMinutesFromMidnight == 0)
        #expect(period.endMinutesFromMidnight == 1)
        #expect(session.weekday == 7)
        #expect(session.startPeriodIndex == 1)
        #expect(session.endPeriodIndex == 1)
        #expect(session.startWeek == 1)
        #expect(session.endWeek == 1)
    }

    @Test("course timetable period generation stops before overflowing day")
    func courseTimetablePeriodGenerationStopsBeforeOverflowingDay() throws {
        let timetable = CourseTimetable(
            name: "Long day",
            semesterStartDate: try date("2026-01-20 00:00"),
            semesterWeeks: 16,
            periodsPerDay: 12,
            lessonDurationMinutes: 240,
            breakDurationMinutes: 120
        )

        let periods = CourseTimetablePlanner.defaultPeriods(for: timetable, firstStartMinutes: 20 * 60)

        #expect(periods.count == 1)
        #expect(periods[0].startMinutesFromMidnight == 1_200)
        #expect(periods[0].endMinutesFromMidnight == 1_440)
    }

    @Test("course session is visible only inside its week range")
    func courseSessionVisibilityFollowsWeekRange() {
        let session = CourseSession(
            courseID: UUID(),
            weekday: 4,
            startPeriodIndex: 1,
            endPeriodIndex: 2,
            startWeek: 3,
            endWeek: 8
        )

        #expect(session.isVisible(inWeek: 3))
        #expect(session.isVisible(inWeek: 8))
        #expect(!session.isVisible(inWeek: 2))
        #expect(!session.isVisible(inWeek: 9))
    }

    @Test("course timetable calculates semester week")
    func courseTimetableCalculatesSemesterWeek() throws {
        let timetable = CourseTimetable(
            name: "Spring 2026",
            semesterStartDate: try date("2026-01-20 00:00"),
            semesterWeeks: 16
        )

        #expect(CourseTimetablePlanner.weekNumber(for: try date("2026-01-20 12:00"), timetable: timetable, calendar: calendar) == 1)
        #expect(CourseTimetablePlanner.weekNumber(for: try date("2026-01-27 12:00"), timetable: timetable, calendar: calendar) == 2)
        #expect(CourseTimetablePlanner.weekNumber(for: try date("2026-05-25 12:00"), timetable: timetable, calendar: calendar) == 16)
    }

    @Test("course timetable week dates start from calendar week start")
    func courseTimetableWeekDatesStartFromCalendarWeekStart() throws {
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let timetable = CourseTimetable(
            name: "Fall 2026",
            semesterStartDate: try date("2026-09-02 09:00"),
            semesterWeeks: 16
        )

        let firstWeekDates = CourseTimetablePlanner.weekDates(forWeek: 1, timetable: timetable, calendar: utcCalendar)
        let secondWeekDates = CourseTimetablePlanner.weekDates(forWeek: 2, timetable: timetable, calendar: utcCalendar)
        let expectedSecondWeekStart = try dateOnly("2026-09-06")

        #expect(firstWeekDates.map { utcCalendar.startOfDay(for: $0) } == [
            try dateOnly("2026-08-30"),
            try dateOnly("2026-08-31"),
            try dateOnly("2026-09-01"),
            try dateOnly("2026-09-02"),
            try dateOnly("2026-09-03"),
            try dateOnly("2026-09-04"),
            try dateOnly("2026-09-05")
        ])
        #expect(secondWeekDates.first.map { utcCalendar.startOfDay(for: $0) } == expectedSecondWeekStart)
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
