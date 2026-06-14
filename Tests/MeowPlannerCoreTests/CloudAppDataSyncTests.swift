import Foundation
import Testing
@testable import MeowPlannerCore

struct CloudAppDataSyncTests {
    @Test("cloud app data collections cover every SwiftData model")
    func cloudAppDataCollectionsCoverEverySwiftDataModel() {
        #expect(CloudDataCollection.allCases.map(\.rawValue) == [
            "events",
            "todoGroups",
            "todos",
            "habits",
            "habitCheckIns",
            "focusTags",
            "focusSessions",
            "preferences",
            "courseTimetables",
            "coursePeriods",
            "courses",
            "courseSessions"
        ])
    }

    @Test("cloud app data paths are scoped under the signed in Firebase user")
    func cloudAppDataPathsAreScopedUnderSignedInFirebaseUser() throws {
        #expect(try CloudDataCollection.events.collectionPath(userID: " user-123 ") == "users/user-123/events")
        #expect(try CloudDataCollection.courseSessions.documentPath(userID: "user-123", documentID: "session-1") == "users/user-123/courseSessions/session-1")
        #expect(throws: CloudTodoSyncError.invalidUserID) {
            try CloudDataCollection.todos.collectionPath(userID: "")
        }
        #expect(throws: CloudTodoSyncError.invalidUserID) {
            try CloudDataCollection.todos.collectionPath(userID: "users/user-123")
        }
    }

    @Test("deletion tracker emits tombstones only for previously uploaded missing records")
    func deletionTrackerEmitsTombstonesOnlyForPreviouslyUploadedMissingRecords() {
        let previous: Set<String> = ["local-1", "local-2", "already-deleted"]
        let current: Set<String> = ["local-2", "new-local"]

        let missing = CloudDeletionTracker.missingUploadedDocumentIDs(
            previousUploadedIDs: previous,
            currentLocalIDs: current
        )

        #expect(missing == ["already-deleted", "local-1"])
    }

    @Test("merge keeps local records when the local update is newer")
    func mergeKeepsLocalRecordsWhenTheLocalUpdateIsNewer() {
        let localUpdatedAt = Date(timeIntervalSince1970: 2_000)
        let remoteUpdatedAt = Date(timeIntervalSince1970: 1_000)

        let shouldApplyRemote = CloudRecordMergeDecision.shouldApplyRemoteRecord(
            localUpdatedAt: localUpdatedAt,
            remoteUpdatedAt: remoteUpdatedAt
        )

        #expect(!shouldApplyRemote)
    }

    @Test("merge applies remote records when the remote update is newer")
    func mergeAppliesRemoteRecordsWhenTheRemoteUpdateIsNewer() {
        let localUpdatedAt = Date(timeIntervalSince1970: 1_000)
        let remoteUpdatedAt = Date(timeIntervalSince1970: 2_000)

        let shouldApplyRemote = CloudRecordMergeDecision.shouldApplyRemoteRecord(
            localUpdatedAt: localUpdatedAt,
            remoteUpdatedAt: remoteUpdatedAt
        )

        #expect(shouldApplyRemote)
    }

    @Test("merge keeps local records when remote deletion is older")
    func mergeKeepsLocalRecordsWhenRemoteDeletionIsOlder() {
        let localUpdatedAt = Date(timeIntervalSince1970: 2_000)
        let remoteUpdatedAt = Date(timeIntervalSince1970: 1_000)

        let shouldDeleteLocal = CloudRecordMergeDecision.shouldApplyRemoteDeletion(
            localUpdatedAt: localUpdatedAt,
            remoteUpdatedAt: remoteUpdatedAt
        )

        #expect(!shouldDeleteLocal)
    }

    @Test("merge keeps local preference tags when the local preference is newer")
    func mergeKeepsLocalPreferenceTagsWhenTheLocalPreferenceIsNewer() {
        let preference = PlannerPreference(
            eventTagNames: ["工作", "Coursera"],
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        let remoteUpdatedAt = Date(timeIntervalSince1970: 1_000)

        let shouldApplyRemote = CloudRecordMergeDecision.shouldApplyRemoteRecord(
            localUpdatedAt: preference.updatedAt,
            remoteUpdatedAt: remoteUpdatedAt
        )

        #expect(!shouldApplyRemote)
        #expect(preference.eventTagNames == ["工作", "Coursera"])
    }

    @Test("merge blocks remote records while local deletion is pending")
    func mergeBlocksRemoteRecordsWhileLocalDeletionIsPending() {
        let shouldApplyRemoteRecord = CloudRecordMergeDecision.shouldApplyRemoteRecord(
            localUpdatedAt: nil,
            remoteUpdatedAt: Date(timeIntervalSince1970: 2_000),
            isPendingLocalDeletion: true,
            remoteIsDeleted: false
        )

        let shouldApplyRemoteDeletion = CloudRecordMergeDecision.shouldApplyRemoteRecord(
            localUpdatedAt: nil,
            remoteUpdatedAt: Date(timeIntervalSince1970: 2_000),
            isPendingLocalDeletion: true,
            remoteIsDeleted: true
        )

        #expect(!shouldApplyRemoteRecord)
        #expect(shouldApplyRemoteDeletion)
    }

    @Test("synced user defaults keep newer local language selections")
    func syncedUserDefaultsKeepNewerLocalLanguageSelections() {
        let localLanguageUpdatedAt = Date(timeIntervalSince1970: 2_000)
        let remoteLanguageUpdatedAt = Date(timeIntervalSince1970: 1_000)

        #expect(!SyncedUserDefaultMergeDecision.shouldApplyRemoteValue(
            localUpdatedAt: localLanguageUpdatedAt,
            remoteUpdatedAt: remoteLanguageUpdatedAt
        ))
        #expect(SyncedUserDefaultMergeDecision.shouldApplyRemoteValue(
            localUpdatedAt: nil,
            remoteUpdatedAt: remoteLanguageUpdatedAt
        ))
    }

    @Test("synced user defaults keep newer local appearance selections")
    func syncedUserDefaultsKeepNewerLocalAppearanceSelections() {
        let localAppearanceUpdatedAt = Date(timeIntervalSince1970: 2_000)
        let remoteAppearanceUpdatedAt = Date(timeIntervalSince1970: 1_000)

        #expect(AppAppearancePreference.updatedAtStorageKey == "meowplanner.appearance.preference.updatedAt")
        #expect(!SyncedUserDefaultMergeDecision.shouldApplyRemoteValue(
            localUpdatedAt: localAppearanceUpdatedAt,
            remoteUpdatedAt: remoteAppearanceUpdatedAt
        ))
        #expect(SyncedUserDefaultMergeDecision.shouldApplyRemoteValue(
            localUpdatedAt: nil,
            remoteUpdatedAt: remoteAppearanceUpdatedAt
        ))
    }
}
