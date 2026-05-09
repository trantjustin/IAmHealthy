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
                        let goalDisplay = active?.goalKg.map { UnitFormatter.kgToDisplay($0, unit: unit) }
                        let yDomain = computeYDomain(for: filtered, goal: goalDisplay)
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
                            if let goalDisplay {
                                RuleMark(y: .value("Goal", goalDisplay))
                                    .foregroundStyle(.green)
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .annotation(position: .top, alignment: .leading) {
                                        Text("Goal").font(.caption2).foregroundStyle(.green)
                                    }
                            }
                        }
                        .chartYScale(domain: yDomain)
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

    /// Compute a tight Y-axis domain for the filtered data so small changes
    /// over short windows don't render as a flat line. The goal line is
    /// included only when it's "close" to the data (within ~2× the data's
    /// own range, or 5 display units when the data is essentially flat).
    /// A faraway goal would otherwise re-flatten the chart.
    private func computeYDomain(for entries: [WeightEntry], goal: Double?) -> ClosedRange<Double> {
        let values = entries.map { UnitFormatter.kgToDisplay($0.kilograms, unit: unit) }
        guard let dataMin = values.min(), let dataMax = values.max() else {
            return 0...1 // Defensive; this branch isn't reached when entries is non-empty.
        }
        let dataRange = dataMax - dataMin

        // Decide whether to include the goal in the domain.
        var lo = dataMin
        var hi = dataMax
        if let g = goal {
            let proximityWindow = max(dataRange * 2, 5.0)
            if g >= dataMin - proximityWindow && g <= dataMax + proximityWindow {
                lo = min(lo, g)
                hi = max(hi, g)
            }
        }

        // Pad: 20% of the visible range, with a sane floor so a perfectly
        // flat dataset (or two values within < 1 unit) still gets breathing
        // room. Floor of 1 display unit on each side feels right for both kg
        // and lb scales.
        let visibleRange = hi - lo
        let padding = max(visibleRange * 0.2, 1.0)
        return (lo - padding)...(hi + padding)
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
