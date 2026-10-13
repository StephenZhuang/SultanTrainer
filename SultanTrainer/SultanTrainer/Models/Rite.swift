import Foundation

/// 仪式实例
struct Rite: Codable, Identifiable, Hashable {
    var uid: Int
    var id: Int
    var cards: [Card?]
    
    // MARK: - Codable 容错解码
    
    private enum CodingKeys: String, CodingKey {
        case uid, id, cards
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        self.id = try container.decode(Int.self, forKey: .id)
        cards = (try? container.decode([Card?].self, forKey: .cards)) ?? []
    }
    
    init(uid: Int, id: Int, cards: [Card?] = []) {
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
