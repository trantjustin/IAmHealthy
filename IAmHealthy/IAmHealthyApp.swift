import SwiftUI
import SwiftData

@main
struct IAmHealthyApp: App {
    let container: ModelContainer

    init() {
        container = IAmHealthyApp.makeContainer()
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // With a proper migration plan in place this should never fire
            // for end users. If it does, crashing is preferable to silently
            // wiping the local store and losing the user's data — it lets
            // us see and respond to the failure instead.
            fatalError("Failed to create ModelContainer: \(error)")
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
