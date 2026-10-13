import XCTest
@testable import SultanTrainer

final class AppViewModelTests: XCTestCase {

    var viewModel: AppViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AppViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertNil(viewModel.lastSaveMessage)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.saveData)
        XCTAssertNil(viewModel.globalData)
    }

    // MARK: - State Transition Tests

    func testMarkModified() {
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        viewModel.markModified()
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    // MARK: - Counter Proxy Tests

    func testSetCounter() throws {
        // 设置一个最小存档
        let save = try createMinimalSave()
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        viewModel.setCounter(id: "7000195", value: 10)

        XCTAssertEqual(viewModel.saveData?.counter["7000195"], 10)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testSetGoldCardCount() throws {
        let save = try createMinimalSave()
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        // 添加一张金币卡
        viewModel.addCard(templateId: 2000029)
        viewModel.setCounter(id: "gold", value: 999)

        if let goldCard = viewModel.saveData?.cards.first(where: { $0.templateId == 2000029 }) {
            XCTAssertEqual(goldCard.count, 999)
        } else {
            XCTFail("金币卡未找到")
        }
    }

    // MARK: - Card Proxy Tests

    func testAddCard() throws {
        let save = try createMinimalSave()
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        let initialCount = viewModel.saveData?.cards.count ?? 0
        viewModel.addCard(templateId: 2000001)

        XCTAssertEqual(viewModel.saveData?.cards.count, initialCount + 1)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testDeleteCard() throws {
        var save = try createMinimalSave()
        save.cards = [Card(uid: 1, templateId: 2000001)]
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        let result = viewModel.deleteCard(uid: 1)

        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.saveData?.cards.count, 0)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testReplaceCard() throws {
        var save = try createMinimalSave()
        save.cards = [Card(uid: 1, templateId: 2000001)]
        save.card_uid_index = 10
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        let newUid = viewModel.replaceCard(uid: 1, newTemplateId: 2000045)

        XCTAssertNotNil(newUid)
        XCTAssertEqual(viewModel.saveData?.cards.count, 1)
        XCTAssertEqual(viewModel.saveData?.cards[0].templateId, 2000045)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    // MARK: - Character Attribute Proxy Tests

    func testUpdateCharacterAttribute() throws {
        var save = try createMinimalSave()
        save.cards = [Card(uid: 1, templateId: 2000001, tag: ["physique": 2])]
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        viewModel.updateCharacterAttribute(characterUid: 1, attr: .physique, value: 10)

        XCTAssertEqual(viewModel.saveData?.cards[0].tag["physique"], 10)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testSetEquipSlot() throws {
        var save = try createMinimalSave()
        save.cards = [Card(uid: 1, templateId: 2000001, equip_slots: [])]
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        viewModel.setEquipSlot(characterUid: 1, slot: "weapon", enabled: true)

        XCTAssertTrue(viewModel.saveData?.cards[0].equip_slots.contains("weapon") ?? false)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    // MARK: - Quick Modify Proxy Tests

    func testQuickAddGold() throws {
        var save = try createMinimalSave()
        save.counter["7000100"] = 50
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        viewModel.quickAddGold()

        XCTAssertEqual(viewModel.saveData?.counter["7000100"], 1049)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testQuickMaxAttributes() throws {
        var save = try createMinimalSave()
        // 需要设置模板才能让 categorize 正确识别为人物卡
        viewModel.configLoader.cardTemplates[2000001] = CardTemplate(id: 2000001, name: "阿尔图", type: "char")
        save.cards = [Card(uid: 1, templateId: 2000001, tag: ["physique": 2])]
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        viewModel.quickMaxAttributes()

        XCTAssertEqual(viewModel.saveData?.cards[0].tag["physique"], GameConstants.attributeMaxValue)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testQuickInstantVictory() throws {
        var save = try createMinimalSave()
        save.sudan_card_pool = [Card(uid: 160, templateId: 2010001, life: 3)]
        save.success = false
        viewModel.saveData = save
        viewModel.globalData = try createMinimalGlobal()

        viewModel.quickInstantVictory()

        XCTAssertEqual(viewModel.saveData?.sudan_card_pool[0].life, 0)
        XCTAssertTrue(viewModel.saveData?.success ?? false)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    // MARK: - Helpers

    private func createMinimalSave() throws -> SaveData {
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
        return try JSONDecoder().decode(SaveData.self, from: json)
    }

    private func createMinimalGlobal() throws -> GlobalData {
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
        return try JSONDecoder().decode(GlobalData.self, from: json)
    }
}
