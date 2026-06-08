import Foundation
import SwiftData

@Model
public final class TodoGroup {
    public static let defaultColorHex = "#B07A47"

    @Attribute(.unique) public var id: UUID
    public var name: String
    public var colorHex: String = TodoGroup.defaultColorHex
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = TodoGroup.defaultColorHex,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
