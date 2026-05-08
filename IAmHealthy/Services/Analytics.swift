import Foundation
import TelemetryDeck

/// Thin wrapper around TelemetryDeck so callsites stay free of vendor names
/// and we have one place to enforce "no PII" hygiene.
///
/// **Privacy contract:**
/// - We never pass user names, weights, dates of birth, gender, notes,
///   reminder times, or HealthKit identifiers to `signal(_:parameters:)`.
/// - Only enums (e.g. reminder frequency type) and counts (e.g. number of
///   people) are eligible. If you need to add a new parameter, double-check
///   it against this rule.
/// - TelemetryDeck itself does not collect IP, IDFA, or device identifiers
///   that can be reversed to a user; it sends a salted, hashed identifier.
enum Analytics {
    private static var started = false

    static func start() {
        guard !started else { return }
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "TelemetryDeckAppID") as? String,
              !appID.trimmingCharacters(in: .whitespaces).isEmpty else {
            AppLogger.analytics.notice("TelemetryDeckAppID missing or empty in Info.plist; analytics disabled.")
            return
        }
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
        started = true
        AppLogger.analytics.info("TelemetryDeck initialized.")
    }

    /// Send a signal. No-op if analytics never started.
    static func signal(_ name: String, parameters: [String: String] = [:]) {
        guard started else { return }
        TelemetryDeck.signal(name, parameters: parameters)
    }

    // MARK: - Named events
    // Centralizing names so we don't drift across callsites.

    enum Event {
        static let appLaunch = "App.launch"
        static let onboardingCompleted = "Onboarding.completed"
        static let weightLogged = "Weight.logged"
        static let weightDeleted = "Weight.deleted"
        static let personAdded = "Person.added"
        static let personDeleted = "Person.deleted"
        static let healthKitAuthorized = "HealthKit.authorized"
        static let healthKitDenied = "HealthKit.denied"
        static let reminderScheduled = "Reminder.scheduled"
        static let migrationFailed = "Migration.failed"
    }
}
