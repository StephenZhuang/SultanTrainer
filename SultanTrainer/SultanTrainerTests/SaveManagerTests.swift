import XCTest
@testable import SultanTrainer

final class SaveManagerTests: XCTestCase {

    var tempDir: URL!
    var saveManager: SaveManager!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        saveManager = SaveManager()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadSaveFromPath() throws {
        let json = """
        {
            "configId": 1,
            "configVersion": 0,
            "name": "Test",
            "difficulty": 1,
            "round": 3,
            "min_round": 0,
            "saveTime": "2026-10-10",
            "card_uid_index": 10,
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
            "ithink_card": null
        }
        """
        let fileUrl = tempDir.appendingPathComponent("auto_save.json")
        try json.write(to: fileUrl, atomically: true, encoding: .utf8)

        let save = try saveManager.loadSave(from: fileUrl)
        XCTAssertEqual(save.round, 3)
        XCTAssertEqual(save.name, "Test")
    }

    func testAtomicWrite() throws {
        let save = createMinimalSaveData()
        let fileUrl = tempDir.appendingPathComponent("test_save.json")

        try saveManager.atomicWrite(save, to: fileUrl)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileUrl.path))
        let loaded = try saveManager.loadSave(from: fileUrl)
        XCTAssertEqual(loaded.name, save.name)
    }

    func testBackupCreation() throws {
        let json = """
        {
            "configId": 1, "configVersion": 0, "name": "Test",
            "difficulty": 1, "round": 1, "min_round": 0,
            "saveTime": "", "card_uid_index": 1, "rite_uid_index": 1,
            "success": false, "over_reason": 0,
            "cards": [], "rites": [], "sudan_card_pool": [],
            "counter": {}, "event_status": {}, "timing_rounds": {},
            "gen_cards": {}, "gen_tags": {}, "ithink_card": null
        }
        """
        let fileUrl = tempDir.appendingPathComponent("auto_save.json")
        try json.write(to: fileUrl, atomically: true, encoding: .utf8)

        let backupDir = tempDir.appendingPathComponent("backups")
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        try saveManager.backupFile(at: fileUrl, to: backupDir)

        let backups = try FileManager.default.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(backups.count, 1)
        XCTAssertTrue(backups[0].lastPathComponent.hasPrefix("auto_save_"))
    }

    func testMergeWritePreservesUnmodeledFields() throws {
        // JSON with extra fields not modeled in SaveData (e.g. sudan_box_show, ui_state)
        let json = """
        {
            "configId": 1, "configVersion": 0, "name": "Test",
            "difficulty": 1, "round": 1, "min_round": 0,
            "saveTime": "", "card_uid_index": 1, "rite_uid_index": 1,
            "success": false, "over_reason": 0,
            "cards": [], "rites": [], "sudan_card_pool": [],
            "counter": {}, "event_status": {}, "timing_rounds": {},
            "gen_cards": {}, "gen_tags": {}, "ithink_card": null,
            "sudan_box_show": [1, 2, 3],
            "ui_state": {"tab": "character"},
            "custom_flag": true
        }
        """
        let fileUrl = tempDir.appendingPathComponent("auto_save.json")
        try json.write(to: fileUrl, atomically: true, encoding: .utf8)

        let save = try saveManager.loadSave(from: fileUrl)
        try saveManager.saveSave(save, to: fileUrl)

        // Read the saved file as raw JSON and verify unmodeled fields survived
        let savedData = try Data(contentsOf: fileUrl)
        let savedJson = try JSONSerialization.jsonObject(with: savedData) as? [String: Any]
        XCTAssertNotNil(savedJson?["sudan_box_show"], "sudan_box_show should be preserved")
        XCTAssertNotNil(savedJson?["ui_state"], "ui_state should be preserved")
        XCTAssertNotNil(savedJson?["custom_flag"], "custom_flag should be preserved")
        XCTAssertEqual(savedJson?["custom_flag"] as? Bool, true)
    }

    func testMergeWritePreservesCardTagFields() throws {
        // JSON with a card that has extra tag fields beyond the 9 known attributes
        let json = """
        {
            "configId": 1, "configVersion": 0, "name": "Test",
            "difficulty": 1, "round": 1, "min_round": 0,
            "saveTime": "", "card_uid_index": 2, "rite_uid_index": 0,
            "success": false, "over_reason": 0,
            "cards": [
                {
                    "uid": 1,
                    "id": 1000001,
                    "count": 1,
                    "life": 0,
                    "rareup": 0,
                    "tag": {
                        "physique": 50,
                        "charm": 30,
                        "wisdom": 40,
                        "conceal": 0,
                        "battle": 20,
                        "social": 10,
                        "survival": 15,
                        "magic": 5,
                        "knowledge": 25,
                        "own": 1,
                        "adherent": 0,
                        "sudan_card_init_life": 100,
                        "card_vanishing": 0,
                        "custom_unknown_field": 999
                    },
                    "equip_slots": [],
                    "equips": [],
                    "bag": 0,
                    "bagpos": 1,
                    "custom_name": "",
                    "custom_text": ""
                }
            ],
            "rites": [],
            "sudan_card_pool": [],
            "counter": {},
            "event_status": {},
            "timing_rounds": {},
            "gen_cards": {},
            "gen_tags": {},
            "ithink_card": null
        }
        """
        let fileUrl = tempDir.appendingPathComponent("auto_save.json")
        try json.write(to: fileUrl, atomically: true, encoding: .utf8)

        // Load and modify only the physique attribute
        var save = try saveManager.loadSave(from: fileUrl)
        if let index = save.cards.firstIndex(where: { $0.uid == 1 }) {
            save.cards[index].tag["physique"] = 60  // Change from 50 to 60
        }
        try saveManager.saveSave(save, to: fileUrl)

        // Verify that unmodeled tag fields are preserved
        let savedData = try Data(contentsOf: fileUrl)
        let savedJson = try JSONSerialization.jsonObject(with: savedData) as? [String: Any]
        let cards = savedJson?["cards"] as? [[String: Any]]
        XCTAssertNotNil(cards, "cards array should exist")
        XCTAssertEqual(cards?.count, 1)

        guard let firstCard = cards?.first,
              let tag = firstCard["tag"] as? [String: Any] else {
            XCTFail("Card or tag missing")
            return
        }

        // Modified field should have new value
        XCTAssertEqual(tag["physique"] as? Int, 60, "Modified physique should be updated")

        // Unmodified known attributes should be preserved
        XCTAssertEqual(tag["charm"] as? Int, 30)
        XCTAssertEqual(tag["wisdom"] as? Int, 40)

        // Unmodeled fields should be preserved
        XCTAssertEqual(tag["own"] as? Int, 1, "own field should be preserved")
        XCTAssertEqual(tag["adherent"] as? Int, 0, "adherent field should be preserved")
        XCTAssertEqual(tag["sudan_card_init_life"] as? Int, 100, "sudan_card_init_life should be preserved")
        XCTAssertEqual(tag["card_vanishing"] as? Int, 0, "card_vanishing should be preserved")
        XCTAssertEqual(tag["custom_unknown_field"] as? Int, 999, "Custom unknown field should be preserved")
    }

    func testMergeWriteHandlesCardDeletion() throws {
        // JSON with two cards, one has extra tag fields
        let json = """
        {
            "configId": 1, "configVersion": 0, "name": "Test",
            "difficulty": 1, "round": 1, "min_round": 0,
            "saveTime": "", "card_uid_index": 3, "rite_uid_index": 0,
            "success": false, "over_reason": 0,
            "cards": [
                {
                    "uid": 1, "id": 1000001, "count": 1, "life": 0, "rareup": 0,
                    "tag": {"physique": 50, "own": 1, "custom_x": 123},
                    "equip_slots": [], "equips": [], "bag": 0, "bagpos": 1,
                    "custom_name": "", "custom_text": ""
                },
                {
                    "uid": 2, "id": 1000002, "count": 1, "life": 0, "rareup": 0,
                    "tag": {"charm": 30, "adherent": 1},
                    "equip_slots": [], "equips": [], "bag": 0, "bagpos": 2,
                    "custom_name": "", "custom_text": ""
                }
            ],
            "rites": [], "sudan_card_pool": [],
            "counter": {}, "event_status": {}, "timing_rounds": {},
            "gen_cards": {}, "gen_tags": {}, "ithink_card": null
        }
        """
        let fileUrl = tempDir.appendingPathComponent("auto_save.json")
        try json.write(to: fileUrl, atomically: true, encoding: .utf8)

        // Delete card uid=2
        var save = try saveManager.loadSave(from: fileUrl)
        save.cards.removeAll { $0.uid == 2 }
        try saveManager.saveSave(save, to: fileUrl)

        // Verify card uid=2 is gone, uid=1 is preserved with its tag fields
        let savedData = try Data(contentsOf: fileUrl)
        let savedJson = try JSONSerialization.jsonObject(with: savedData) as? [String: Any]
        let cards = savedJson?["cards"] as? [[String: Any]]
        XCTAssertEqual(cards?.count, 1, "Should have only 1 card after deletion")

        guard let firstCard = cards?.first,
              let uid = firstCard["uid"] as? Int else {
            XCTFail("Card missing")
            return
        }
        XCTAssertEqual(uid, 1, "Remaining card should be uid=1")

        if let tag = firstCard["tag"] as? [String: Int] {
            XCTAssertEqual(tag["own"], 1, "Unmodeled field 'own' should be preserved")
            XCTAssertEqual(tag["custom_x"], 123, "Custom field should be preserved")
        }
    }

    private func createMinimalSaveData() -> SaveData {
        let json = """
        {
            "configId": 1, "configVersion": 0, "name": "Test",
            "difficulty": 1, "round": 1, "min_round": 0,
            "saveTime": "", "card_uid_index": 1, "rite_uid_index": 1,
            "success": false, "over_reason": 0,
            "cards": [], "rites": [], "sudan_card_pool": [],
            "counter": {}, "event_status": {}, "timing_rounds": {},
            "gen_cards": {}, "gen_tags": {}, "ithink_card": null
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(SaveData.self, from: json)
    }
}
