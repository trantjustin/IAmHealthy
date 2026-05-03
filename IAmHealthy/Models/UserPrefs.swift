import Foundation
import SwiftData

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var label: String { self == .kg ? "Kilograms (kg)" : "Pounds (lb)" }
    var short: String { rawValue }
}

@Model
final class UserPrefs {
    var unitRaw: String
    var unitChosen: Bool
    var onboardingCompleted: Bool
    var hasSeenPeopleTip: Bool
    var reminderEnabled: Bool
    var reminderTime: Date
    var selectedPersonID: UUID?

    init(unitRaw: String = WeightUnit.kg.rawValue,
         unitChosen: Bool = false,
         onboardingCompleted: Bool = false,
         hasSeenPeopleTip: Bool = false,
         reminderEnabled: Bool = false,
         reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
         selectedPersonID: UUID? = nil) {
        self.unitRaw = unitRaw
        self.unitChosen = unitChosen
        self.onboardingCompleted = onboardingCompleted
        self.hasSeenPeopleTip = hasSeenPeopleTip
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.selectedPersonID = selectedPersonID
    }

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .kg }
        set { unitRaw = newValue.rawValue }
    }
}
