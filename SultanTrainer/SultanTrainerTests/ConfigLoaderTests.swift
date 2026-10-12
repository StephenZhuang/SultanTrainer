// SultanTrainerTests/ConfigLoaderTests.swift
import XCTest
@testable import SultanTrainer

final class ConfigLoaderTests: XCTestCase {
    
    func testLocateConfigDirectoryKnownPath() {
        let loader = ConfigLoader()
        let knownPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Steam/steamapps/common/Sultan's Game/Sultan's Game.app/Contents/Resources/Data/StreamingAssets/config")
        
        if FileManager.default.fileExists(atPath: knownPath.path) {
            let result = loader.locateConfigDirectory()
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.path, knownPath.path)
        }
    }
    
    func testGetCardNameWithLoadedTemplate() {
        let loader = ConfigLoader()
        loader.cardTemplates[2000001] = CardTemplate(id: 2000001, name: "阿尔图")
        XCTAssertEqual(loader.getCardName(id: 2000001), "阿尔图")
    }
    
    func testGetCardNameFallbackToId() {
        let loader = ConfigLoader()
        XCTAssertEqual(loader.getCardName(id: 9999999), "9999999")
    }
    
    func testCategorizeCard() {
        let loader = ConfigLoader()

        let character = CardTemplate(id: 2000001, name: "阿尔图", type: "char")
        XCTAssertEqual(loader.categorize(template: character), .character)

        let sudan = CardTemplate(id: 2010001, name: "苏丹卡1", type: "sudan")
        XCTAssertEqual(loader.categorize(template: sudan), .sudan)

        let weapon = CardTemplate(id: 2000045, name: "长剑", type: "item", equip_slots: ["武器"])
        XCTAssertEqual(loader.categorize(template: weapon), .equipment)

        let book = CardTemplate(id: 2000100, name: "古书", type: "item", tag: ["读物": 1])
        XCTAssertEqual(loader.categorize(template: book), .book)

        let other = CardTemplate(id: 2000090, name: "金币", type: "item")
        XCTAssertEqual(loader.categorize(template: other), .other)
    }
}
