import Foundation
import SwiftData

/// Initial released schema. The model types themselves live at the top level
/// (Models/) so the rest of the app can reference them directly. This enum
/// exists only to register them with SwiftData under a stable version
/// identifier so future migrations are possible.
///
/// **Adding a new schema version:**
/// 1. Create `SchemaV2.swift` with copies of any models whose shape changed.
///    (Unchanged models can be referenced from V1.)
/// 2. Bump `versionIdentifier`.
/// 3. Add a corresponding `MigrationStage` (lightweight or custom) to
///    `AppMigrationPlan.stages`.
/// 4. Update `AppMigrationPlan.schemas` to include the new version, with
///    the latest version listed last.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [WeightEntry.self, UserPrefs.self, Person.self]
    }
}
