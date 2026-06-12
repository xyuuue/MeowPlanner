import Foundation

public enum CloudTodoSyncError: Error, Equatable, Sendable {
    case invalidUserID
    case invalidTodoID(String)
    case invalidGroupID(String)
}

public enum CloudTodoPath {
    public static func todosCollectionPath(userID: String) throws -> String {
        let userID = try normalizedUserID(userID)
        return "users/\(userID)/todos"
    }

    public static func todoDocumentPath(userID: String, todoID: UUID) throws -> String {
        "\(try todosCollectionPath(userID: userID))/\(todoID.uuidString)"
    }

    private static func normalizedUserID(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("/") else {
            throw CloudTodoSyncError.invalidUserID
        }
        return trimmed
    }
}

public struct CloudTodoRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var notes: String
    public var dueDate: Date?
    public var groupID: String?
    public var sortOrder: Int?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var reminderDate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var isDeleted: Bool

    public init(
        id: String,
        title: String,
        notes: String,
        dueDate: Date?,
        groupID: String?,
        sortOrder: Int?,
        isCompleted: Bool,
        completedAt: Date?,
        reminderDate: Date?,
        createdAt: Date,
        updatedAt: Date,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.groupID = groupID
        self.sortOrder = sortOrder
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.reminderDate = reminderDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }

    public init(todo: TodoItem, isDeleted: Bool = false) {
        self.init(
            id: todo.id.uuidString,
            title: todo.title,
            notes: todo.notes,
            dueDate: todo.dueDate,
            groupID: todo.groupID?.uuidString,
            sortOrder: todo.sortOrder,
            isCompleted: todo.isCompleted,
            completedAt: todo.completedAt,
            reminderDate: todo.reminderDate,
            createdAt: todo.createdAt,
            updatedAt: todo.updatedAt,
            isDeleted: isDeleted
        )
    }

    public func todoID() throws -> UUID {
        guard let uuid = UUID(uuidString: id) else {
            throw CloudTodoSyncError.invalidTodoID(id)
        }
        return uuid
    }

    public func todoItem() throws -> TodoItem {
        let itemID = try todoID()
        let groupUUID: UUID?
        if let groupID {
            guard let uuid = UUID(uuidString: groupID) else {
                throw CloudTodoSyncError.invalidGroupID(groupID)
            }
            groupUUID = uuid
        } else {
            groupUUID = nil
        }

        return TodoItem(
            id: itemID,
            title: title,
            notes: notes,
            dueDate: dueDate,
            groupID: groupUUID,
            sortOrder: sortOrder,
            isCompleted: isCompleted,
            completedAt: completedAt,
            reminderDate: reminderDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
