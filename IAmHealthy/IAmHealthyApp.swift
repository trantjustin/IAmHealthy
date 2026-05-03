import SwiftUI
import SwiftData

@main
struct IAmHealthyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: WeightEntry.self, UserPrefs.self, Person.self)
        } catch {
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
