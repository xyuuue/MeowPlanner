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
}
