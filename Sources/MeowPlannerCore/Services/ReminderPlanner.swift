import Foundation

public struct ReminderRequest: Equatable, Sendable {
    public var id: String
    public var title: String
    public var body: String
    public var fireDate: Date

    public init(id: String, title: String, body: String, fireDate: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.fireDate = fireDate
    }
}

public enum ReminderPlanner {
    public static func eventReminder(for event: PlannerEvent) -> ReminderRequest? {
        guard let fireDate = event.reminderDate else {
            return nil
        }

        return ReminderRequest(
            id: "event-\(event.id.uuidString)",
            title: event.title,
            body: "FuFu says it starts soon.",
            fireDate: fireDate
        )
    }

    public static func todoReminder(for todo: TodoItem) -> ReminderRequest? {
        guard let reminderDate = todo.reminderDate ?? todo.dueDate else {
            return nil
        }

        return ReminderRequest(
            id: "todo-\(todo.id.uuidString)",
            title: todo.title,
            body: "FuFu saved this todo for you.",
            fireDate: reminderDate
        )
    }
}
