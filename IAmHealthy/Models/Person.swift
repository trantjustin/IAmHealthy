import Foundation
import SwiftData
import SwiftUI

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var syncToHealth: Bool
    var goalKg: Double?
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WeightEntry.person)
    var entries: [WeightEntry] = []

    init(id: UUID = UUID(),
         name: String,
         colorHex: String = Person.defaultColors.first!,
         syncToHealth: Bool = false,
         goalKg: Double? = nil,
         sortOrder: Int = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.syncToHealth = syncToHealth
        self.goalKg = goalKg
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    static let defaultColors: [String] = [
        "#3CB371", // mint
        "#2E86DE", // blue
        "#E67E22", // orange
        "#9B59B6", // purple
        "#E74C3C", // red
        "#16A085", // teal
        "#F1C40F", // yellow
        "#34495E"  // slate
    ]

    var color: Color { Color(hex: colorHex) ?? .accentColor }

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let chars = parts.compactMap { $0.first }.map(String.init)
        let joined = chars.joined()
        return joined.isEmpty ? "?" : joined.uppercased()
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
