import XCTest
@testable import IAmHealthy

final class UnitFormatterTests: XCTestCase {
    func testKgPassthrough() {
        XCTAssertEqual(UnitFormatter.kgToDisplay(70, unit: .kg), 70, accuracy: 0.0001)
        XCTAssertEqual(UnitFormatter.displayToKg(70, unit: .kg), 70, accuracy: 0.0001)
    }

    func testKgToLb() {
        XCTAssertEqual(UnitFormatter.kgToDisplay(70, unit: .lb), 154.3236, accuracy: 0.001)
    }

    func testLbToKg() {
        XCTAssertEqual(UnitFormatter.displayToKg(154.3236, unit: .lb), 70, accuracy: 0.001)
    }

    func testRoundTrip() {
        for kg in stride(from: 40.0, through: 150.0, by: 7.5) {
            let lb = UnitFormatter.kgToDisplay(kg, unit: .lb)
            let back = UnitFormatter.displayToKg(lb, unit: .lb)
            XCTAssertEqual(back, kg, accuracy: 0.0001)
        }
    }

    func testFormatIncludesUnit() {
        XCTAssertEqual(UnitFormatter.format(70.0, unit: .kg), "70.0 kg")
        XCTAssertTrue(UnitFormatter.format(70.0, unit: .lb).hasSuffix(" lb"))
    }
}
