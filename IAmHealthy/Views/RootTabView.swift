import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var prefsList: [UserPrefs]
    @Query(sort: \Person.sortOrder) private var people: [Person]

    var body: some View {
        ZStack(alignment: .topLeading) {
            TabView {
                LogView()
                    .tabItem { Label("Log", systemImage: "list.bullet") }
                TrendView()
                    .tabItem { Label("Trend", systemImage: "chart.xyaxis.line") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }

            if let prefs = prefsList.first,
               prefs.onboardingCompleted,
               !prefs.hasSeenPeopleTip {
                PeopleTipOverlay {
                    prefs.hasSeenPeopleTip = true
                    try? context.save()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .task { bootstrap() }
        .sheet(isPresented: Binding(
            get: { prefsList.first.map { !$0.onboardingCompleted } ?? false },
            set: { _ in }
        )) {
            if let prefs = prefsList.first, let me = primaryPerson() {
                OnboardingFlow(prefs: prefs, person: me)
            }
        }
    }

    private func primaryPerson() -> Person? {
        if let id = prefsList.first?.selectedPersonID,
           let match = people.first(where: { $0.id == id }) { return match }
        return people.first
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

/// Translucent tooltip overlay shown once after onboarding, pointing at the
/// top-left person switcher in the Log/Trend tab toolbars.
struct PeopleTipOverlay: View {
    let dismiss: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(alignment: .leading, spacing: 0) {
                // Arrow on the left side of the card, pointing up at the
                // top-leading avatar in the toolbar.
                Triangle()
                    .fill(Color(.systemBackground))
                    .frame(width: 16, height: 10)
                    .padding(.leading, 22)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.tint)
                        Text("Track multiple people")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("Tap your avatar to switch profiles or add family.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Got it", action: dismiss)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.18), radius: 10, y: 3)
                )
            }
            .frame(maxWidth: 280, alignment: .leading)
            .padding(.top, 48) // just under the toolbar (avatar + user's name)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
