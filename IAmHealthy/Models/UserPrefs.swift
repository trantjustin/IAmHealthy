import Foundation
import SwiftData

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var label: String { self == .kg ? "Kilograms (kg)" : "Pounds (lb)" }
    var short: String { rawValue }
}

enum ReminderFrequency: String, CaseIterable, Identifiable {
    case daily, weekly, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .custom: return "Custom"
        }
    }
}

@Model
final class UserPrefs {
    var unitRaw: String
    var unitChosen: Bool
    var onboardingCompleted: Bool
    var hasSeenPeopleTip: Bool
    var reminderEnabled: Bool
    var reminderTime: Date
    var reminderFrequencyRaw: String
    var reminderWeekday: Int            // 1 = Sunday … 7 = Saturday (Calendar convention)
    var reminderIntervalDays: Int       // for .custom frequency
    var selectedPersonID: UUID?

    init(unitRaw: String = WeightUnit.kg.rawValue,
         unitChosen: Bool = false,
         onboardingCompleted: Bool = false,
         hasSeenPeopleTip: Bool = false,
         reminderEnabled: Bool = false,
         reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
         reminderFrequencyRaw: String = ReminderFrequency.daily.rawValue,
         reminderWeekday: Int = 2,       // Monday default
         reminderIntervalDays: Int = 3,
         selectedPersonID: UUID? = nil) {
        self.unitRaw = unitRaw
        self.unitChosen = unitChosen
        self.onboardingCompleted = onboardingCompleted
        self.hasSeenPeopleTip = hasSeenPeopleTip
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.reminderFrequencyRaw = reminderFrequencyRaw
        self.reminderWeekday = reminderWeekday
        self.reminderIntervalDays = reminderIntervalDays
        self.selectedPersonID = selectedPersonID
    }

    var reminderFrequency: ReminderFrequency {
        get { ReminderFrequency(rawValue: reminderFrequencyRaw) ?? .daily }
        set { reminderFrequencyRaw = newValue.rawValue }
    }

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .kg }
        set { unitRaw = newValue.rawValue }
    }
}
