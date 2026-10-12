import XCTest
@testable import SultanTrainer

final class CardModelTests: XCTestCase {
    
    func testCardDecoding() throws {
        let json = """
        {
            "uid": 29,
            "id": 2000001,
            "count": 1,
            "life": 0,
            "rareup": 0,
            "tag": {"physique": 2, "charm": 2},
            "equip_slots": ["weapon", "cloth"],
            "equips": [],
            "bag": 0,
            "bagpos": 15,
            "custom_name": "",
            "custom_text": ""
        }
        """.data(using: .utf8)!
        
        let card = try JSONDecoder().decode(Card.self, from: json)
        XCTAssertEqual(card.uid, 29)
        XCTAssertEqual(card.templateId, 2000001)
        XCTAssertEqual(card.count, 1)
        XCTAssertEqual(card.life, 0)
        XCTAssertEqual(card.tag["physique"], 2)
        XCTAssertEqual(card.equip_slots, ["weapon", "cloth"])
    }
    
    func testCardDecodingWithUnknownFields() throws {
        let json = """
        {
            "uid": 1,
            "id": 2000001,
            "count": 1,
            "life": 0,
            "rareup": 0,
            "tag": {},
            "equip_slots": [],
            "equips": [],
            "bag": 0,
            "bagpos": 0,
            "custom_name": "",
            "custom_text": "",
            "future_field": "should_be_ignored"
        }
        """.data(using: .utf8)!
        
        let card = try JSONDecoder().decode(Card.self, from: json)
        XCTAssertEqual(card.uid, 1)
    }
    
    func testCardDecodingWithMissingOptionalFields() throws {
        let json = """
        {
            "uid": 1,
            "id": 2000001,
            "count": 1,
            "life": 0,
            "rareup": 0,
            "tag": {},
            "equip_slots": [],
            "equips": []
        }
        """.data(using: .utf8)!
        
        let card = try JSONDecoder().decode(Card.self, from: json)
        XCTAssertEqual(card.bag, 0)
        XCTAssertEqual(card.bagpos, 0)
        XCTAssertEqual(card.custom_name, "")
        XCTAssertEqual(card.custom_text, "")
    }
    
    func testCardIdentifiable() {
        let card = Card(uid: 42, templateId: 2000001)
        XCTAssertEqual(card.id, 42)
    }
}
