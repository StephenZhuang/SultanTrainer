import XCTest
@testable import SultanTrainer

final class RiteModelTests: XCTestCase {
    
    func testRiteDecoding() throws {
        let json = """
        {
            "uid": 5,
            "id": 5001001,
            "cards": [
                null,
                {"uid": 112, "id": 2000001, "count": 1, "life": 0, "rareup": 0, "tag": {}, "equip_slots": [], "equips": [], "bag": 0, "bagpos": 0, "custom_name": "", "custom_text": ""},
                null,
                null,
                null,
                null,
                null
            ]
        }
        """.data(using: .utf8)!
        
        let rite = try JSONDecoder().decode(Rite.self, from: json)
        XCTAssertEqual(rite.uid, 5)
        XCTAssertEqual(rite.id, 5001001)
        XCTAssertEqual(rite.cards.count, 7)
        XCTAssertNil(rite.cards[0])
        XCTAssertEqual(rite.cards[1]?.uid, 112)
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
