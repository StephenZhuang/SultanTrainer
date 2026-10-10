import Foundation

/// global.json 数据模型
struct GlobalData: Codable {
    var saveTime: String
    var finishTutorial: Bool
    var inGame: Bool
    var totalRound: Int
    var totalPoint: Int
    var usedPoint: Int
    var upgrade: [String: Int]
    var quest: [String: Int]
    var achievements: [String: Bool]
    var counter: [String: Int]
    var doneRite: [Int]
    var doneEvent: [Int]
    var overID: [Int]
    var gameStatistics: [String: GameStat]
    var mods: [String]
    var hasEnterSudanBox: Bool
    var hasEnterQuest: Bool
    var backToPrevRound: Int
    var roundRollback: Int
    var overRecord: [OverRecord]
    var showedGalleryCards: [Int]
    var showedPrompt: [String]

    struct GameStat: Codable {
        var startTimes: Int
        var overTimes: Int

        private enum CodingKeys: String, CodingKey {
            case startTimes, overTimes
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            startTimes = (try? container.decode(Int.self, forKey: .startTimes)) ?? 0
            overTimes = (try? container.decode(Int.self, forKey: .overTimes)) ?? 0
        }

        init(startTimes: Int = 0, overTimes: Int = 0) {
            self.startTimes = startTimes
            self.overTimes = overTimes
        }
    }

    struct OverRecord: Codable {
        var overID: Int
        var round: Int
        var name: String

        private enum CodingKeys: String, CodingKey {
            case overID, round, name
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            overID = (try? container.decode(Int.self, forKey: .overID)) ?? 0
            round = (try? container.decode(Int.self, forKey: .round)) ?? 0
            name = (try? container.decode(String.self, forKey: .name)) ?? ""
        }

        init(overID: Int, round: Int, name: String = "") {
            self.overID = overID
            self.round = round
            self.name = name
        }
    }

    // MARK: - Codable 容错解码

    private enum CodingKeys: String, CodingKey {
        case saveTime, finishTutorial, inGame, totalRound, totalPoint, usedPoint
        case upgrade, quest, achievements, counter, doneRite, doneEvent, overID
        case gameStatistics, mods, hasEnterSudanBox, hasEnterQuest, backToPrevRound
        case roundRollback, overRecord, showedGalleryCards, showedPrompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        saveTime = (try? container.decode(String.self, forKey: .saveTime)) ?? ""
        finishTutorial = (try? container.decode(Bool.self, forKey: .finishTutorial)) ?? false
        inGame = (try? container.decode(Bool.self, forKey: .inGame)) ?? false
        totalRound = (try? container.decode(Int.self, forKey: .totalRound)) ?? 0
        totalPoint = (try? container.decode(Int.self, forKey: .totalPoint)) ?? 0
        usedPoint = (try? container.decode(Int.self, forKey: .usedPoint)) ?? 0
        upgrade = (try? container.decode([String: Int].self, forKey: .upgrade)) ?? [:]
        quest = (try? container.decode([String: Int].self, forKey: .quest)) ?? [:]
        achievements = (try? container.decode([String: Bool].self, forKey: .achievements)) ?? [:]
        counter = (try? container.decode([String: Int].self, forKey: .counter)) ?? [:]
        doneRite = (try? container.decode([Int].self, forKey: .doneRite)) ?? []
        doneEvent = (try? container.decode([Int].self, forKey: .doneEvent)) ?? []
        overID = (try? container.decode([Int].self, forKey: .overID)) ?? []
        gameStatistics = (try? container.decode([String: GameStat].self, forKey: .gameStatistics)) ?? [:]
        mods = (try? container.decode([String].self, forKey: .mods)) ?? []
        hasEnterSudanBox = (try? container.decode(Bool.self, forKey: .hasEnterSudanBox)) ?? false
        hasEnterQuest = (try? container.decode(Bool.self, forKey: .hasEnterQuest)) ?? false
        backToPrevRound = (try? container.decode(Int.self, forKey: .backToPrevRound)) ?? 0
        roundRollback = (try? container.decode(Int.self, forKey: .roundRollback)) ?? 0
        overRecord = (try? container.decode([OverRecord].self, forKey: .overRecord)) ?? []
        showedGalleryCards = (try? container.decode([Int].self, forKey: .showedGalleryCards)) ?? []
        showedPrompt = (try? container.decode([String].self, forKey: .showedPrompt)) ?? []
    }
}
