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
    @State private var showingDeleteTodoConfirmation = false

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
        platformEditorBody
            .confirmationDialog(PlannerCopy.text(.deleteTodo, language: appLanguage), isPresented: $showingDeleteTodoConfirmation) {
                Button(PlannerCopy.text(.deleteTodo, language: appLanguage), role: .destructive) {
                    deleteTodo()
                }
                Button(PlannerCopy.text(.cancel, language: appLanguage), role: .cancel) {}
            }
    }

    @ViewBuilder
    private var platformEditorBody: some View {
        #if os(iOS)
        iosEditorBody
        #else
        desktopEditorBody
        #endif
    }

    #if os(iOS)
    private var iosEditorTitleFont: Font {
        .system(size: 20, weight: .semibold)
    }

    private var iosEditorRowFont: Font {
        .system(size: 16, weight: .semibold)
    }

    private var iosEditorBodyFont: Font {
        .system(size: 15, weight: .medium)
    }

    private var iosEditorActionFont: Font {
        .system(size: 18, weight: .semibold)
    }

    private var iosEditorBody: some View {
        NavigationStack {
            ZStack {
                MeowPlannerTheme.plannerGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        iosTitleCard
                        iosGroupCard
                        iosDueDateCard
                        iosNotesCard
                        if todo != nil {
                            iosDeleteTodoButton
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(todo == nil ? PlannerCopy.text(.newTodo, language: appLanguage) : PlannerCopy.text(.editTodo, language: appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PlannerCopy.text(.cancel, language: appLanguage)) {
                        dismiss()
                    }
                    .foregroundStyle(MeowPlannerTheme.caramel)
                }
            }
            .safeAreaInset(edge: .bottom) {
                iosBottomSaveBar
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private var iosTitleCard: some View {
        iosEditorCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: todo == nil ? "plus.circle" : "checkmark.circle")
                    .font(iosEditorTitleFont)
                    .foregroundStyle(MeowPlannerTheme.blush.opacity(0.58))
                    .padding(.top, 2)

                TextField(PlannerCopy.text(.title, language: appLanguage), text: $title, axis: .vertical)
                    .font(iosEditorTitleFont)
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .submitLabel(.done)
            }
        }
    }

    private var iosGroupCard: some View {
        iosEditorCard {
            HStack(spacing: 12) {
                Label(PlannerCopy.text(.todoGroup, language: appLanguage), systemImage: "folder")
                    .font(iosEditorRowFont)
                    .foregroundStyle(MeowPlannerTheme.cocoa)

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Circle()
                        .fill(MeowPlannerTheme.color(hex: selectedGroupColorHex))
                        .frame(width: 12, height: 12)

                    Picker(PlannerCopy.text(.todoGroup, language: appLanguage), selection: $selectedGroupID) {
                        Text(PlannerCopy.text(.defaultTodoGroup, language: appLanguage)).tag(UUID?.none)
                        ForEach(sortedGroups) { group in
                            Text(group.name).tag(Optional(group.id))
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(MeowPlannerTheme.caramel)
                    .fufuControlTint()
                }
            }
        }
    }

    private var iosDueDateCard: some View {
        iosEditorCard {
            VStack(spacing: 12) {
                iosToggleRow(
                    title: PlannerCopy.text(.dueDate, language: appLanguage),
                    systemImage: "calendar.badge.clock",
                    isOn: $hasDueDate
                )

                if hasDueDate {
                    Divider()
                        .background(MeowPlannerTheme.caramel.opacity(0.12))

                    HStack(spacing: 12) {
                        Label(PlannerCopy.text(.due, language: appLanguage), systemImage: "clock")
                            .font(iosEditorBodyFont)
                            .foregroundStyle(MeowPlannerTheme.cocoa)

                        Spacer(minLength: 12)

                        DatePicker(PlannerCopy.text(.due, language: appLanguage), selection: $dueDate)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .fufuControlTint()
                    }
                }
            }
        }
    }

    private var iosNotesCard: some View {
        iosEditorCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(PlannerCopy.text(.notes, language: appLanguage), systemImage: "note.text")
                    .font(iosEditorRowFont)
                    .foregroundStyle(MeowPlannerTheme.cocoa)

                TextField(PlannerCopy.text(.notes, language: appLanguage), text: $notes, axis: .vertical)
                    .font(iosEditorBodyFont)
                    .foregroundStyle(MeowPlannerTheme.cocoa)
                    .textFieldStyle(.plain)
                    .lineLimit(4...8)
                    .padding(12)
                    .background(MeowPlannerTheme.cream.opacity(0.36), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var iosBottomSaveBar: some View {
        Button {
            save()
        } label: {
            Text(PlannerCopy.text(.save, language: appLanguage))
                .font(iosEditorActionFont)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MeowPlannerTheme.pawButtonBrown, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isSaveDisabled)
        .opacity(isSaveDisabled ? 0.48 : 1)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(MeowPlannerTheme.fufuPlannerBackground.opacity(0.94))
    }

    private var iosDeleteTodoButton: some View {
        Button(role: .destructive) {
            showingDeleteTodoConfirmation = true
        } label: {
            Label(PlannerCopy.text(.deleteTodo, language: appLanguage), systemImage: "trash")
                .font(iosEditorRowFont)
                .foregroundStyle(MeowPlannerTheme.blush)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(MeowPlannerTheme.blush.opacity(0.11), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func iosEditorCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MeowPlannerTheme.fufuCalendarBackground.opacity(0.88), in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(MeowPlannerTheme.blush.opacity(0.28), lineWidth: 1.5)
            }
    }

    private func iosToggleRow(
        title: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: systemImage)
                .font(iosEditorRowFont)
                .foregroundStyle(MeowPlannerTheme.cocoa)
        }
        .fufuControlTint()
    }
    #endif

    private var desktopEditorBody: some View {
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
                if todo != nil {
                    deleteTodoButton
                }
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

    private var deleteTodoButton: some View {
        Button(role: .destructive) {
            showingDeleteTodoConfirmation = true
        } label: {
            Label(PlannerCopy.text(.deleteTodo, language: appLanguage), systemImage: "trash")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
        .padding(.vertical, 8)
    }

    private var sortedGroups: [TodoGroup] {
        groups.sorted {
            if $0.createdAt != $1.createdAt {
                return $0.createdAt < $1.createdAt
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var selectedGroupColorHex: String {
        guard let selectedGroupID,
              let selectedGroup = sortedGroups.first(where: { $0.id == selectedGroupID }) else {
            return TodoGroup.defaultColorHex
        }

        return selectedGroup.colorHex
    }

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

        syncAfterMutation()
        dismiss()
    }

    private func deleteTodo() {
        guard let todo else {
            return
        }

        modelContext.delete(todo)
        syncAfterMutation()
        dismiss()
    }

    private func syncAfterMutation() {
        try? modelContext.save()
        WidgetTimelineSyncService.publishSnapshotAndReload(using: modelContext)
        FirestoreAppDataSyncService.shared.scheduleSync(
            for: AccountSessionStore.shared.currentProfile?.remoteUserID,
            using: modelContext
        )
    }
}
