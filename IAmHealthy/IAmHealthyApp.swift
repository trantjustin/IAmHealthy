import SwiftUI
import SwiftData

@main
struct IAmHealthyApp: App {
    let container: ModelContainer

    init() {
        container = IAmHealthyApp.makeContainer()
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([WeightEntry.self, UserPrefs.self, Person.self])
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema mismatch (typically during development after adding /
            // renaming model fields). Nuke the on-disk store and retry —
            // we don't ship migrations yet.
            wipePersistentStore()
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer after wipe: \(error)")
            }
        }
    }

    private static func wipePersistentStore() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        // SwiftData writes default.store plus -shm / -wal sidecar files.
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? fm.removeItem(at: appSupport.appendingPathComponent(name))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task {
                    _ = try? await HealthKitService.shared.requestAuthorization()
                    _ = try? await NotificationService.shared.requestAuthorization()
                }
        }
        .modelContainer(container)
    }
}
