import SwiftUI
import SwiftData
import os

@main
struct IAmHealthyApp: App {
    init() {
        Analytics.start()
        Analytics.signal(Analytics.Event.appLaunch)
    }

    var body: some Scene {
        WindowGroup {
            AppLauncher()
        }
    }
}

/// Root view that owns the ModelContainer lifecycle. On the first attempt
/// (and on any retry tapped from the error screen) it tries to open the
/// store with the active migration plan; if that fails, it logs the error
/// to the unified log, fires a Migration.failed analytics signal, and
/// shows ContainerErrorView with the underlying error visible to the user.
struct AppLauncher: View {
    @State private var state: LaunchState = .loading

    enum LaunchState {
        case loading
        case ready(ModelContainer)
        case failed(Error)
    }

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task { open() }
            case .ready(let container):
                RootTabView()
                    .modelContainer(container)
                    .task {
                        _ = try? await HealthKitService.shared.requestAuthorization()
                        _ = try? await NotificationService.shared.requestAuthorization()
                    }
            case .failed(let error):
                ContainerErrorView(error: error) {
                    state = .loading
                }
            }
        }
    }

    private func open() {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema)
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [config]
            )
            state = .ready(container)
        } catch {
            let ns = error as NSError
            AppLogger.swiftData.error("ModelContainer open failed: domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription) full=\(String(describing: error))")
            Analytics.signal(Analytics.Event.migrationFailed, parameters: [
                "errorDomain": ns.domain,
                "errorCode": String(ns.code)
            ])
            state = .failed(error)
        }
    }
}
