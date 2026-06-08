import Foundation
import SwiftData

@Model
public final class CourseTimetable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var semesterStartDate: Date
    public var semesterWeeks: Int
    public var periodsPerDay: Int
    public var lessonDurationMinutes: Int
    public var breakDurationMinutes: Int
    public var skipHolidays: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        semesterStartDate: Date,
        semesterWeeks: Int = 16,
        periodsPerDay: Int = 6,
        lessonDurationMinutes: Int = 90,
        breakDurationMinutes: Int = 10,
        skipHolidays: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = normalizedName.isEmpty ? "Spring 2026" : normalizedName
        self.semesterStartDate = semesterStartDate
        self.semesterWeeks = min(max(semesterWeeks, 1), 30)
        self.periodsPerDay = min(max(periodsPerDay, 1), 12)
        self.lessonDurationMinutes = min(max(lessonDurationMinutes, 15), 240)
        self.breakDurationMinutes = min(max(breakDurationMinutes, 0), 120)
        self.skipHolidays = skipHolidays
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class CoursePeriod {
    @Attribute(.unique) public var id: UUID
    public var timetableID: UUID
    public var index: Int
    public var startMinutesFromMidnight: Int
    public var endMinutesFromMidnight: Int

    public init(
        id: UUID = UUID(),
        timetableID: UUID,
        index: Int,
        startMinutesFromMidnight: Int,
        endMinutesFromMidnight: Int
    ) {
        self.id = id
        self.timetableID = timetableID
        self.index = max(index, 1)
        let normalizedStart = min(max(startMinutesFromMidnight, 0), 1_439)
        self.startMinutesFromMidnight = normalizedStart
        self.endMinutesFromMidnight = min(max(endMinutesFromMidnight, normalizedStart + 1), 1_440)
    }
}

@Model
public final class Course {
    @Attribute(.unique) public var id: UUID
    public var timetableID: UUID
    public var name: String
    public var colorHex: String
    public var teacherName: String
    public var location: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        timetableID: UUID,
        name: String,
        colorHex: String = PlannerPreference.defaultEventColorHexes[0],
        teacherName: String = "",
        location: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.timetableID = timetableID
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.colorHex = colorHex
        self.teacherName = teacherName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class CourseSession {
    @Attribute(.unique) public var id: UUID
    public var courseID: UUID
    public var weekday: Int
    public var startPeriodIndex: Int
    public var endPeriodIndex: Int
    public var startWeek: Int
    public var endWeek: Int

    public init(
        id: UUID = UUID(),
        courseID: UUID,
        weekday: Int,
        startPeriodIndex: Int,
        endPeriodIndex: Int,
        startWeek: Int = 1,
        endWeek: Int = 16
    ) {
        self.id = id
        self.courseID = courseID
        self.weekday = min(max(weekday, 1), 7)
        let normalizedStartPeriod = max(startPeriodIndex, 1)
        self.startPeriodIndex = normalizedStartPeriod
        self.endPeriodIndex = max(endPeriodIndex, normalizedStartPeriod)
        let normalizedStartWeek = max(startWeek, 1)
        self.startWeek = normalizedStartWeek
        self.endWeek = max(endWeek, normalizedStartWeek)
    }

    public func isVisible(inWeek week: Int) -> Bool {
        week >= startWeek && week <= endWeek
    }
}
