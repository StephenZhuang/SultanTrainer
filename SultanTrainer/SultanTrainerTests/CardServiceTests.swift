import XCTest
@testable import SultanTrainer

final class CardServiceTests: XCTestCase {
    
    var cardService: CardService!
    var configLoader: ConfigLoader!
    
    override func setUp() {
        super.setUp()
        configLoader = ConfigLoader()
        configLoader.cardTemplates[2000001] = CardTemplate(templateId: 2000001, name: "阿尔图")
        configLoader.cardTemplates[2000045] = CardTemplate(templateId: 2000045, name: "长剑", equip_slots: ["weapon"])
        configLoader.cardTemplates[2010001] = CardTemplate(id: 2010001, name: "苏丹卡1")
        cardService = CardService(configLoader: configLoader)
    }
    
    func testAddCard() {
        var save = createMinimalSave()
        save.card_uid_index = 100
        
        cardService.addCard(to: &save, templateId: 2000001)
        
        XCTAssertEqual(save.cards.count, 1)
        XCTAssertEqual(save.cards[0].templateId, 2000001)
        XCTAssertEqual(save.cards[0].uid, 100)
        XCTAssertEqual(save.card_uid_index, 101)
    }
    
    func testDeleteCard() {
        var save = createMinimalSave()
        save.cards = [
            Card(uid: 1, templateId: 2000001),
            Card(uid: 2, templateId: 2000045)
        ]
        
        let deleted = cardService.deleteCard(from: &save, cardUid: 1)
        
        XCTAssertTrue(deleted)
        XCTAssertEqual(save.cards.count, 1)
        XCTAssertEqual(save.cards[0].uid, 2)
    }
    
    func testDeleteCardReferencedByRite() {
        var save = createMinimalSave()
        save.cards = [Card(uid: 1, templateId: 2000001)]
        save.rites = [Rite(uid: 1, id: 5001001, cards: [Card(uid: 1, templateId: 2000001)])]
        
        let deleted = cardService.deleteCard(from: &save, cardUid: 1)
        
        XCTAssertFalse(deleted)
        XCTAssertEqual(save.cards.count, 1)
    }
    
    func testReplaceCard() {
        var save = createMinimalSave()
        save.cards = [Card(uid: 1, templateId: 2000001)]
        save.card_uid_index = 10
        
        cardService.replaceCard(in: &save, cardUid: 1, newTemplateId: 2000045)
        
        XCTAssertEqual(save.cards.count, 1)
        XCTAssertEqual(save.cards[0].templateId, 2000045)
        XCTAssertEqual(save.cards[0].uid, 10)
        XCTAssertEqual(save.card_uid_index, 11)
    }
    
    func testIsCardInRite() {
        var save = createMinimalSave()
        save.cards = [Card(uid: 1, templateId: 2000001), Card(uid: 2, templateId: 2000045)]
        save.rites = [Rite(uid: 1, id: 5001001, cards: [Card(uid: 1, templateId: 2000001)])]
        
        XCTAssertTrue(cardService.isCardInRite(save: save, cardUid: 1))
        XCTAssertFalse(cardService.isCardInRite(save: save, cardUid: 2))
    }
    
    func testUpdateCharacterAttribute() {
        var save = createMinimalSave()
        save.cards = [Card(uid: 1, templateId: 2000001, tag: ["physique": 2, "charm": 3])]
        
        cardService.updateCharacterAttribute(in: &save, characterUid: 1, attribute: .physique, value: 10)
        
        XCTAssertEqual(save.cards[0].tag["physique"], 10)
        XCTAssertEqual(save.cards[0].tag["charm"], 3)
    }
    
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
}
