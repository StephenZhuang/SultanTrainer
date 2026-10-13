import XCTest
@testable import SultanTrainer

final class EnumsTests: XCTestCase {
    
    func testCardCategoryAllCases() {
        XCTAssertEqual(CardCategory.allCases.count, 5)
    }
    
    func testAttributeTypeAllCases() {
        XCTAssertEqual(AttributeType.allCases.count, 9)
    }
    
    func testAttributeTypeRawValues() {
        XCTAssertEqual(AttributeType.physique.rawValue, "physique")
        XCTAssertEqual(AttributeType.charm.rawValue, "charm")
        XCTAssertEqual(AttributeType.wisdom.rawValue, "wisdom")
        XCTAssertEqual(AttributeType.conceal.rawValue, "conceal")
        XCTAssertEqual(AttributeType.battle.rawValue, "battle")
        XCTAssertEqual(AttributeType.social.rawValue, "social")
        XCTAssertEqual(AttributeType.survival.rawValue, "survival")
    }
    
    func testCounterScopeFromId() {
        XCTAssertEqual(CounterScope(fromId: "7000195"), .session)
        XCTAssertEqual(CounterScope(fromId: "7100001"), .persistent)
        XCTAssertEqual(CounterScope(fromId: "7200131"), .achievement)
        XCTAssertEqual(CounterScope(fromId: "7210001"), .crossSession)
        XCTAssertEqual(CounterScope(fromId: "7220001"), .completion)
        XCTAssertEqual(CounterScope(fromId: "7230001"), .unlock)
        XCTAssertNil(CounterScope(fromId: "9999999"))
    }
    
    func testSidebarItemAllCases() {
        XCTAssertEqual(SidebarItem.allCases.count, 6)
    }
}
