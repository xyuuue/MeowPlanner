import Foundation
import SwiftData

@Model
public final class TodoItem {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String
    public var dueDate: Date?
    public var groupID: UUID?
    public var sortOrder: Int?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var reminderDate: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        groupID: UUID? = nil,
        sortOrder: Int? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        reminderDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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
    }

    public func markCompleted(at date: Date = Date()) {
        isCompleted = true
        completedAt = date
        updatedAt = date
    }

    public func reopen(at date: Date = Date()) {
        isCompleted = false
        completedAt = nil
        updatedAt = date
    }
}
