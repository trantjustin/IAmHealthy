import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()
    private let bodyMass = HKQuantityType(.bodyMass)

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func authorizationStatus() -> HKAuthorizationStatus {
        store.authorizationStatus(for: bodyMass)
    }

    @discardableResult
    func requestAuthorization() async throws -> Bool {
        guard isAvailable else { return false }
        try await store.requestAuthorization(toShare: [bodyMass], read: [])
        return true
    }

    @discardableResult
    func saveBodyMass(kg: Double, date: Date) async throws -> UUID {
        guard isAvailable else {
            throw NSError(domain: "HealthKit", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Health data is not available on this device."])
        }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: bodyMass, quantity: quantity, start: date, end: date)
        try await store.save(sample)
        return sample.uuid
    }

    func deleteBodyMass(uuid: UUID) async throws {
        guard isAvailable else { return }
        let predicate = HKQuery.predicateForObject(with: uuid)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            store.deleteObjects(of: bodyMass, predicate: predicate) { _, _, error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }
}
