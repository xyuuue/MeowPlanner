import Foundation

public enum CourseTimetablePlanner {
    public static func defaultPeriods(
        for timetable: CourseTimetable,
        firstStartMinutes: Int = 9 * 60
    ) -> [CoursePeriod] {
        let firstStart = min(max(firstStartMinutes, 0), 1_439)
        var periods: [CoursePeriod] = []
        var start = firstStart

        for index in 1...timetable.periodsPerDay {
            guard start < 1_440 else { break }

            let end = min(start + timetable.lessonDurationMinutes, 1_440)
            guard end > start else { break }

            periods.append(CoursePeriod(
                timetableID: timetable.id,
                index: index,
                startMinutesFromMidnight: start,
                endMinutesFromMidnight: end
            ))
            start = end + timetable.breakDurationMinutes
        }

        return periods
    }

    public static func weekNumber(
        for date: Date,
        timetable: CourseTimetable,
        calendar: Calendar = .current
    ) -> Int {
        let semesterStart = semesterWeekStart(for: timetable, calendar: calendar)
        let targetDate = calendar.startOfDay(for: date)
        let elapsedDays = calendar.dateComponents([.day], from: semesterStart, to: targetDate).day ?? 0
        let week = (max(elapsedDays, 0) / 7) + 1
        return min(max(week, 1), timetable.semesterWeeks)
    }

    public static func weekDates(
        forWeek week: Int,
        timetable: CourseTimetable,
        calendar: Calendar = .current
    ) -> [Date] {
        let normalizedWeek = min(max(week, 1), timetable.semesterWeeks)
        let semesterStart = semesterWeekStart(for: timetable, calendar: calendar)
        let firstDayOffset = (normalizedWeek - 1) * 7
        guard let firstDay = calendar.date(byAdding: .day, value: firstDayOffset, to: semesterStart) else {
            return []
        }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstDay)
        }
    }

    private static func semesterWeekStart(
        for timetable: CourseTimetable,
        calendar: Calendar
    ) -> Date {
        let semesterStart = calendar.startOfDay(for: timetable.semesterStartDate)
        return calendar.dateInterval(of: .weekOfYear, for: semesterStart)?.start ?? semesterStart
    }
}
