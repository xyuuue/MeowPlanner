import Foundation
import SwiftData

public enum ModelContainerFactoryError: Error, Equatable {
    case invalidAccountID
    case missingApplicationSupportDirectory
}

public enum ModelContainerFactory {
    public static let cloudKitContainerIdentifier = "iCloud.com.yuelingqiu.MeowPlanner"
    private static let accountStoreDirectoryName = "AccountStores"

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
        cloudKitEnabled: Bool = true,
        accountID: String? = nil,
        accountStoreBaseDirectory: URL? = nil
    ) throws -> ModelContainer {
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = if cloudKitEnabled && !inMemory {
            .private(cloudKitContainerIdentifier)
        } else {
            .none
        }
        let configuration: ModelConfiguration

        if let accountID, !inMemory {
            let storeURL = try accountStoreURL(for: accountID, baseDirectory: accountStoreBaseDirectory)
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            configuration = ModelConfiguration(
                "MeowPlanner-\(try normalizedAccountStoreName(for: accountID))",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: cloudKitDatabase
            )
        } else {
            let groupContainer: ModelConfiguration.GroupContainer = .none

            configuration = ModelConfiguration(
                "MeowPlanner",
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                groupContainer: groupContainer,
                cloudKitDatabase: cloudKitDatabase
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func makeAccountScoped(
        for userID: String,
        inMemory: Bool = false,
        cloudKitEnabled: Bool = false,
        baseDirectory: URL? = nil
    ) throws -> ModelContainer {
        try make(
            inMemory: inMemory,
            cloudKitEnabled: cloudKitEnabled,
            accountID: userID,
            accountStoreBaseDirectory: baseDirectory
        )
    }

    public static func makeSignedOutWorkspace() throws -> ModelContainer {
        try make(inMemory: true, cloudKitEnabled: false)
    }

    public static func accountStoreURL(for userID: String, baseDirectory: URL? = nil) throws -> URL {
        let baseDirectory = try baseDirectory ?? defaultAccountStoreBaseDirectory()
        let accountStoreName = try normalizedAccountStoreName(for: userID)
        return baseDirectory.appendingPathComponent("\(accountStoreName).store", isDirectory: false)
    }

    private static func normalizedAccountStoreName(for userID: String) throws -> String {
        let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ModelContainerFactoryError.invalidAccountID
        }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = trimmed.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : "_"
        }
        let sanitized = String(scalars)
            .split(separator: "_", omittingEmptySubsequences: true)
            .joined(separator: "_")

        guard !sanitized.isEmpty else {
            throw ModelContainerFactoryError.invalidAccountID
        }

        return sanitized
    }

    private static func defaultAccountStoreBaseDirectory() throws -> URL {
        guard let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw ModelContainerFactoryError.missingApplicationSupportDirectory
        }

        return applicationSupportDirectory
            .appendingPathComponent("MeowPlanner", isDirectory: true)
            .appendingPathComponent(accountStoreDirectoryName, isDirectory: true)
    }
}
