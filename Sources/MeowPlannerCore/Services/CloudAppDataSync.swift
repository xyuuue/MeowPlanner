import Foundation

public enum CloudDataCollection: String, CaseIterable, Identifiable, Sendable {
    case events
    case todoGroups
    case todos
    case habits
    case habitCheckIns
    case focusTags
    case focusSessions
    case preferences
    case courseTimetables
    case coursePeriods
    case courses
    case courseSessions

    public var id: String { rawValue }

    public func collectionPath(userID: String) throws -> String {
        let userID = try Self.normalizedUserID(userID)
        return "users/\(userID)/\(rawValue)"
    }

    public func documentPath(userID: String, documentID: String) throws -> String {
        let trimmedDocumentID = documentID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDocumentID.isEmpty, !trimmedDocumentID.contains("/") else {
            throw CloudTodoSyncError.invalidTodoID(documentID)
        }
        return "\(try collectionPath(userID: userID))/\(trimmedDocumentID)"
    }

    private static func normalizedUserID(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("/") else {
            throw CloudTodoSyncError.invalidUserID
        }
        return trimmed
    }
}

public enum CloudDeletionTracker {
    public static func missingUploadedDocumentIDs(
        previousUploadedIDs: Set<String>,
        currentLocalIDs: Set<String>
    ) -> [String] {
        previousUploadedIDs
            .subtracting(currentLocalIDs)
            .sorted()
    }
}

public enum CloudRecordMergeDecision {
    public static func shouldApplyRemoteRecord(
        localUpdatedAt: Date?,
        remoteUpdatedAt: Date?,
        isPendingLocalDeletion: Bool = false,
        remoteIsDeleted: Bool = false
    ) -> Bool {
        if isPendingLocalDeletion && !remoteIsDeleted {
            return false
        }

        guard let localUpdatedAt else {
            return true
        }

        guard let remoteUpdatedAt else {
            return false
        }

        return remoteUpdatedAt >= localUpdatedAt
    }

    public static func shouldApplyRemoteDeletion(
        localUpdatedAt: Date?,
        remoteUpdatedAt: Date?
    ) -> Bool {
        shouldApplyRemoteRecord(
            localUpdatedAt: localUpdatedAt,
            remoteUpdatedAt: remoteUpdatedAt
        )
    }
}

public enum SyncedUserDefaultMergeDecision {
    public static func shouldApplyRemoteValue(localUpdatedAt: Date?, remoteUpdatedAt: Date?) -> Bool {
        CloudRecordMergeDecision.shouldApplyRemoteRecord(
            localUpdatedAt: localUpdatedAt,
            remoteUpdatedAt: remoteUpdatedAt
        )
    }
}
