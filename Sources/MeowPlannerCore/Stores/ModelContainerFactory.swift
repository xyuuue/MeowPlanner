import Foundation
import SwiftData

public enum ModelContainerFactory {
    public static let cloudKitContainerIdentifier = "iCloud.com.yuelingqiu.MeowPlanner"

    public static var schema: Schema {
        Schema([
            PlannerEvent.self,
            TodoItem.self,
            TodoGroup.self,
            Habit.self,
            HabitCheckIn.self,
            FocusTag.self,
            FocusSession.self,
            PlannerPreference.self,
            CourseTimetable.self,
            CoursePeriod.self,
            Course.self,
            CourseSession.self
        ])
    }

    public static func make(
        inMemory: Bool = false,
        cloudKitEnabled: Bool = true
    ) throws -> ModelContainer {
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = if cloudKitEnabled && !inMemory {
            .private(cloudKitContainerIdentifier)
        } else {
            .none
        }
        let groupContainer: ModelConfiguration.GroupContainer = .none

        let configuration = ModelConfiguration(
            "MeowPlanner",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: groupContainer,
            cloudKitDatabase: cloudKitDatabase
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
