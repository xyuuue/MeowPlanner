import Foundation
import SwiftData
import Testing
@testable import MeowPlannerCore

@Suite("Todo grouping")
struct TodoGroupingTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("todo groups and todo group identifiers persist in SwiftData")
    func todoGroupsAndTodoGroupIdentifiersPersist() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let group = TodoGroup(name: "Homework", colorHex: "#71B7ED", createdAt: try date("2026-06-02 09:00"))
        let todo = TodoItem(
            title: "Finish METCS 555 homework",
            dueDate: try date("2026-06-03 12:00"),
            groupID: group.id,
            createdAt: try date("2026-06-02 09:30")
        )

        context.insert(group)
        context.insert(todo)
        try context.save()

        let savedGroup = try #require(try context.fetch(FetchDescriptor<TodoGroup>()).first)
        let savedTodo = try #require(try context.fetch(FetchDescriptor<TodoItem>()).first)

        #expect(savedGroup.name == "Homework")
        #expect(savedGroup.colorHex == "#71B7ED")
        #expect(savedTodo.groupID == savedGroup.id)
    }

    @Test("todo planner filters all default and custom groups")
    func todoPlannerFiltersAllDefaultAndCustomGroups() throws {
        let homework = TodoGroup(name: "Homework", createdAt: try date("2026-06-02 09:00"))
        let life = TodoGroup(name: "Life", createdAt: try date("2026-06-02 10:00"))
        let defaultTodo = TodoItem(title: "Default task", dueDate: nil, createdAt: try date("2026-06-02 11:00"))
        let homeworkTodo = TodoItem(title: "Homework task", dueDate: try date("2026-06-03 11:00"), groupID: homework.id, createdAt: try date("2026-06-02 12:00"))
        let lifeTodo = TodoItem(title: "Life task", dueDate: try date("2026-06-03 10:00"), groupID: life.id, createdAt: try date("2026-06-02 13:00"))
        lifeTodo.markCompleted(at: try date("2026-06-03 10:30"))
        let todos = [defaultTodo, homeworkTodo, lifeTodo]

        #expect(TodoListPlanner.visibleTodos(todos, filter: .all).map(\.title) == [
            "Homework task",
            "Default task",
            "Life task"
        ])
        #expect(TodoListPlanner.visibleTodos(todos, filter: .group(homework.id)).map(\.title) == ["Homework task"])
        #expect(TodoListPlanner.visibleTodos(todos, filter: .group(nil)).map(\.title) == ["Default task"])
        #expect(TodoListPlanner.groupName(for: defaultTodo, groups: [homework, life], defaultName: "Default") == "Default")
        #expect(TodoListPlanner.groupName(for: homeworkTodo, groups: [homework, life], defaultName: "Default") == "Homework")
        #expect(TodoListPlanner.groupColorHex(for: defaultTodo, groups: [homework, life]) == TodoGroup.defaultColorHex)
        #expect(TodoListPlanner.groupColorHex(for: homeworkTodo, groups: [homework, life]) == homework.colorHex)
    }

    @Test("todo planner keeps automatic ordering before custom sorting")
    func todoPlannerKeepsAutomaticOrderingBeforeCustomSorting() throws {
        let later = TodoItem(title: "Later", dueDate: try date("2026-06-03 12:00"), createdAt: try date("2026-06-02 09:00"))
        let sooner = TodoItem(title: "Sooner", dueDate: try date("2026-06-03 09:00"), createdAt: try date("2026-06-02 10:00"))
        let anytime = TodoItem(title: "Anytime", dueDate: nil, createdAt: try date("2026-06-02 08:00"))
        let completed = TodoItem(title: "Completed", dueDate: try date("2026-06-03 08:00"), createdAt: try date("2026-06-02 07:00"))
        completed.markCompleted(at: try date("2026-06-02 13:00"))

        let visible = TodoListPlanner.visibleTodos([anytime, completed, later, sooner], filter: .all)

        #expect(visible.map(\.title) == ["Sooner", "Later", "Anytime", "Completed"])
        #expect(visible.allSatisfy { $0.sortOrder == nil })
    }

    @Test("custom todo ordering persists and drives visible order")
    func customTodoOrderingPersistsAndDrivesVisibleOrder() throws {
        let container = try ModelContainerFactory.make(inMemory: true, cloudKitEnabled: false)
        let context = ModelContext(container)
        let customOrderDate = try date("2026-06-02 15:00")
        let homework = TodoItem(title: "Homework", dueDate: try date("2026-06-03 09:00"), createdAt: try date("2026-06-02 09:00"))
        let pack = TodoItem(title: "Pack bag", dueDate: try date("2026-06-03 10:00"), createdAt: try date("2026-06-02 10:00"))
        let email = TodoItem(title: "Email advisor", dueDate: nil, createdAt: try date("2026-06-02 11:00"))

        context.insert(homework)
        context.insert(pack)
        context.insert(email)
        try context.save()

        let automaticOrder = TodoListPlanner.visibleTodos([pack, email, homework], filter: .all)
        #expect(automaticOrder.map(\.title) == ["Homework", "Pack bag", "Email advisor"])

        let reordered = TodoListPlanner.reorderedTodos(
            automaticOrder,
            moving: IndexSet(integer: 2),
            to: 0,
            at: customOrderDate
        )
        try context.save()

        #expect(reordered.map(\.title) == ["Email advisor", "Homework", "Pack bag"])

        let savedTodos = try context.fetch(FetchDescriptor<TodoItem>())
        let visibleAfterSave = TodoListPlanner.visibleTodos(savedTodos, filter: .all)

        #expect(visibleAfterSave.map(\.title) == ["Email advisor", "Homework", "Pack bag"])
        #expect(visibleAfterSave.map(\.sortOrder) == [0, 1, 2])
        #expect(visibleAfterSave.allSatisfy { $0.updatedAt == customOrderDate })
    }

    @Test("completing a todo moves it to the bottom and starts custom ordering")
    func completingTodoMovesItToBottomAndStartsCustomOrdering() throws {
        let completedAt = try date("2026-06-02 16:00")
        let project = TodoItem(title: "Project draft", dueDate: try date("2026-06-03 09:00"), createdAt: try date("2026-06-02 09:00"))
        let pack = TodoItem(title: "Pack bag", dueDate: try date("2026-06-03 10:00"), createdAt: try date("2026-06-02 10:00"))
        let email = TodoItem(title: "Email advisor", dueDate: nil, createdAt: try date("2026-06-02 11:00"))
        let visible = TodoListPlanner.visibleTodos([email, pack, project], filter: .all)

        project.markCompleted(at: completedAt)
        let reordered = TodoListPlanner.reorderedTodosAfterCompletionChange(
            visible,
            changedTodo: project,
            at: completedAt
        )

        #expect(reordered.map(\.title) == ["Pack bag", "Email advisor", "Project draft"])
        #expect(reordered.map(\.sortOrder) == [0, 1, 2])
        #expect(reordered.allSatisfy { $0.updatedAt == completedAt })
    }

    @Test("reopening a completed todo moves it to the end of the active area")
    func reopeningCompletedTodoMovesItToEndOfActiveArea() throws {
        let reopenedAt = try date("2026-06-02 17:00")
        let active = TodoItem(title: "Active task", sortOrder: 0, createdAt: try date("2026-06-02 09:00"))
        let reopened = TodoItem(title: "Reopened task", sortOrder: 1, isCompleted: true, completedAt: try date("2026-06-02 12:00"), createdAt: try date("2026-06-02 10:00"))
        let completed = TodoItem(title: "Completed task", sortOrder: 2, isCompleted: true, completedAt: try date("2026-06-02 13:00"), createdAt: try date("2026-06-02 11:00"))
        let visible = TodoListPlanner.visibleTodos([completed, reopened, active], filter: .all)

        reopened.reopen(at: reopenedAt)
        let reordered = TodoListPlanner.reorderedTodosAfterCompletionChange(
            visible,
            changedTodo: reopened,
            at: reopenedAt
        )

        #expect(reordered.map(\.title) == ["Active task", "Reopened task", "Completed task"])
        #expect(reordered.map(\.sortOrder) == [0, 1, 2])
        #expect(reordered.allSatisfy { $0.updatedAt == reopenedAt })
    }

    @Test("todo group display order starts with all and default")
    func todoGroupDisplayOrderStartsWithAllAndDefault() throws {
        let homework = TodoGroup(name: "Homework", createdAt: try date("2026-06-02 10:00"))
        let life = TodoGroup(name: "Life", createdAt: try date("2026-06-02 09:00"))

        let options = TodoListPlanner.groupOptions(
            groups: [homework, life],
            allTitle: "All",
            defaultTitle: "Default"
        )

        #expect(options.map(\.title) == ["All", "Default", "Life", "Homework"])
        #expect(options.map(\.filter) == [.all, .group(nil), .group(life.id), .group(homework.id)])
    }

    @Test("deleting a todo group moves its todos to the default group")
    func deletingTodoGroupMovesTodosToDefaultGroup() throws {
        let deletedAt = try date("2026-06-02 18:00")
        let homework = TodoGroup(name: "Homework", createdAt: try date("2026-06-02 09:00"))
        let life = TodoGroup(name: "Life", createdAt: try date("2026-06-02 10:00"))
        let homeworkTodo = TodoItem(title: "Homework task", groupID: homework.id, createdAt: try date("2026-06-02 11:00"))
        let lifeTodo = TodoItem(title: "Life task", groupID: life.id, createdAt: try date("2026-06-02 12:00"))
        let defaultTodo = TodoItem(title: "Default task", createdAt: try date("2026-06-02 13:00"))

        let movedTodos = TodoListPlanner.moveTodosToDefaultGroup(
            [homeworkTodo, lifeTodo, defaultTodo],
            from: homework.id,
            at: deletedAt
        )

        #expect(movedTodos.map(\.title) == ["Homework task"])
        #expect(homeworkTodo.groupID == nil)
        #expect(homeworkTodo.updatedAt == deletedAt)
        #expect(lifeTodo.groupID == life.id)
        #expect(defaultTodo.groupID == nil)
    }

    private func date(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try #require(formatter.date(from: value))
    }
}
