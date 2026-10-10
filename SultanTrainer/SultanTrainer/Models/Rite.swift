import Foundation

/// 仪式实例
struct Rite: Codable, Identifiable, Hashable {
    var uid: Int
    var id: Int
    var cards: [String: CardReference?]
    
    /// 仪式槽位中的卡牌引用
    struct CardReference: Codable, Hashable {
        var uid: Int
    }
    
    // MARK: - Codable 容错解码
    
    private enum CodingKeys: String, CodingKey {
        case uid, id, cards
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        self.id = try container.decode(Int.self, forKey: .id)
        cards = (try? container.decode([String: CardReference?].self, forKey: .cards)) ?? [:]
    }
    
    init(uid: Int, id: Int, cards: [String: CardReference?] = [:]) {
        self.uid = uid
        self.id = id
        self.cards = cards
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
