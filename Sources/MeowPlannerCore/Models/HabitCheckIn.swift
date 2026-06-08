import Foundation
import SwiftData

@Model
public final class HabitCheckIn {
    @Attribute(.unique) public var id: UUID
    public var habitID: UUID
    public var date: Date
    public var note: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        habitID: UUID,
        date: Date,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.note = note
        self.createdAt = createdAt
    }
}
