import Foundation

enum UnitFormatter {
    static let lbPerKg = 2.2046226218

    static func kgToDisplay(_ kg: Double, unit: WeightUnit) -> Double {
        unit == .kg ? kg : kg * lbPerKg
    }

    static func displayToKg(_ value: Double, unit: WeightUnit) -> Double {
        unit == .kg ? value : value / lbPerKg
    }

    static func format(_ kg: Double, unit: WeightUnit, withUnit: Bool = true) -> String {
        let v = kgToDisplay(kg, unit: unit)
        let s = String(format: "%.1f", v)
        return withUnit ? "\(s) \(unit.short)" : s
    }
}
