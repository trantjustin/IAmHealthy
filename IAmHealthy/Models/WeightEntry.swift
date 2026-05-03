import Foundation
import SwiftData

@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var kilograms: Double
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
