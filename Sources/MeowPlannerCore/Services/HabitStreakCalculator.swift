import Foundation

public enum HabitStreakCalculator {
    public static func currentStreak(
        from checkIns: [HabitCheckIn],
        endingOn referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let checkedDays = Set(checkIns.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var currentDay = calendar.startOfDay(for: referenceDate)

        while checkedDays.contains(currentDay) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                break
            }
            currentDay = previousDay
        }

        return streak
    }
}
