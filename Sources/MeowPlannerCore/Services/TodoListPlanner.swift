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
        let filteredTodos = todos
            .filter { todo in
                switch filter {
                case .all:
                    true
                case let .group(groupID):
                    todo.groupID == groupID
                }
            }

        if usesCustomOrdering(filteredTodos) {
            return filteredTodos.sorted(by: customTodoSort)
        }

        return filteredTodos.sorted(by: automaticTodoSort)
    }

    public static func usesCustomOrdering(_ todos: [TodoItem]) -> Bool {
        !todos.isEmpty && todos.allSatisfy { $0.sortOrder != nil }
    }

    public static func nextSortOrder(after todos: [TodoItem]) -> Int? {
        guard usesCustomOrdering(todos) else {
            return nil
        }

        return (todos.compactMap(\.sortOrder).max() ?? -1) + 1
    }

    @discardableResult
    public static func reorderedTodos(
        _ visibleTodos: [TodoItem],
        moving source: IndexSet,
        to destination: Int,
        at date: Date = Date()
    ) -> [TodoItem] {
        let reorderedTodos = reordered(visibleTodos, moving: source, to: destination)
        for (index, todo) in reorderedTodos.enumerated() {
            todo.sortOrder = index
            todo.updatedAt = date
        }
        return reorderedTodos
    }

    @discardableResult
    public static func reorderedTodosAfterCompletionChange(
        _ visibleTodos: [TodoItem],
        changedTodo: TodoItem,
        at date: Date = Date()
    ) -> [TodoItem] {
        var reorderedTodos = visibleTodos.filter { $0.id != changedTodo.id }
        let insertionIndex: Int

        if changedTodo.isCompleted {
            insertionIndex = reorderedTodos.count
        } else {
            insertionIndex = reorderedTodos.firstIndex(where: \.isCompleted) ?? reorderedTodos.count
        }

        reorderedTodos.insert(changedTodo, at: insertionIndex)
        for (index, todo) in reorderedTodos.enumerated() {
            todo.sortOrder = index
            todo.updatedAt = date
        }
        return reorderedTodos
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

    private static func automaticTodoSort(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
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

    private static func customTodoSort(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        switch (lhs.sortOrder, rhs.sortOrder) {
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

    private static func reordered(
        _ todos: [TodoItem],
        moving source: IndexSet,
        to destination: Int
    ) -> [TodoItem] {
        let sourceIndexes = Array(source).sorted()
        guard !sourceIndexes.isEmpty else {
            return todos
        }

        var movingTodos: [TodoItem] = []
        var remainingTodos: [TodoItem] = []

        for (index, todo) in todos.enumerated() {
            if source.contains(index) {
                movingTodos.append(todo)
            } else {
                remainingTodos.append(todo)
            }
        }

        let movedBeforeDestination = sourceIndexes.filter { $0 < destination }.count
        let insertionIndex = max(0, min(remainingTodos.count, destination - movedBeforeDestination))
        remainingTodos.insert(contentsOf: movingTodos, at: insertionIndex)
        return remainingTodos
    }
}
