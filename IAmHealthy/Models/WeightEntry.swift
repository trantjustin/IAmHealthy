import Foundation
import SwiftData

@Model
final class WeightEntry {
    // Property-level defaults are required for SwiftData lightweight migration
    // when these fields land on existing rows during an upgrade.
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date = Date()
    var kilograms: Double = 0
    var note: String?
    var healthKitUUID: UUID?
    var person: Person?

    init(id: UUID = UUID(),
         date: Date,
         kilograms: Double,
         note: String? = nil,
         healthKitUUID: UUID? = nil,
         person: Person? = nil) {
        self.id = id
        self.date = date
        self.kilograms = kilograms
        self.note = note
        self.healthKitUUID = healthKitUUID
        self.person = person
    }
}
