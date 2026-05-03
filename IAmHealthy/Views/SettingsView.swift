import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var prefsList: [UserPrefs]
    @Query(sort: \Person.sortOrder) private var people: [Person]

    private var prefs: UserPrefs? { prefsList.first }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        PeopleListView()
                    } label: {
                        HStack {
                            Image(systemName: "person.2")
                            Text("Manage People")
                            Spacer()
                            Text("\(people.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("People")
                } footer: {
                    Text("Each person has their own log, goal, and trend. Only one person can sync to Apple Health.")
                }

                Section("Units") {
                    if let prefs {
                        Picker("Unit", selection: Binding(
                            get: { prefs.unit },
                            set: { prefs.unit = $0; try? context.save() }
                        )) {
                            ForEach(WeightUnit.allCases) { u in
                                Text(u.label).tag(u)
                            }
                        }
                    }
                }

                Section("Daily reminder") {
                    if let prefs {
                        Toggle("Enable reminder", isOn: Binding(
                            get: { prefs.reminderEnabled },
                            set: { newValue in
                                prefs.reminderEnabled = newValue
                                try? context.save()
                                Task { await applyReminder() }
                            }
                        ))
                        if prefs.reminderEnabled {
                            DatePicker("Time",
                                       selection: Binding(
                                        get: { prefs.reminderTime },
                                        set: { newValue in
                                            prefs.reminderTime = newValue
                                            try? context.save()
                                            Task { await applyReminder() }
                                        }),
                                       displayedComponents: .hourAndMinute)
                        }
                    }
                }

                Section("Apple Health") {
                    Text(healthStatusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Re-request access") {
                        Task { try? await HealthKitService.shared.requestAuthorization() }
                    }
                }

                Section {
                    Text("I Am Healthy! v1.0").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func applyReminder() async {
        guard let prefs else { return }
        if prefs.reminderEnabled {
            _ = try? await NotificationService.shared.requestAuthorization()
            await NotificationService.shared.scheduleDaily(at: prefs.reminderTime)
        } else {
            NotificationService.shared.cancel()
        }
    }

    private var healthStatusText: String {
        guard HealthKitService.shared.isAvailable else { return "Health data is not available on this device." }
        switch HealthKitService.shared.authorizationStatus() {
        case .notDetermined: return "Not yet requested."
        case .sharingAuthorized: return "Write access granted. Entries from the Health-syncing person will appear in the Health app."
        case .sharingDenied: return "Write access denied. Enable it in Settings → Health → Data Access & Devices."
        @unknown default: return "Unknown status."
        }
    }
}
