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
