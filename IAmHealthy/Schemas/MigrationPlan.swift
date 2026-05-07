import Foundation
import SwiftData

/// Single source of truth for SwiftData schema evolution.
///
/// `schemas` lists every released `VersionedSchema`, oldest first. The last
/// entry is the current schema. `stages` lists migration steps between
/// consecutive versions. A lightweight stage covers additive changes
/// (new optional fields, new models); custom stages are needed for
/// rename / type-change / data-transform migrations.
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet — V1 is the initial released schema.
        []
    }
}
