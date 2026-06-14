import MeowPlannerCore
import SwiftData
import SwiftUI

struct TodoHomeView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt) private var todos: [TodoItem]
    @Query(sort: \TodoGroup.createdAt) private var groups: [TodoGroup]

    @State private var selectedFilter: TodoGroupFilter = .all
    @State private var showingTodoEditor = false
    @State private var editingTodo: TodoItem?
    @State private var showingGroupEditor = false
    @State private var editingGroup: TodoGroup?
    @State private var dropTargetTodoID: UUID?

    var body: some View {
        ZStack {
            MeowPlannerTheme.fufuPlannerBackground
                .overlay {
                    MeowPlannerTheme.plannerGradient.opacity(0.88)
                }
                .overlay {
                    todoBackgroundMotifs
                }
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header
                groupSelector

                if visibleTodos.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(visibleTodos) { todo in
                                let groupColorHex = TodoListPlanner.groupColorHex(
                                    for: todo,
                                    groups: groups
                                )
                                TodoRowView(
                                    todo: todo,
                                    groupName: TodoListPlanner.groupName(
                                        for: todo,
                                        groups: groups,
                                        defaultName: defaultGroupTitle
                                    ),
                                    groupColorHex: groupColorHex,
                                    showsGroupTag: selectedFilter == .all,
                                    completeAction: { toggleCompletion(todo) },
                                    editAction: { editingTodo = todo },
                                    deleteAction: { deleteTodo(todo) }
                                )
                                .scaleEffect(dropTargetTodoID == todo.id ? 1.01 : 1)
                                .animation(.easeInOut(duration: 0.12), value: dropTargetTodoID)
                                .draggable(todo.id.uuidString) {
                                    TodoDragPreviewView(title: todo.title, groupColorHex: groupColorHex)
                                }
                                .dropDestination(for: String.self) { itemIdentifiers, _ in
                                    guard let draggedIdentifier = itemIdentifiers.first else {
                                        return false
                                    }
                                    return moveTodo(draggedIdentifier: draggedIdentifier, before: todo.id)
                                } isTargeted: { isTargeted in
                                    dropTargetTodoID = isTargeted ? todo.id : nil
                                }
                            }

                            Color.clear
                                .frame(height: 28)
                                .dropDestination(for: String.self) { itemIdentifiers, _ in
                                    guard let draggedIdentifier = itemIdentifiers.first else {
                                        return false
                                    }
                                    return moveTodo(draggedIdentifier: draggedIdentifier, before: nil)
                                }
                        }
                        .padding(.bottom, 28)
                    }
                    .verticalPageScrollOnly()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: groupIDs) { _, _ in
            selectedFilter = TodoListPlanner.normalizedSelection(selectedFilter, groups: groups)
        }
        .sheet(isPresented: $showingTodoEditor) {
            TodoEditorView(
                defaultDate: Date(),
                groups: groups,
                defaultGroupID: defaultGroupIDForNewTodo,
                defaultSortOrder: defaultSortOrderForNewTodo
            )
        }
        .sheet(isPresented: Binding(get: { editingTodo != nil }, set: { if !$0 { editingTodo = nil } })) {
            if let editingTodo {
                TodoEditorView(
                    defaultDate: editingTodo.dueDate ?? Date(),
                    groups: groups,
                    todo: editingTodo
                )
            }
        }
        .sheet(isPresented: $showingGroupEditor, onDismiss: { editingGroup = nil }) {
            TodoGroupEditorView(group: editingGroup)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            FuFuAssetImage(size: 58)

            VStack(alignment: .leading, spacing: 3) {
                Text(PlannerCopy.text(.todo, language: appLanguage))
                    .font(.title2.bold())
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                Text(PlannerCopy.text(.todoListSubtitle, language: appLanguage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if selectedEditableGroup != nil {
                Button {
                    editingGroup = selectedEditableGroup
                    showingGroupEditor = true
                } label: {
                    Label(PlannerCopy.text(.editTodoGroup, language: appLanguage), systemImage: "pencil")
                }
                .buttonStyle(.bordered)
            }

            Button {
                editingGroup = nil
                showingGroupEditor = true
            } label: {
                Label(PlannerCopy.text(.newTodoGroup, language: appLanguage), systemImage: "folder.badge.plus")
            }
            .buttonStyle(.bordered)

            Button {
                showingTodoEditor = true
            } label: {
                Label(PlannerCopy.text(.addTodo, language: appLanguage), systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(MeowPlannerTheme.caramel)
        }
    }

    private var groupSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(groupOptions) { option in
                    Button {
                        selectedFilter = option.filter
                    } label: {
                        let groupColor = MeowPlannerTheme.color(hex: groupColorHex(for: option.filter))
                        Text(option.title)
                            .font(.callout.weight(selectedFilter == option.filter ? .bold : .semibold))
                            .lineLimit(1)
                            .foregroundStyle(selectedFilter == option.filter ? .white : MeowPlannerTheme.cocoa)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedFilter == option.filter
                                    ? groupColor
                                    : MeowPlannerTheme.cream.opacity(0.76),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(groupColor.opacity(0.36), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if let group = editableGroup(for: option.filter) {
                            Button(PlannerCopy.text(.editTodoGroup, language: appLanguage)) {
                                editingGroup = group
                                showingGroupEditor = true
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var emptyState: some View {
        FuFuEmptyStateView(
            title: selectedFilter == .all
                ? PlannerCopy.text(.noTodos, language: appLanguage)
                : PlannerCopy.text(.noTodosInGroup, language: appLanguage),
            message: selectedFilter == .all
                ? PlannerCopy.text(.noTodosMessage, language: appLanguage)
                : PlannerCopy.text(.noTodosInGroupMessage, language: appLanguage),
            actionTitle: PlannerCopy.text(.addTodo, language: appLanguage),
            action: { showingTodoEditor = true }
        )
    }

    private var todoBackgroundMotifs: some View {
        GeometryReader { proxy in
            ZStack {
                Image(systemName: "checklist")
                    .font(.system(size: 210, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.fufuPawTint.opacity(0.10))
                    .rotationEffect(.degrees(-10))
                    .position(x: proxy.size.width * 0.18, y: proxy.size.height * 0.58)

                Image(systemName: "pawprint")
                    .font(.system(size: 180, weight: .semibold))
                    .foregroundStyle(MeowPlannerTheme.caramel.opacity(0.13))
                    .rotationEffect(.degrees(8))
                    .position(x: proxy.size.width * 0.58, y: proxy.size.height * 0.32)

                Image(systemName: "folder.fill")
                    .font(.system(size: 230, weight: .bold))
                    .foregroundStyle(MeowPlannerTheme.blush.opacity(0.10))
                    .rotationEffect(.degrees(12))
                    .position(x: proxy.size.width * 0.84, y: proxy.size.height * 0.70)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }

    private var visibleTodos: [TodoItem] {
        TodoListPlanner.visibleTodos(todos, filter: selectedFilter)
    }

    private var groupOptions: [TodoGroupOption] {
        TodoListPlanner.groupOptions(
            groups: groups,
            allTitle: PlannerCopy.text(.allTodos, language: appLanguage),
            defaultTitle: defaultGroupTitle
        )
    }

    private var defaultGroupTitle: String {
        PlannerCopy.text(.defaultTodoGroup, language: appLanguage)
    }

    private var defaultGroupIDForNewTodo: UUID? {
        switch selectedFilter {
        case .all:
            nil
        case let .group(groupID):
            groupID
        }
    }

    private var defaultSortOrderForNewTodo: Int? {
        TodoListPlanner.nextSortOrder(after: visibleTodos)
    }

    private var selectedEditableGroup: TodoGroup? {
        editableGroup(for: selectedFilter)
    }

    private var groupIDs: [UUID] {
        groups.map(\.id)
    }

    private func editableGroup(for filter: TodoGroupFilter) -> TodoGroup? {
        guard case let .group(groupID?) = filter else {
            return nil
        }

        return groups.first { $0.id == groupID }
    }

    private func groupColorHex(for filter: TodoGroupFilter) -> String {
        switch filter {
        case .all:
            TodoGroup.defaultColorHex
        case .group(nil):
            TodoGroup.defaultColorHex
        case let .group(groupID?):
            groups.first { $0.id == groupID }?.colorHex ?? TodoGroup.defaultColorHex
        }
    }

    private func toggleCompletion(_ todo: TodoItem) {
        let currentTodos = visibleTodos
        let now = Date()

        if todo.isCompleted {
            todo.reopen(at: now)
        } else {
            todo.markCompleted(at: now)
        }

        TodoListPlanner.reorderedTodosAfterCompletionChange(
            currentTodos,
            changedTodo: todo,
            at: now
        )
        syncWidgetTimelineAfterMutation()
    }

    private func deleteTodo(_ todo: TodoItem) {
        modelContext.delete(todo)
        syncWidgetTimelineAfterMutation()
    }

    @discardableResult
    private func moveTodo(draggedIdentifier: String, before targetID: UUID?) -> Bool {
        guard let draggedID = UUID(uuidString: draggedIdentifier) else {
            return false
        }

        let currentTodos = visibleTodos
        guard let sourceIndex = currentTodos.firstIndex(where: { $0.id == draggedID }) else {
            return false
        }

        let destinationIndex: Int
        if let targetID {
            guard let targetIndex = currentTodos.firstIndex(where: { $0.id == targetID }) else {
                return false
            }
            guard targetIndex != sourceIndex && targetIndex != sourceIndex + 1 else {
                dropTargetTodoID = nil
                return false
            }
            destinationIndex = targetIndex
        } else {
            guard sourceIndex != currentTodos.count - 1 else {
                dropTargetTodoID = nil
                return false
            }
            destinationIndex = currentTodos.count
        }

        TodoListPlanner.reorderedTodos(
            currentTodos,
            moving: IndexSet(integer: sourceIndex),
            to: destinationIndex
        )
        dropTargetTodoID = nil
        syncWidgetTimelineAfterMutation()
        return true
    }

    private func syncWidgetTimelineAfterMutation() {
        try? modelContext.save()
        WidgetTimelineSyncService.publishSnapshotAndReload(using: modelContext)
        FirestoreAppDataSyncService.shared.scheduleSync(
            for: AccountSessionStore.shared.currentProfile?.remoteUserID,
            using: modelContext
        )
    }
}

private struct TodoDragPreviewView: View {
    var title: String
    var groupColorHex: String

    var body: some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(MeowPlannerTheme.cocoa)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: 220, alignment: .leading)
            .background(MeowPlannerTheme.color(hex: groupColorHex).opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(MeowPlannerTheme.color(hex: groupColorHex).opacity(0.24), lineWidth: 1)
            }
    }
}

private struct TodoRowView: View {
    @Environment(\.appLanguage) private var appLanguage

    var todo: TodoItem
    var groupName: String
    var groupColorHex: String
    var showsGroupTag: Bool
    var completeAction: () -> Void
    var editAction: () -> Void
    var deleteAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 18)
                .accessibilityHidden(true)

            Button(action: completeAction) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(todo.isCompleted ? MeowPlannerTheme.color(hex: groupColorHex) : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(todo.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MeowPlannerTheme.cocoa)
                        .strikethrough(todo.isCompleted)

                    if showsGroupTag {
                        Text(groupName)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(MeowPlannerTheme.cocoa)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(MeowPlannerTheme.color(hex: groupColorHex).opacity(0.16), in: Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Text(todo.dueDate?.formatted(date: .abbreviated, time: .shortened) ?? PlannerCopy.text(.anytime, language: appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !todo.notes.isEmpty {
                        Text(todo.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Button(action: editAction) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)

            Button(role: .destructive, action: deleteAction) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(MeowPlannerTheme.color(hex: groupColorHex).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(todo.isCompleted ? MeowPlannerTheme.color(hex: groupColorHex).opacity(0.45) : MeowPlannerTheme.color(hex: groupColorHex))
                .frame(width: 4)
                .padding(.vertical, 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(MeowPlannerTheme.color(hex: groupColorHex).opacity(0.18), lineWidth: 1)
        }
    }
}

private struct TodoGroupEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [PlannerPreference]

    @State private var name: String
    @State private var colorHex: String
    @State private var showingPaletteColorEditor = false
    @State private var paletteEditorColorHex = PlannerPreference.defaultEventColorHexes[0]
    @State private var paletteEditorOriginalColorHex: String?
    private var group: TodoGroup?

    init(group: TodoGroup? = nil) {
        let initialColorHex = MeowPlannerTheme.normalizedHex(group?.colorHex ?? TodoGroup.defaultColorHex) ?? TodoGroup.defaultColorHex
        _name = State(initialValue: group?.name ?? "")
        _colorHex = State(initialValue: initialColorHex)
        _paletteEditorColorHex = State(initialValue: initialColorHex)
        self.group = group
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(PlannerCopy.text(.groupName, language: appLanguage), text: $name)
                paletteColorControls
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(MeowPlannerTheme.plannerGradient)
            .sheet(isPresented: $showingPaletteColorEditor) {
                PaletteColorEditorView(
                    initialColorHex: paletteEditorColorHex,
                    originalColorHex: paletteEditorOriginalColorHex,
                    canDelete: paletteEditorOriginalColorHex != nil && eventColorOptions.count > 1,
                    onSave: { newColorHex, originalColorHex in
                        if let originalColorHex {
                            updatePaletteColor(from: originalColorHex, to: newColorHex)
                        } else {
                            addPaletteColor(newColorHex)
                        }
                    },
                    onDelete: { colorHex in
                        deletePaletteColor(colorHex)
                    }
                )
            }
            .navigationTitle(group == nil ? PlannerCopy.text(.newTodoGroup, language: appLanguage) : PlannerCopy.text(.editTodoGroup, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(PlannerCopy.text(.save, language: appLanguage)) {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .frame(minWidth: 360, minHeight: 180)
    }

    private var paletteColorControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(PlannerCopy.text(.color, language: appLanguage))
                    .foregroundStyle(.secondary)

                Spacer()

                Circle()
                    .fill(MeowPlannerTheme.color(hex: colorHex))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Circle()
                            .stroke(Color.primary.opacity(0.14), lineWidth: 1)
                    }
                    .accessibilityLabel(colorHex)
            }

            HStack(spacing: 12) {
                ForEach(eventColorOptions, id: \.self) { option in
                    ColorSwatchButton(
                        colorHex: option,
                        isSelected: colorHex == option,
                        canDelete: eventColorOptions.count > 1,
                        onSelect: { applyColorHex(option) },
                        onDelete: { deletePaletteColor(option) }
                    )
                }

                Button {
                    openPaletteColorEditor(nil)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 30, height: 30)
                        .foregroundStyle(MeowPlannerTheme.caramel)
                        .background(MeowPlannerTheme.cream.opacity(0.72), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(MeowPlannerTheme.caramel.opacity(0.32), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(PlannerCopy.text(.addColor, language: appLanguage))
            }
        }
    }

    private var eventColorOptions: [String] {
        preferences.first?.eventColorHexes ?? PlannerPreference.defaultEventColorHexes
    }

    private var preference: PlannerPreference {
        if let existing = preferences.first {
            return existing
        }

        let created = PlannerPreference.defaults
        modelContext.insert(created)
        return created
    }

    private func applyColorHex(_ value: String) {
        guard let normalized = MeowPlannerTheme.normalizedHex(value) else {
            return
        }

        colorHex = normalized
    }

    private func openPaletteColorEditor(_ colorHex: String?) {
        let editorColorHex = colorHex ?? self.colorHex
        paletteEditorColorHex = MeowPlannerTheme.normalizedHex(editorColorHex) ?? PlannerPreference.defaultEventColorHexes[0]
        paletteEditorOriginalColorHex = colorHex
        showingPaletteColorEditor = true
    }

    private func addPaletteColor(_ value: String) {
        guard let normalized = MeowPlannerTheme.normalizedHex(value) else {
            return
        }

        var colors = eventColorOptions
        if !colors.contains(normalized) {
            colors.append(normalized)
            persistPaletteColors(colors)
        }
        applyColorHex(normalized)
    }

    private func updatePaletteColor(from originalColorHex: String, to newColorHex: String) {
        guard let original = MeowPlannerTheme.normalizedHex(originalColorHex),
              let updated = MeowPlannerTheme.normalizedHex(newColorHex) else {
            return
        }

        var colors = eventColorOptions
        if let index = colors.firstIndex(of: original) {
            colors[index] = updated
        } else {
            colors.append(updated)
        }
        colors = PlannerPreference.normalizedEventColorHexes(colors)
        persistPaletteColors(colors)
        applyColorHex(updated)
    }

    private func deletePaletteColor(_ value: String) {
        guard eventColorOptions.count > 1,
              let normalized = MeowPlannerTheme.normalizedHex(value) else {
            return
        }

        var colors = eventColorOptions
        colors.removeAll { $0 == normalized }
        colors = PlannerPreference.normalizedEventColorHexes(colors)
        persistPaletteColors(colors)
        if colorHex == normalized, let firstColor = colors.first {
            applyColorHex(firstColor)
        }
    }

    private func persistPaletteColors(_ colors: [String]) {
        preference.eventColorHexes = colors
        preference.markUpdated()
        try? modelContext.save()
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        if let group {
            group.name = trimmedName
            group.colorHex = colorHex
            group.updatedAt = now
        } else {
            modelContext.insert(TodoGroup(name: trimmedName, colorHex: colorHex, createdAt: now, updatedAt: now))
        }

        dismiss()
    }
}
