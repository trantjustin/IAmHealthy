import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var prefsList: [UserPrefs]
    @Query(sort: \Person.sortOrder) private var people: [Person]

    var body: some View {
        TabView {
            LogView()
                .tabItem { Label("Log", systemImage: "list.bullet") }
            TrendView()
                .tabItem { Label("Trend", systemImage: "chart.xyaxis.line") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .task { bootstrap() }
        .sheet(isPresented: Binding(
            get: { prefsList.first.map { !$0.unitChosen } ?? false },
            set: { _ in }
        )) {
            if let prefs = prefsList.first {
                UnitOnboardingSheet(prefs: prefs)
            }
        }
    }

    private func bootstrap() {
        let prefs: UserPrefs
        if let existing = prefsList.first {
            prefs = existing
        } else {
            prefs = UserPrefs()
            context.insert(prefs)
        }
        if people.isEmpty {
            let me = Person(name: "Me",
                            colorHex: Person.defaultColors[0],
                            syncToHealth: true,
                            sortOrder: 0)
            context.insert(me)
            prefs.selectedPersonID = me.id
        } else if prefs.selectedPersonID == nil {
            prefs.selectedPersonID = people.first?.id
        }
        try? context.save()
    }
}
