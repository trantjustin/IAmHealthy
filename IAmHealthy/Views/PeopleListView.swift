import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @Query private var prefsList: [UserPrefs]
    @State private var editing: Person?
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(people) { person in
                Button { editing = person } label: {
                    HStack {
                        AvatarBadge(person: person, size: 36)
                        VStack(alignment: .leading) {
                            Text(person.name).font(.headline).foregroundStyle(.primary)
                            HStack(spacing: 6) {
                                Text("\(person.entries.count) entries")
                                if person.syncToHealth {
                                    Text("·").foregroundStyle(.secondary)
                                    Label("Health", systemImage: "heart.fill")
                                        .labelStyle(.titleAndIcon)
                                        .foregroundStyle(.pink)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(item: $editing) { person in
            NavigationStack { PersonEditView(person: person) }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack { PersonEditView(person: nil) }
        }
    }

    private func delete(at offsets: IndexSet) {
        let prefs = prefsList.first
        for idx in offsets {
            let person = people[idx]
            if prefs?.selectedPersonID == person.id {
                prefs?.selectedPersonID = people.first(where: { $0.id != person.id })?.id
            }
            context.delete(person)
        }
        try? context.save()
    }
}

struct PersonEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @Query private var prefsList: [UserPrefs]

    let person: Person?

    @State private var name = ""
    @State private var colorHex = Person.defaultColors.first!
    @State private var syncToHealth = false
    @State private var goalText = ""
    @State private var loaded = false

    private var unit: WeightUnit { prefsList.first?.unit ?? .kg }
    private var isNew: Bool { person == nil }
    private var anotherSyncs: Bool {
        people.contains { $0.syncToHealth && $0.id != person?.id }
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
            }
            Section("Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                          spacing: 12) {
                    ForEach(Person.defaultColors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex) ?? .gray)
                            .frame(height: 40)
                            .overlay {
                                if hex == colorHex {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.white)
                                        .font(.headline)
                                }
                            }
                            .onTapGesture { colorHex = hex }
                    }
                }
                .padding(.vertical, 4)
            }
            Section("Goal") {
                HStack {
                    TextField("Goal weight", text: $goalText)
                        .keyboardType(.decimalPad)
                    Text(unit.short).foregroundStyle(.secondary)
                }
            }
            Section {
                Toggle("Sync to Apple Health", isOn: $syncToHealth)
                    .disabled(syncToHealth == false && anotherSyncs)
            } footer: {
                if syncToHealth {
                    Text("New entries for this person will be written to the Health app on this device.")
                } else if anotherSyncs {
                    Text("Apple Health represents the device owner's data. Only one person can sync at a time.")
                } else {
                    Text("Turn on if this is the device owner. Other people's entries stay only in this app.")
                }
            }
        }
        .navigationTitle(isNew ? "New Person" : "Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            if let person {
                name = person.name
                colorHex = person.colorHex
                syncToHealth = person.syncToHealth
                if let kg = person.goalKg {
                    goalText = String(format: "%.1f", UnitFormatter.kgToDisplay(kg, unit: unit))
                }
            } else {
                let used = Set(people.map(\.colorHex))
                colorHex = Person.defaultColors.first(where: { !used.contains($0) }) ?? Person.defaultColors[0]
                syncToHealth = !anotherSyncs && people.isEmpty
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let parsedGoal: Double? = {
            let n = goalText.replacingOccurrences(of: ",", with: ".")
            guard let v = Double(n), v > 0 else { return nil }
            return UnitFormatter.displayToKg(v, unit: unit)
        }()

        // Enforce single Health-syncing person.
        if syncToHealth {
            for p in people where p.id != person?.id {
                p.syncToHealth = false
            }
        }

        if let person {
            person.name = trimmed
            person.colorHex = colorHex
            person.syncToHealth = syncToHealth
            person.goalKg = parsedGoal
        } else {
            let next = (people.map(\.sortOrder).max() ?? -1) + 1
            let new = Person(name: trimmed,
                             colorHex: colorHex,
                             syncToHealth: syncToHealth,
                             goalKg: parsedGoal,
                             sortOrder: next)
            context.insert(new)
            if prefsList.first?.selectedPersonID == nil {
                prefsList.first?.selectedPersonID = new.id
            }
        }
        try? context.save()
        dismiss()
    }
}
