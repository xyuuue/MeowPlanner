import MeowPlannerCore
import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \HabitCheckIn.date, order: .reverse) private var checkIns: [HabitCheckIn]

    @State private var showingAddHabit = false

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(PlannerCopy.text(.habits, language: appLanguage))
                            .font(.title2.bold())
                        Text(PlannerCopy.text(.habitsSubtitle, language: appLanguage))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        showingAddHabit = true
                    } label: {
                        Label(PlannerCopy.text(.habit, language: appLanguage), systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .fufuControlTint()
                }

                if habits.isEmpty {
                    FuFuEmptyStateView(
                        title: PlannerCopy.text(.noHabits, language: appLanguage),
                        message: PlannerCopy.text(.noHabitsMessage, language: appLanguage),
                        actionTitle: PlannerCopy.text(.addHabit, language: appLanguage),
                        action: { showingAddHabit = true }
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(habits) { habit in
                            habitRow(habit)
                        }
                    }
                }
            }
            .padding()
        }
        .verticalPageScrollOnly()
        .background(MeowPlannerTheme.plannerGradient)
        .sheet(isPresented: $showingAddHabit) {
            HabitEditorView()
        }
    }

    private func habitRow(_ habit: Habit) -> some View {
        let alreadyCheckedIn = checkIns.contains { checkIn in
            checkIn.habitID == habit.id && Calendar.current.isDateInToday(checkIn.date)
        }
        let streak = HabitStreakCalculator.currentStreak(
            from: checkIns.filter { $0.habitID == habit.id },
            endingOn: Date()
        )

        return HStack(spacing: 12) {
            Image(systemName: habit.symbolName)
                .font(.title2)
                .foregroundStyle(MeowPlannerTheme.fufuBlue)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.title)
                    .font(.body.weight(.semibold))
                Text(PlannerCopy.streak(days: streak, language: appLanguage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                toggleCheckIn(for: habit, alreadyCheckedIn: alreadyCheckedIn)
            } label: {
                Label(alreadyCheckedIn ? PlannerCopy.text(.checked, language: appLanguage) : PlannerCopy.text(.checkIn, language: appLanguage), systemImage: alreadyCheckedIn ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.bordered)
            .fufuControlTint()

            Button(role: .destructive) {
                modelContext.delete(habit)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func toggleCheckIn(for habit: Habit, alreadyCheckedIn: Bool) {
        if alreadyCheckedIn,
           let checkIn = checkIns.first(where: { $0.habitID == habit.id && Calendar.current.isDateInToday($0.date) }) {
            modelContext.delete(checkIn)
        } else {
            modelContext.insert(HabitCheckIn(habitID: habit.id, date: Date()))
        }
    }
}

private struct HabitEditorView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var symbolName = "pawprint.fill"

    var body: some View {
        NavigationStack {
            Form {
                TextField(PlannerCopy.text(.habitName, language: appLanguage), text: $title)
                Picker(PlannerCopy.text(.icon, language: appLanguage), selection: $symbolName) {
                    Label(PlannerCopy.text(.paw, language: appLanguage), systemImage: "pawprint.fill").tag("pawprint.fill")
                    Label(PlannerCopy.text(.water, language: appLanguage), systemImage: "drop.fill").tag("drop.fill")
                    Label(PlannerCopy.text(.book, language: appLanguage), systemImage: "book.fill").tag("book.fill")
                    Label(PlannerCopy.text(.walk, language: appLanguage), systemImage: "figure.walk").tag("figure.walk")
                }
                .fufuControlTint()
            }
            .formStyle(.grouped)
            .navigationTitle(PlannerCopy.text(.newHabit, language: appLanguage))
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
        .frame(minWidth: 360, minHeight: 240)
    }

    private func save() {
        modelContext.insert(Habit(title: title.trimmingCharacters(in: .whitespacesAndNewlines), symbolName: symbolName))
        dismiss()
    }
}
