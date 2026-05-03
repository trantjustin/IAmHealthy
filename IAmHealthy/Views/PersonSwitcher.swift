import SwiftUI
import SwiftData

/// Compact toolbar control: avatar chip showing active person; tap to switch or manage.
struct PersonSwitcher: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @Query private var prefsList: [UserPrefs]
    @State private var managing = false

    private var prefs: UserPrefs? { prefsList.first }
    private var active: Person? {
        guard let id = prefs?.selectedPersonID else { return people.first }
        return people.first(where: { $0.id == id }) ?? people.first
    }

    var body: some View {
        Menu {
            ForEach(people) { person in
                Button {
                    prefs?.selectedPersonID = person.id
                    try? context.save()
                } label: {
                    HStack {
                        Text(person.name)
                        if person.id == active?.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Button {
                managing = true
            } label: {
                Label("Manage People…", systemImage: "person.2")
            }
        } label: {
            HStack(spacing: 6) {
                AvatarBadge(person: active, size: 28)
                Text(active?.name ?? "—")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $managing) {
            NavigationStack { PeopleListView() }
        }
    }
}

struct AvatarBadge: View {
    let person: Person?
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle().fill(person?.color ?? .gray)
            Text(person?.initials ?? "?")
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Helper used by views to read active person reactively.
struct ActivePersonReader<Content: View>: View {
    @Query(sort: \Person.sortOrder) private var people: [Person]
    @Query private var prefsList: [UserPrefs]
    @ViewBuilder var content: (Person?) -> Content

    var body: some View {
        let prefs = prefsList.first
        let active: Person? = {
            if let id = prefs?.selectedPersonID,
               let match = people.first(where: { $0.id == id }) { return match }
            return people.first
        }()
        content(active)
    }
}
