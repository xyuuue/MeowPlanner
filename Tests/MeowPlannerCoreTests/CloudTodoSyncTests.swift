import Foundation
import Testing
@testable import MeowPlannerCore

struct CloudTodoSyncTests {
    @Test("cloud todo record preserves local todo fields")
    func cloudTodoRecordPreservesLocalTodoFields() throws {
        let todoID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let groupID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let dueDate = Date(timeIntervalSince1970: 1_800)
        let completedAt = Date(timeIntervalSince1970: 2_400)
        let reminderDate = Date(timeIntervalSince1970: 1_200)
        let createdAt = Date(timeIntervalSince1970: 600)
        let updatedAt = Date(timeIntervalSince1970: 3_000)
        let todo = TodoItem(
            id: todoID,
            title: "Write Firestore sync",
            notes: "Ship the first cloud path",
            dueDate: dueDate,
            groupID: groupID,
            sortOrder: 3,
            isCompleted: true,
            completedAt: completedAt,
            reminderDate: reminderDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let record = CloudTodoRecord(todo: todo)

        #expect(record.id == todoID.uuidString)
        #expect(record.title == "Write Firestore sync")
        #expect(record.notes == "Ship the first cloud path")
        #expect(record.dueDate == dueDate)
        #expect(record.groupID == groupID.uuidString)
        #expect(record.sortOrder == 3)
        #expect(record.isCompleted)
        #expect(record.completedAt == completedAt)
        #expect(record.reminderDate == reminderDate)
        #expect(record.createdAt == createdAt)
        #expect(record.updatedAt == updatedAt)
        #expect(!record.isDeleted)

        let roundTrip = try record.todoItem()
        #expect(roundTrip.id == todoID)
        #expect(roundTrip.title == todo.title)
        #expect(roundTrip.notes == todo.notes)
        #expect(roundTrip.dueDate == todo.dueDate)
        #expect(roundTrip.groupID == todo.groupID)
        #expect(roundTrip.sortOrder == todo.sortOrder)
        #expect(roundTrip.isCompleted == todo.isCompleted)
        #expect(roundTrip.completedAt == todo.completedAt)
        #expect(roundTrip.reminderDate == todo.reminderDate)
        #expect(roundTrip.createdAt == todo.createdAt)
        #expect(roundTrip.updatedAt == todo.updatedAt)
    }

    @Test("cloud todo paths are scoped to the signed in Firebase user")
    func cloudTodoPathsAreScopedToSignedInFirebaseUser() throws {
        let todoID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000003"))

        #expect(try CloudTodoPath.todosCollectionPath(userID: " firebase-user-123 ") == "users/firebase-user-123/todos")
        #expect(try CloudTodoPath.todoDocumentPath(userID: "firebase-user-123", todoID: todoID) == "users/firebase-user-123/todos/\(todoID.uuidString)")
        #expect(throws: CloudTodoSyncError.invalidUserID) {
            try CloudTodoPath.todosCollectionPath(userID: " ")
        }
        #expect(throws: CloudTodoSyncError.invalidUserID) {
            try CloudTodoPath.todosCollectionPath(userID: "users/firebase-user-123")
        }
    }
}
