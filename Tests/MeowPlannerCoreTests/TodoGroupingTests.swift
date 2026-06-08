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

    private func date(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try #require(formatter.date(from: value))
    }
}
