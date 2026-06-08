import Foundation

public enum RepeatRule: Codable, Equatable, Sendable {
    case none
    case daily(interval: Int)
    case weekly(interval: Int, weekdays: [Int])
    case monthly(interval: Int)

    public func occurrences(
        startingAt startDate: Date,
        until endDate: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard startDate <= endDate else {
            return []
        }

        switch self {
        case .none:
            return [startDate]
        case .daily(let interval):
            return strideOccurrences(
                startingAt: startDate,
                until: endDate,
                component: .day,
                interval: max(1, interval),
                calendar: calendar
            )
        case .weekly(let interval, let weekdays):
            return weeklyOccurrences(
                startingAt: startDate,
                until: endDate,
                interval: max(1, interval),
                weekdays: weekdays,
                calendar: calendar
            )
        case .monthly(let interval):
            return strideOccurrences(
                startingAt: startDate,
                until: endDate,
                component: .month,
                interval: max(1, interval),
                calendar: calendar
            )
        }
    }

    private func strideOccurrences(
        startingAt startDate: Date,
        until endDate: Date,
        component: Calendar.Component,
        interval: Int,
        calendar: Calendar
    ) -> [Date] {
        var results: [Date] = []
        var current = startDate

        while current <= endDate {
            results.append(current)
            guard let next = calendar.date(byAdding: component, value: interval, to: current) else {
                break
            }
            current = next
        }

        return results
    }

    private func weeklyOccurrences(
        startingAt startDate: Date,
        until endDate: Date,
        interval: Int,
        weekdays: [Int],
        calendar: Calendar
    ) -> [Date] {
        let targetWeekdays = Set(weekdays.isEmpty ? [calendar.component(.weekday, from: startDate)] : weekdays)
        var results: [Date] = []
        var currentDay = calendar.startOfDay(for: startDate)
        let startWeek = calendar.component(.weekOfYear, from: startDate)
        let startTime = calendar.dateComponents([.hour, .minute, .second], from: startDate)

        while currentDay <= endDate {
            let weekDelta = calendar.component(.weekOfYear, from: currentDay) - startWeek
            let weekday = calendar.component(.weekday, from: currentDay)

            if weekDelta.isMultiple(of: interval), targetWeekdays.contains(weekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: currentDay)
                components.hour = startTime.hour
                components.minute = startTime.minute
                components.second = startTime.second

                if let occurrence = calendar.date(from: components),
                   occurrence >= startDate,
                   occurrence <= endDate {
                    results.append(occurrence)
                }
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                break
            }
            currentDay = nextDay
        }

        return results
    }
}
