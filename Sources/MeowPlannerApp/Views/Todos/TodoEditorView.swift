import MeowPlannerCore
import SwiftData
import SwiftUI

struct TodoEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var dueDate: Date
    @State private var hasDueDate = true
    @State private var selectedGroupID: UUID?
    @State private var notes = ""

    private let groups: [TodoGroup]
    private let defaultSortOrder: Int?
    private var todo: TodoItem?

    init(
        defaultDate: Date,
        groups: [TodoGroup],
        defaultGroupID: UUID? = nil,
        defaultSortOrder: Int? = nil,
        todo: TodoItem? = nil
    ) {
        _title = State(initialValue: todo?.title ?? "")
        _dueDate = State(initialValue: todo?.dueDate ?? defaultDate)
        _hasDueDate = State(initialValue: todo?.dueDate != nil)
        _selectedGroupID = State(initialValue: todo?.groupID ?? defaultGroupID)
        _notes = State(initialValue: todo?.notes ?? "")
        self.groups = groups
        self.defaultSortOrder = defaultSortOrder
        self.todo = todo
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(PlannerCopy.text(.title, language: appLanguage), text: $title)

                Picker(PlannerCopy.text(.todoGroup, language: appLanguage), selection: $selectedGroupID) {
                    Text(PlannerCopy.text(.defaultTodoGroup, language: appLanguage)).tag(UUID?.none)
                    ForEach(sortedGroups) { group in
                        Text(group.name).tag(Optional(group.id))
                    }
                }
                .fufuControlTint()

                Toggle(PlannerCopy.text(.dueDate, language: appLanguage), isOn: $hasDueDate)
                    .fufuControlTint()
                if hasDueDate {
                    DatePicker(PlannerCopy.text(.due, language: appLanguage), selection: $dueDate)
                        .fufuControlTint()
                }
                TextField(PlannerCopy.text(.notes, language: appLanguage), text: $notes, axis: .vertical)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(MeowPlannerTheme.plannerGradient)
            .navigationTitle(todo == nil ? PlannerCopy.text(.newTodo, language: appLanguage) : PlannerCopy.text(.editTodo, language: appLanguage))
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .frame(minWidth: 420, minHeight: 340)
    }

    private var sortedGroups: [TodoGroup] {
        groups.sorted {
            if $0.createdAt != $1.createdAt {
                return $0.createdAt < $1.createdAt
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        if let todo {
            todo.title = trimmedTitle
            todo.notes = notes
            todo.dueDate = hasDueDate ? dueDate : nil
            todo.reminderDate = hasDueDate ? dueDate : nil
            todo.groupID = selectedGroupID
            todo.updatedAt = now
        } else {
            let todo = TodoItem(
                title: trimmedTitle,
                notes: notes,
                dueDate: hasDueDate ? dueDate : nil,
                groupID: selectedGroupID,
                sortOrder: defaultSortOrder,
                reminderDate: hasDueDate ? dueDate : nil,
                createdAt: now,
                updatedAt: now
            )
            modelContext.insert(todo)
        }

        try? modelContext.save()
        WidgetTimelineSyncService.publishSnapshotAndReload(using: modelContext)
        FirestoreAppDataSyncService.shared.scheduleSync(
            for: AccountSessionStore.shared.currentProfile?.remoteUserID,
            using: modelContext
        )
        dismiss()
    }
}
