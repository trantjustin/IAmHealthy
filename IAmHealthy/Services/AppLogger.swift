import Foundation
import os

/// Centralized loggers. Filter in Console.app by subsystem
/// `com.jtrant.i-am-healthy` to see only our messages, or by category to
/// narrow further (e.g. `swiftdata`, `healthkit`, `analytics`).
enum AppLogger {
    static let subsystem = "com.jtrant.i-am-healthy"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let swiftData = Logger(subsystem: subsystem, category: "swiftdata")
    static let healthKit = Logger(subsystem: subsystem, category: "healthkit")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let analytics = Logger(subsystem: subsystem, category: "analytics")
}
