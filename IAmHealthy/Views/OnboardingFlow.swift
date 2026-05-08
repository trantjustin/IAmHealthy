import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let prefs: UserPrefs
    let person: Person

    @State private var step = 0
    @State private var name = ""
    @State private var dob: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var hasDOB = false
    @State private var gender: Gender = .preferNotToSay
    @State private var unit: WeightUnit = {
        Locale.current.measurementSystem == .us ? .lb : .kg
    }()

    var body: some View {
        NavigationStack {
            VStack {
                ProgressDots(count: 2, current: step)
                    .padding(.top, 8)
                Group {
                    if step == 0 {
                        aboutYouStep
                    } else {
                        unitStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.2), value: step)
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Step 1: About you

    private var aboutYouStep: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Welcome!")
                .font(.title.bold())
            Text("Tell us a little about yourself. You can change any of this later.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Form {
                Section {
                    TextField("Your name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section {
                    Toggle("Add date of birth", isOn: $hasDOB.animation())
                    if hasDOB {
                        DatePicker("Date of birth",
                                   selection: $dob,
                                   in: ...Date(),
                                   displayedComponents: .date)
                    }
                } footer: {
                    if hasDOB {
                        let years = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
                        Text("Age: \(years)")
                    }
                }
                Section("Gender") {
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases) { g in
                            Text(g.label).tag(g)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .scrollContentBackground(.hidden)

            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Step 2: Units

    private var unitStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "scalemass.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Choose your units")
                .font(.title.bold())
            Text("Pick how you'd like to see weights. You can change this later in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Picker("Unit", selection: $unit) {
                ForEach(WeightUnit.allCases) { u in
                    Text(u.label).tag(u)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("Back") { withAnimation { step = 0 } }
                    .buttonStyle(.bordered)
                Spacer()
                Button {
                    finish()
                } label: {
                    Text("Get started")
                        .font(.headline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func finish() {
        person.name = name.trimmingCharacters(in: .whitespaces)
        person.dateOfBirth = hasDOB ? dob : nil
        person.gender = gender
        prefs.unit = unit
        prefs.unitChosen = true
        prefs.onboardingCompleted = true
        try? context.save()
        Analytics.signal(Analytics.Event.onboardingCompleted, parameters: [
            "unit": unit.short,
            "providedDOB": hasDOB ? "true" : "false"
        ])
        dismiss()
    }
}

private struct ProgressDots: View {
    let count: Int
    let current: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: i == current ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }
}
