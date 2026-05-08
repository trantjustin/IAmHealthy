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
    // Property-level defaults are REQUIRED for SwiftData lightweight migration
    // when adding new non-optional fields to an existing schema. Without them,
    // upgrading users (whose on-disk rows pre-date the field) crash on launch.
    // Always provide a sensible default at the property level for any new
    // non-optional persistent property.
    var unitRaw: String = WeightUnit.kg.rawValue
    var unitChosen: Bool = false
    var onboardingCompleted: Bool = false
    var hasSeenPeopleTip: Bool = false
    var reminderEnabled: Bool = false
    var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    var reminderFrequencyRaw: String = ReminderFrequency.daily.rawValue
    var reminderWeekday: Int = 2        // 1 = Sunday … 7 = Saturday; Monday default
    var reminderIntervalDays: Int = 3   // for .custom frequency
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
