import Foundation

public enum TodoGroupFilter: Hashable, Sendable {
    case all
    case group(UUID?)
}

public struct TodoGroupOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let filter: TodoGroupFilter

    public init(id: String, title: String, filter: TodoGroupFilter) {
        self.id = id
        self.title = title
        self.filter = filter
    }
}

public enum TodoListPlanner {
    public static func groupOptions(
        groups: [TodoGroup],
        allTitle: String,
        defaultTitle: String
    ) -> [TodoGroupOption] {
        let sortedGroups = groups.sorted {
            if $0.createdAt != $1.createdAt {
                return $0.createdAt < $1.createdAt
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        return [
            TodoGroupOption(id: "all", title: allTitle, filter: .all),
            TodoGroupOption(id: "default", title: defaultTitle, filter: .group(nil))
        ] + sortedGroups.map { group in
            TodoGroupOption(id: group.id.uuidString, title: group.name, filter: .group(group.id))
        }
    }

    public static func visibleTodos(
        _ todos: [TodoItem],
        filter: TodoGroupFilter
    ) -> [TodoItem] {
        todos
            .filter { todo in
                switch filter {
                case .all:
                    true
                case let .group(groupID):
                    todo.groupID == groupID
                }
            }
            .sorted(by: todoSort)
    }

    public static func groupName(
        for todo: TodoItem,
        groups: [TodoGroup],
        defaultName: String
    ) -> String {
        guard let groupID = todo.groupID,
              let group = groups.first(where: { $0.id == groupID }) else {
            return defaultName
        }

        return group.name
    }

    public static func groupColorHex(
        for todo: TodoItem,
        groups: [TodoGroup]
    ) -> String {
        guard let groupID = todo.groupID,
              let group = groups.first(where: { $0.id == groupID }) else {
            return TodoGroup.defaultColorHex
        }

        return group.colorHex
    }

    public static func normalizedSelection(
        _ filter: TodoGroupFilter,
        groups: [TodoGroup]
    ) -> TodoGroupFilter {
        switch filter {
        case .all, .group(nil):
            filter
        case let .group(groupID?):
            groups.contains { $0.id == groupID } ? filter : .all
        }
    }

    private static func todoSort(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }

        switch (lhs.dueDate, rhs.dueDate) {
        case let (left?, right?):
            if left != right {
                return left < right
            }
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            break
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}
