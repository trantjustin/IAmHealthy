import SwiftUI
import SwiftData
import Charts

enum TrendRange: String, CaseIterable, Identifiable {
    case month = "1M", threeMonth = "3M", year = "1Y", all = "All"
    var id: String { rawValue }
    var days: Int? {
        switch self {
        case .month: return 30
        case .threeMonth: return 90
        case .year: return 365
        case .all: return nil
        }
    }
}

struct TrendView: View {
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
    @Query private var prefsList: [UserPrefs]
    @State private var range: TrendRange = .month

    private var prefs: UserPrefs? { prefsList.first }
    private var unit: WeightUnit { prefs?.unit ?? .kg }

    var body: some View {
        NavigationStack {
            ActivePersonReader { active in
                let mine = entries.filter { $0.person?.id == active?.id }
                let filtered: [WeightEntry] = {
                    guard let days = range.days else { return mine }
                    let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
                    return mine.filter { $0.date >= cutoff }
                }()

                VStack(alignment: .leading, spacing: 12) {
                    Picker("Range", selection: $range) {
                        ForEach(TrendRange.allCases) { r in Text(r.rawValue).tag(r) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if let delta = deltaText(active: active, mine: mine) {
                        HStack {
                            Text(delta).font(.headline)
                            Spacer()
                            if let eta = etaText(active: active, mine: mine) {
                                Text(eta).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }

                    if filtered.isEmpty {
                        ContentUnavailableView("Not enough data",
                                               systemImage: "chart.xyaxis.line",
                                               description: Text("Log some entries to see the trend."))
                    } else {
                        Chart {
                            ForEach(filtered) { entry in
                                LineMark(
                                    x: .value("Date", entry.date),
                                    y: .value("Weight", UnitFormatter.kgToDisplay(entry.kilograms, unit: unit))
                                )
                                .foregroundStyle(active?.color ?? .accentColor)
                                .interpolationMethod(.monotone)
                                PointMark(
                                    x: .value("Date", entry.date),
                                    y: .value("Weight", UnitFormatter.kgToDisplay(entry.kilograms, unit: unit))
                                )
                                .foregroundStyle(active?.color ?? .accentColor)
                            }
                            if let goalKg = active?.goalKg {
                                RuleMark(y: .value("Goal", UnitFormatter.kgToDisplay(goalKg, unit: unit)))
                                    .foregroundStyle(.green)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .annotation(position: .top, alignment: .leading) {
                                        Text("Goal").font(.caption2).foregroundStyle(.green)
                                    }
                            }
                        }
                        .chartYAxisLabel(unit.short)
                        .padding()
                    }
                    Spacer()
                }
                .navigationTitle("Trend")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { PersonSwitcher() }
                }
            }
        }
    }

    private func deltaText(active: Person?, mine: [WeightEntry]) -> String? {
        guard let goalKg = active?.goalKg, let latest = mine.last else { return nil }
        let diffKg = latest.kilograms - goalKg
        let absDisplay = abs(UnitFormatter.kgToDisplay(diffKg, unit: unit))
        let formatted = String(format: "%.1f", absDisplay)
        if abs(diffKg) < 0.05 { return "At goal!" }
        return diffKg > 0 ? "\(formatted) \(unit.short) to goal" : "\(formatted) \(unit.short) under goal"
    }

    private func etaText(active: Person?, mine: [WeightEntry]) -> String? {
        guard let goalKg = active?.goalKg, mine.count >= 14 else { return nil }
        let now = Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now
        let recent = mine.filter { $0.date >= twoWeeksAgo }
        guard recent.count >= 4 else { return nil }
        let firstDate = recent.first!.date
        let xs = recent.map { $0.date.timeIntervalSince(firstDate) / 86400.0 }
        let ys = recent.map { $0.kilograms }
        guard let slope = linearSlope(xs: xs, ys: ys), abs(slope) > 0.01 else { return nil }
        let latest = recent.last!
        let daysToGoal = (goalKg - latest.kilograms) / slope
        guard daysToGoal > 0, daysToGoal < 3650 else { return nil }
        let eta = Calendar.current.date(byAdding: .day, value: Int(daysToGoal.rounded()), to: latest.date) ?? now
        return "At current rate, ~" + eta.formatted(.dateTime.month(.abbreviated).day())
    }

    private func linearSlope(xs: [Double], ys: [Double]) -> Double? {
        let n = Double(xs.count)
        guard n > 1 else { return nil }
        let mx = xs.reduce(0, +) / n
        let my = ys.reduce(0, +) / n
        var num = 0.0, den = 0.0
        for i in 0..<xs.count {
            num += (xs[i] - mx) * (ys[i] - my)
            den += (xs[i] - mx) * (xs[i] - mx)
        }
        return den == 0 ? nil : num / den
    }
}
