import XCTest
@testable import SultanTrainer

final class QuickModifiersTests: XCTestCase {

    var modifiers: QuickModifiers!

    override func setUp() {
        super.setUp()
        modifiers = QuickModifiers()
    }

    func testAddGold() {
        var save = createMinimalSave()
        save.counter["7000100"] = 50

        modifiers.addGold(to: &save, amount: 999)

        XCTAssertEqual(save.counter["7000100"], 1049)
    }

    func testAddGoldNoExistingCounter() {
        var save = createMinimalSave()

        modifiers.addGold(to: &save, amount: 999)

        XCTAssertEqual(save.counter["7000100"], 999)
    }

    func testAddGoldNegativeAmount() {
        var save = createMinimalSave()
        save.counter["7000100"] = 500

        modifiers.addGold(to: &save, amount: -200)

        XCTAssertEqual(save.counter["7000100"], 300)
    }

    func testInstantVictoryEmptyPool() {
        var save = createMinimalSave()
        // 苏丹卡池为空
        save.sudan_card_pool = []
        save.success = false

        modifiers.instantVictory(in: &save)

        XCTAssertTrue(save.sudan_card_pool.isEmpty)
        XCTAssertTrue(save.success)
    }

    func testMaxAllAttributes() {
        var save = createMinimalSave()
        save.cards = [
            Card(uid: 1, templateId: 2000001, tag: ["physique": 2, "charm": 3, "wisdom": 1, "conceal": 1, "battle": 1, "social": 1, "survival": 1])
        ]

        modifiers.maxAllAttributes(in: &save, characterUid: 1)

        XCTAssertEqual(save.cards[0].tag["physique"], 999)
        XCTAssertEqual(save.cards[0].tag["charm"], 999)
        XCTAssertEqual(save.cards[0].tag["wisdom"], 999)
        XCTAssertEqual(save.cards[0].tag["conceal"], 999)
        XCTAssertEqual(save.cards[0].tag["battle"], 999)
        XCTAssertEqual(save.cards[0].tag["social"], 999)
        XCTAssertEqual(save.cards[0].tag["survival"], 999)
    }

    func testInstantVictory() {
        var save = createMinimalSave()
        save.sudan_card_pool = [
            Card(uid: 160, templateId: 2010001, life: 3),
            Card(uid: 161, templateId: 2010002, life: 5)
        ]
        save.success = false

        modifiers.instantVictory(in: &save)

        for card in save.sudan_card_pool {
            XCTAssertEqual(card.life, 0)
        }
        XCTAssertTrue(save.success)
    }

    func testUnlockAllEndings() {
        var global = createMinimalGlobal()
        global.overID = [0]

        let allEndingIds = [0, 1, 2, 3, 4, 5]
        modifiers.unlockAllEndings(in: &global, allEndingIds: allEndingIds)

        XCTAssertEqual(Set(global.overID), Set(allEndingIds))
    }

    func testAddUpgradePoints() {
        var global = createMinimalGlobal()
        global.totalPoint = 100

        modifiers.addUpgradePoints(to: &global, amount: 100)

        XCTAssertEqual(global.totalPoint, 200)
    }

    // MARK: - Helpers

    private func createMinimalSave() -> SaveData {
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

    private func createMinimalGlobal() -> GlobalData {
        let json = """
        {
            "saveTime": "", "finishTutorial": true, "inGame": true,
            "totalRound": 0, "totalPoint": 0, "usedPoint": 0,
            "upgrade": {}, "quest": {}, "achievements": {}, "counter": {},
            "doneRite": [], "doneEvent": [], "overID": [],
            "gameStatistics": {}, "mods": [],
            "hasEnterSudanBox": false, "hasEnterQuest": false,
            "backToPrevRound": 0, "roundRollback": 0,
            "overRecord": [], "showedGalleryCards": [], "showedPrompt": []
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(GlobalData.self, from: json)
    }
}
