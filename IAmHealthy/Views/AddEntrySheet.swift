import SwiftUI
import SwiftData

struct AddEntrySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @Query private var prefsList: [UserPrefs]

    @State private var date = Date()
    @State private var weightText = ""
    @State private var note = ""
    @State private var saving = false

    private var unit: WeightUnit { prefsList.first?.unit ?? .kg }
    private var activePerson: Person? {
        if let id = prefsList.first?.selectedPersonID,
           let m = people.first(where: { $0.id == id }) { return m }
        return people.first
    }

    private var parsed: Double? {
        let normalized = weightText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(normalized), v > 0 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            Form {
                if let activePerson {
                    Section {
                        HStack {
                            AvatarBadge(person: activePerson, size: 28)
                            Text("Logging for \(activePerson.name)")
                                .font(.subheadline)
                            Spacer()
                            if activePerson.syncToHealth {
                                Label("Health", systemImage: "heart.fill")
                                    .labelStyle(.titleAndIcon)
                                    .font(.caption)
                                    .foregroundStyle(.pink)
                            }
                        }
                    }
                }
                Section {
                    DatePicker("Date", selection: $date)
                    HStack {
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                        Text(unit.short).foregroundStyle(.secondary)
                    }
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(parsed == nil || saving || activePerson == nil)
                }
            }
        }
    }

    private func save() async {
        guard let value = parsed, let person = activePerson else { return }
        saving = true
        defer { saving = false }

        let kg = UnitFormatter.displayToKg(value, unit: unit)
        let entry = WeightEntry(date: date, kilograms: kg, note: note.isEmpty ? nil : note, person: person)
        context.insert(entry)

        if person.syncToHealth, HealthKitService.shared.authorizationStatus() == .sharingAuthorized {
            // Best-effort write to Apple Health. Failures don't block dismissal —
            // the entry is already persisted locally.
            if let uuid = try? await HealthKitService.shared.saveBodyMass(kg: kg, date: date) {
                entry.healthKitUUID = uuid
            }
        }
        try? context.save()
        Analytics.signal(Analytics.Event.weightLogged, parameters: [
            "syncedToHealth": person.syncToHealth ? "true" : "false"
        ])
        dismiss()
    }
}
