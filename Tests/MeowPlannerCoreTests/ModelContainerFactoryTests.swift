import Foundation
import SwiftData
import Testing
@testable import MeowPlannerCore

@Suite("Model container factory")
struct ModelContainerFactoryTests {
    @Test("in-memory container can store planner defaults")
    func inMemoryContainerCanStorePlannerDefaults() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let preferences = PlannerPreference.defaults

        context.insert(preferences)
        try context.save()

        let descriptor = FetchDescriptor<PlannerPreference>()
        let saved = try context.fetch(descriptor)
        #expect(saved.first?.cloudKitContainerIdentifier == "iCloud.com.yuelingqiu.MeowPlanner")
    }

    @Test("in-memory container can store course timetable models")
    func inMemoryContainerCanStoreCourseTimetableModels() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let timetable = CourseTimetable(
            name: "Spring 2026",
            semesterStartDate: Date(timeIntervalSince1970: 0)
        )
        let period = CoursePeriod(
            timetableID: timetable.id,
            index: 1,
            startMinutesFromMidnight: 9 * 60,
            endMinutesFromMidnight: 10 * 60 + 30
        )
        let course = Course(
            timetableID: timetable.id,
            name: "METCS 555",
            colorHex: "#F57C6E",
            teacherName: "Guanglan Zhang",
            location: "COM 217"
        )
        let session = CourseSession(
            courseID: course.id,
            weekday: 4,
            startPeriodIndex: 1,
            endPeriodIndex: 1
        )

        context.insert(timetable)
        context.insert(period)
        context.insert(course)
        context.insert(session)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<CourseTimetable>()).first?.name == "Spring 2026")
        #expect(try context.fetch(FetchDescriptor<CoursePeriod>()).first?.timetableID == timetable.id)
        #expect(try context.fetch(FetchDescriptor<Course>()).first?.teacherName == "Guanglan Zhang")
        #expect(try context.fetch(FetchDescriptor<CourseSession>()).first?.weekday == 4)
    }
}
