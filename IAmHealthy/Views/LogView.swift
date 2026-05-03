import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @Query private var prefsList: [UserPrefs]
    @State private var showingAdd = false

    private var unit: WeightUnit { prefsList.first?.unit ?? .kg }

    var body: some View {
        NavigationStack {
            ActivePersonReader { active in
                let filtered = entries.filter { $0.person?.id == active?.id }
                Group {
                    if active == nil {
                        ContentUnavailableView("Add a person",
                                               systemImage: "person.crop.circle.badge.plus",
                                               description: Text("Open Settings → People to add someone."))
                    } else if filtered.isEmpty {
                        ContentUnavailableView("No entries yet",
                                               systemImage: "scalemass",
                                               description: Text("Tap + to log \(active?.name ?? "")'s first weight."))
                    } else {
                        List {
                            ForEach(filtered) { entry in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(UnitFormatter.format(entry.kilograms, unit: unit))
                                            .font(.headline)
                                        Text(entry.date, format: .dateTime.weekday(.abbreviated).month().day().year().hour().minute())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let note = entry.note, !note.isEmpty {
                                        Spacer()
                                        Text(note).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                            }
                            .onDelete { delete(at: $0, in: filtered) }
                        }
                    }
                }
                .navigationTitle("I Am Healthy!")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { PersonSwitcher() }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showingAdd = true } label: { Image(systemName: "plus") }
                            .disabled(active == nil)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddEntrySheet() }
        }
    }

    private func delete(at offsets: IndexSet, in source: [WeightEntry]) {
        for index in offsets {
            let entry = source[index]
            if entry.person?.syncToHealth == true, let hkUUID = entry.healthKitUUID {
                Task { try? await HealthKitService.shared.deleteBodyMass(uuid: hkUUID) }
            }
            context.delete(entry)
        }
        try? context.save()
    }
}
