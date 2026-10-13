import Foundation

/// 仪式模板，来自 config/rite/ 目录
struct RiteTemplate: Codable, Identifiable {
    var id: Int
    var name: String
    var text: String
    var waitingRound: Int

    private enum CodingKeys: String, CodingKey {
        case id, name, text
        case waitingRound = "waiting_round"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
        waitingRound = (try? container.decode(Int.self, forKey: .waitingRound)) ?? 0
    }

    init(id: Int, name: String = "", text: String = "", waitingRound: Int = 0) {
        self.id = id
        self.name = name
        self.text = text
        self.waitingRound = waitingRound
    }
}

/// 仪式实例
struct Rite: Codable, Identifiable, Hashable {
    var uid: Int
    var id: Int
    var newBorn: Bool
    var isShow: Bool
    var start: Bool
    var startRound: Int
    var startLife: Int
    var life: Int
    var cards: [Card?]
    var customName: String

    // MARK: - Codable 容错解码

    private enum CodingKeys: String, CodingKey {
        case uid, id
        case newBorn = "new_born"
        case isShow = "is_show"
        case start
        case startRound = "start_round"
        case startLife = "start_life"
        case life
        case cards
        case customName = "custom_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        self.id = try container.decode(Int.self, forKey: .id)
        newBorn = (try? container.decode(Bool.self, forKey: .newBorn)) ?? false
        isShow = (try? container.decode(Bool.self, forKey: .isShow)) ?? true
        start = (try? container.decode(Bool.self, forKey: .start)) ?? false
        startRound = (try? container.decode(Int.self, forKey: .startRound)) ?? 0
        startLife = (try? container.decode(Int.self, forKey: .startLife)) ?? 0
        life = (try? container.decode(Int.self, forKey: .life)) ?? 0
        cards = (try? container.decode([Card?].self, forKey: .cards)) ?? []
        customName = (try? container.decode(String.self, forKey: .customName)) ?? ""
    }

    init(uid: Int, id: Int, newBorn: Bool = false, isShow: Bool = true, start: Bool = false,
         startRound: Int = 0, startLife: Int = 0, life: Int = 0, cards: [Card?] = [], customName: String = "") {
        self.uid = uid
        self.id = id
        self.newBorn = newBorn
        self.isShow = isShow
        self.start = start
        self.startRound = startRound
        self.startLife = startLife
        self.life = life
        self.cards = cards
        self.customName = customName
    }
}

/// 定时事件调度
struct TimingRound: Codable, Hashable {
    var round: Int
    var status: Int
    
    private enum CodingKeys: String, CodingKey {
        case round, status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.round = (try? container.decode(Int.self, forKey: .round)) ?? 0
        status = (try? container.decode(Int.self, forKey: .status)) ?? 0
    }
    
    init(round: Int, status: Int) {
        self.round = round
        self.status = status
    }
}

/// 仪式槽位数据（用于 last_round_rite_data）
struct RiteSlotData: Codable, Hashable {
    var id: Int
    var count: Int

    private enum CodingKeys: String, CodingKey {
        case id, count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(Int.self, forKey: .id)) ?? 0
        count = (try? container.decode(Int.self, forKey: .count)) ?? 0
    }

    init(id: Int, count: Int) {
        self.id = id
        self.count = count
    }
}
