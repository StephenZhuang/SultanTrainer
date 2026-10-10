import XCTest
@testable import SultanTrainer

final class RiteModelTests: XCTestCase {
    
    func testRiteDecoding() throws {
        let json = """
        {
            "uid": 5,
            "id": 5001001,
            "cards": {
                "s1": null,
                "s2": {"uid": 112},
                "s3": null,
                "s4": null,
                "s5": null,
                "s6": null,
                "s7": null
            }
        }
        """.data(using: .utf8)!
        
        let rite = try JSONDecoder().decode(Rite.self, from: json)
        XCTAssertEqual(rite.uid, 5)
        XCTAssertEqual(rite.id, 5001001)
        XCTAssertNil(rite.cards["s1"] ?? nil)
        XCTAssertEqual((rite.cards["s2"] ?? nil)?.uid, 112)
    }
    
    func testTimingRoundDecoding() throws {
        let json = """
        {"round": 5, "status": 1}
        """.data(using: .utf8)!
        
        let timing = try JSONDecoder().decode(TimingRound.self, from: json)
        XCTAssertEqual(timing.round, 5)
        XCTAssertEqual(timing.status, 1)
    }
}
