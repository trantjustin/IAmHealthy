import SwiftUI
import SwiftData

struct UnitOnboardingSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let prefs: UserPrefs

    @State private var selection: WeightUnit = {
        Locale.current.measurementSystem == .us ? .lb : .kg
    }()

    var body: some View {
        NavigationStack {
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
                    .padding(.horizontal)

                Picker("Unit", selection: $selection) {
                    ForEach(WeightUnit.allCases) { u in
                        Text(u.label).tag(u)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Spacer()

                Button {
                    prefs.unit = selection
                    prefs.unitChosen = true
                    try? context.save()
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .interactiveDismissDisabled(true)
    }
}
