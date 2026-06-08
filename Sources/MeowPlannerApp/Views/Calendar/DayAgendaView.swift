import MeowPlannerCore
import SwiftUI

struct DayAgendaView: View {
    @Environment(\.appLanguage) private var appLanguage

    var selectedDate: Date
    var events: [PlannerEvent]
    var onCompleteEvent: (PlannerEvent) -> Void
    var onDeleteEvent: (PlannerEvent) -> Void
    var onEditEvent: (PlannerEvent) -> Void
    var onAddEvent: () -> Void
    var completedSchedulesUseStrikethrough: Bool = true
    var showChineseCalendar: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(.title3.bold())
                    if showChineseCalendar {
                        Text(selectedChineseCalendarInfo.displayText)
                            .font(.caption.weight(selectedChineseCalendarInfo.isFestival ? .bold : .medium))
                            .foregroundStyle(selectedChineseCalendarInfo.isFestival ? MeowPlannerTheme.blush : MeowPlannerTheme.caramel)
                    }
                    Text(PlannerCopy.scheduleSummary(scheduleCount: events.count, language: appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onAddEvent) {
                    Label(PlannerCopy.text(.schedule, language: appLanguage), systemImage: "calendar.badge.plus")
                }
                .labelStyle(.iconOnly)
            }

            if events.isEmpty {
                FuFuEmptyStateView(
                    title: PlannerCopy.text(.clearDay, language: appLanguage),
                    message: PlannerCopy.text(.clearDayMessage, language: appLanguage),
                    actionTitle: PlannerCopy.text(.addSchedule, language: appLanguage),
                    action: onAddEvent
                )
                .frame(maxWidth: .infinity)
            } else {
                ForEach(events) { event in
                    agendaRow(
                        title: event.title,
                        subtitle: event.timeSummary(language: appLanguage),
                        tagName: event.tagName,
                        colorHex: event.colorHex,
                        isCompleted: event.isCompleted,
                        completedSchedulesUseStrikethrough: completedSchedulesUseStrikethrough,
                        completeAction: { onCompleteEvent(event) },
                        editAction: { onEditEvent(event) },
                        deleteAction: { onDeleteEvent(event) }
                    )
                }
            }
        }
        .padding()
    }

    private var selectedChineseCalendarInfo: ChineseCalendarDayInfo {
        ChineseCalendarInfoProvider.info(for: selectedDate, calendar: .current)
    }

    private func agendaRow(
        title: String,
        subtitle: String,
        tagName: String = "",
        colorHex: String = "#4F6F8F",
        isCompleted: Bool,
        completedSchedulesUseStrikethrough: Bool = true,
        completeAction: @escaping () -> Void,
        editAction: @escaping () -> Void,
        deleteAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Button(action: completeAction) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? MeowPlannerTheme.color(hex: colorHex) : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .strikethrough(isCompleted && completedSchedulesUseStrikethrough)

                    if !tagName.isEmpty {
                        Text(tagName)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(MeowPlannerTheme.cocoa)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MeowPlannerTheme.color(hex: colorHex).opacity(0.16), in: Capsule())
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .padding(10)
        .background(MeowPlannerTheme.color(hex: colorHex).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(MeowPlannerTheme.color(hex: colorHex))
                .frame(width: 4)
                .padding(.vertical, 8)
        }
    }
}
