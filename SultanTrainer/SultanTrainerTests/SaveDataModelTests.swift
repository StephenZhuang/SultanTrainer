import XCTest
@testable import SultanTrainer

final class SaveDataModelTests: XCTestCase {

    func testSaveDataDecodingMinimal() throws {
        let json = """
        {
            "configId": 1,
            "configVersion": 0,
            "name": "哈兰德",
            "difficulty": 3,
            "round": 1,
            "min_round": 0,
            "saveTime": "2026-10-10T00:00:00Z",
            "card_uid_index": 261,
            "rite_uid_index": 7,
            "success": false,
            "over_reason": -2147483648,
            "cards": [],
            "rites": [],
            "sudan_card_pool": [],
            "counter": {},
            "event_status": {},
            "timing_rounds": {},
            "gen_cards": {},
            "gen_tags": {},
            "ithink_card": null
        }
        """.data(using: .utf8)!

        let save = try JSONDecoder().decode(SaveData.self, from: json)
        XCTAssertEqual(save.configId, 1)
        XCTAssertEqual(save.name, "哈兰德")
        XCTAssertEqual(save.cards.count, 0)
        XCTAssertEqual(save.card_uid_index, 261)
    }

    func testSaveDataDecodingWithUnknownFields() throws {
        let json = """
        {
            "configId": 1,
            "configVersion": 0,
            "name": "Test",
            "difficulty": 1,
            "round": 1,
            "min_round": 0,
            "saveTime": "",
            "card_uid_index": 1,
            "rite_uid_index": 1,
            "success": false,
            "over_reason": 0,
            "cards": [],
            "rites": [],
            "sudan_card_pool": [],
            "counter": {},
            "event_status": {},
            "timing_rounds": {},
            "gen_cards": {},
            "gen_tags": {},
            "ithink_card": null,
            "new_future_field": 123
        }
        """.data(using: .utf8)!

        let save = try JSONDecoder().decode(SaveData.self, from: json)
        XCTAssertEqual(save.configId, 1)
    }

    func testSaveDataRoundTrip() throws {
        let json = """
        {
            "configId": 1,
            "configVersion": 0,
            "name": "Test",
            "difficulty": 1,
            "round": 5,
            "min_round": 0,
            "saveTime": "2026-10-10",
            "card_uid_index": 10,
            "rite_uid_index": 2,
            "success": true,
            "over_reason": 0,
            "cards": [],
            "rites": [],
            "sudan_card_pool": [],
            "counter": {"7000195": 5},
            "event_status": {},
            "timing_rounds": {},
            "gen_cards": {},
            "gen_tags": {},
            "ithink_card": null
        }
        """.data(using: .utf8)!

        let save = try JSONDecoder().decode(SaveData.self, from: json)
        let encoded = try JSONEncoder().encode(save)
        let decoded = try JSONDecoder().decode(SaveData.self, from: encoded)
        XCTAssertEqual(decoded.round, 5)
        XCTAssertEqual(decoded.success, true)
        XCTAssertEqual(decoded.counter["7000195"], 5)
    }
}
