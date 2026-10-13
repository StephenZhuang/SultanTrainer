import XCTest
@testable import SultanTrainer

final class CardTemplateTests: XCTestCase {

    // MARK: - TagTemplate decodeBool tests

    func testDecodeBoolFromInt() throws {
        let json = """
        {
            "id": 1,
            "name": "测试标签",
            "code": "test",
            "tag_rank": 0,
            "can_visible": 1,
            "can_inherit": 0,
            "can_add": true,
            "type": "",
            "can_nagiative_and_zero": false
        }
        """.data(using: .utf8)!

        let tag = try JSONDecoder().decode(TagTemplate.self, from: json)
        XCTAssertTrue(tag.can_visible)
        XCTAssertFalse(tag.can_inherit)
        XCTAssertTrue(tag.can_add)
        XCTAssertFalse(tag.can_nagiative_and_zero)
    }

    func testDecodeBoolFromBool() throws {
        let json = """
        {
            "id": 2,
            "name": "测试标签2",
            "code": "test2",
            "tag_rank": 0,
            "can_visible": true,
            "can_inherit": false,
            "can_add": 1,
            "type": "",
            "can_nagiative_and_zero": 0
        }
        """.data(using: .utf8)!

        let tag = try JSONDecoder().decode(TagTemplate.self, from: json)
        XCTAssertTrue(tag.can_visible)
        XCTAssertFalse(tag.can_inherit)
        XCTAssertTrue(tag.can_add)
        XCTAssertFalse(tag.can_nagiative_and_zero)
    }

    // MARK: - CardTemplate decoding tests

    func testCardTemplateDecodeWithEquipsMapping() throws {
        let json = """
        {
            "id": 2000045,
            "name": "长剑",
            "text": "一把锋利的剑",
            "type": "item",
            "title": "武器",
            "tag": {"战斗": 5},
            "equips": ["武器", "服装"],
            "rare": 3,
            "is_only": false
        }
        """.data(using: .utf8)!

        let template = try JSONDecoder().decode(CardTemplate.self, from: json)
        XCTAssertEqual(template.id, 2000045)
        XCTAssertEqual(template.name, "长剑")
        XCTAssertEqual(template.equip_slots, ["武器", "服装"])
        XCTAssertEqual(template.rare, 3)
        XCTAssertFalse(template.is_only)
    }

    func testCardTemplateDecodeIsOnlyFromInt() throws {
        let json = """
        {
            "id": 2000001,
            "name": "阿尔图",
            "text": "主角",
            "type": "char",
            "title": "主角",
            "tag": {},
            "equips": [],
            "rare": 5,
            "is_only": 1
        }
        """.data(using: .utf8)!

        let template = try JSONDecoder().decode(CardTemplate.self, from: json)
        XCTAssertTrue(template.is_only)
    }

    func testCardTemplateDecodeIsOnlyFromBool() throws {
        let json = """
        {
            "id": 2000002,
            "name": "测试卡",
            "text": "",
            "type": "item",
            "title": "其他",
            "tag": {},
            "equips": [],
            "rare": 1,
            "is_only": true
        }
        """.data(using: .utf8)!

        let template = try JSONDecoder().decode(CardTemplate.self, from: json)
        XCTAssertTrue(template.is_only)
    }

    func testCardTemplateDecodeIsOnlyDefaultFalse() throws {
        let json = """
        {
            "id": 2000003,
            "name": "测试卡2",
            "text": "",
            "type": "item",
            "title": "其他",
            "tag": {},
            "equips": [],
            "rare": 1
        }
        """.data(using: .utf8)!

        let template = try JSONDecoder().decode(CardTemplate.self, from: json)
        XCTAssertFalse(template.is_only)
    }
}
