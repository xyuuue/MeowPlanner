import Foundation
import SwiftData

@Model
public final class PlannerEvent {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var startDate: Date
    public var endDate: Date?
    public var isAllDay: Bool
    public var notes: String
    public var isCompleted: Bool
    public var completedAt: Date?
    public var reminderOffsetMinutes: Int?
    public var repeatRuleData: Data?
    public var tagName: String = ""
    public var colorHex: String = PlannerPreference.defaultEventColorHexes[0]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date? = nil,
        isAllDay: Bool = false,
        notes: String = "",
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        reminderOffsetMinutes: Int? = nil,
        repeatRule: RepeatRule = .none,
        tagName: String = "",
        colorHex: String = PlannerPreference.defaultEventColorHexes[0],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        if isAllDay,
           let endDate,
           !Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            self.endDate = endDate
        } else {
            self.endDate = isAllDay ? nil : endDate
        }
        self.isAllDay = isAllDay
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.reminderOffsetMinutes = reminderOffsetMinutes
        self.repeatRuleData = try? JSONEncoder().encode(repeatRule)
        self.tagName = tagName
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var repeatRule: RepeatRule {
        get {
            guard let repeatRuleData,
                  let decoded = try? JSONDecoder().decode(RepeatRule.self, from: repeatRuleData) else {
                return .none
            }
            return decoded
        }
        set {
            repeatRuleData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    public var reminderDate: Date? {
        guard let reminderOffsetMinutes else {
            return nil
        }
        return startDate.addingTimeInterval(TimeInterval(-reminderOffsetMinutes * 60))
    }

    public func timeSummary(calendar: Calendar = .current) -> String {
        timeSummary(language: .chinese, calendar: calendar)
    }

    public func timeSummary(language: AppLanguage, calendar: Calendar = .current) -> String {
        if isAllDay {
            return PlannerCopy.text(.allDay, language: language)
        }

        let startText = startDate.formatted(date: .omitted, time: .shortened)
        guard let endDate else {
            return startText
        }

        if calendar.isDate(startDate, inSameDayAs: endDate) {
            return "\(startText)-\(endDate.formatted(date: .omitted, time: .shortened))"
        }

        return "\(startText)-\(endDate.formatted(date: .abbreviated, time: .shortened))"
    }

    public func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)?.addingTimeInterval(-1),
              startDate <= dayEnd else {
            return false
        }

        if isAllDay, let endDate {
            let eventStart = calendar.startOfDay(for: startDate)
            let eventEnd = calendar.startOfDay(for: endDate)
            return dayStart >= eventStart && dayStart <= eventEnd
        }

        return repeatRule
            .occurrences(startingAt: startDate, until: dayEnd, calendar: calendar)
            .contains { calendar.isDate($0, inSameDayAs: date) }
    }

    public func markCompleted(at date: Date = Date()) {
        isCompleted = true
        completedAt = date
        updatedAt = date
    }

    public func reopen(at date: Date = Date()) {
        isCompleted = false
        completedAt = nil
        updatedAt = date
    }
}
