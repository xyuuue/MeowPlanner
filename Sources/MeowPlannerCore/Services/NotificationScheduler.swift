import Foundation
import UserNotifications

public final class NotificationScheduler {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    public func schedule(_ reminder: ReminderRequest, calendar: Calendar = .current) async throws {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminder.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
        try await center.add(request)
    }

    public func cancel(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
