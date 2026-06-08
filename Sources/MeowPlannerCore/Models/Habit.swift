import Foundation
import SwiftData

@Model
public final class Habit {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var symbolName: String
    public var colorHex: String
    public var reminderDate: Date?
    public var createdAt: Date
    public var archivedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        symbolName: String = "pawprint.fill",
        colorHex: String = "#4F6F8F",
        reminderDate: Date? = nil,
        createdAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.reminderDate = reminderDate
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}
