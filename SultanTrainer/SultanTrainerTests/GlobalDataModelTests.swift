import XCTest
@testable import SultanTrainer

final class GlobalDataModelTests: XCTestCase {

    func testGlobalDataDecodingMinimal() throws {
        let json = """
        {
            "saveTime": "2026-10-10",
            "finishTutorial": true,
            "inGame": true,
            "totalRound": 10,
            "totalPoint": 637,
            "usedPoint": 614,
            "upgrade": {},
            "quest": {},
            "achievements": {},
            "counter": {},
            "doneRite": [],
            "doneEvent": [],
            "overID": [],
            "gameStatistics": {},
            "mods": [],
            "hasEnterSudanBox": true,
            "hasEnterQuest": true,
            "backToPrevRound": 5,
            "roundRollback": 0,
            "overRecord": [],
            "showedGalleryCards": [],
            "showedPrompt": []
        }
        """.data(using: .utf8)!

        let global = try JSONDecoder().decode(GlobalData.self, from: json)
        XCTAssertEqual(global.totalPoint, 637)
        XCTAssertEqual(global.usedPoint, 614)
        XCTAssertEqual(global.overID.count, 0)
    }

    func testGlobalDataDecodingWithUnknownFields() throws {
        let json = """
        {
            "saveTime": "",
            "finishTutorial": true,
            "inGame": false,
            "totalRound": 0,
            "totalPoint": 0,
            "usedPoint": 0,
            "upgrade": {},
            "quest": {},
            "achievements": {},
            "counter": {},
            "doneRite": [],
            "doneEvent": [],
            "overID": [1, 2, 3],
            "gameStatistics": {},
            "mods": [],
            "hasEnterSudanBox": false,
            "hasEnterQuest": false,
            "backToPrevRound": 0,
            "roundRollback": 0,
            "overRecord": [],
            "showedGalleryCards": [],
            "showedPrompt": [],
            "future_field": true
        }
        """.data(using: .utf8)!

        let global = try JSONDecoder().decode(GlobalData.self, from: json)
        XCTAssertEqual(global.overID, [1, 2, 3])
    }
}
