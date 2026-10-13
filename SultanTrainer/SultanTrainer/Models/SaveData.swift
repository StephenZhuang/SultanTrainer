import Foundation

/// auto_save.json 数据模型
struct SaveData: Codable {
    var configId: Int
    var configVersion: Int
    var name: String
    var difficulty: Int
    var round: Int
    var min_round: Int
    var saveTime: String
    var card_uid_index: Int
    var rite_uid_index: Int
    var success: Bool
    var over_reason: Int
    var cards: [Card]
    var rites: [Rite]
    var sudan_card_pool: [Card]
    var counter: [String: Int]
    var event_status: [String: Bool]
    var timing_rounds: [String: TimingRound]
    var gen_cards: [String: Int]
    var gen_tags: [String: Int]
    var ithink_card: Card?
    var last_round_rite_data: [String: [String: RiteSlotData]]
    var end_rites: [String: Int]
    var auto_result_rites: [Int]
    var rite_auto_result: Bool
    var armageddon_rite_id: Int

    // MARK: - Codable 容错解码

    private enum CodingKeys: String, CodingKey {
        case configId, configVersion, name, difficulty, round, min_round
        case saveTime, card_uid_index, rite_uid_index, success, over_reason
        case cards, rites, sudan_card_pool, counter, event_status
        case timing_rounds, gen_cards, gen_tags, ithink_card
        case last_round_rite_data, end_rites, auto_result_rites
        case rite_auto_result, armageddon_rite_id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configId = try container.decode(Int.self, forKey: .configId)
        configVersion = (try? container.decode(Int.self, forKey: .configVersion)) ?? 0
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        difficulty = (try? container.decode(Int.self, forKey: .difficulty)) ?? 0
        round = (try? container.decode(Int.self, forKey: .round)) ?? 0
        min_round = (try? container.decode(Int.self, forKey: .min_round)) ?? 0
        saveTime = (try? container.decode(String.self, forKey: .saveTime)) ?? ""
        card_uid_index = (try? container.decode(Int.self, forKey: .card_uid_index)) ?? 0
        rite_uid_index = (try? container.decode(Int.self, forKey: .rite_uid_index)) ?? 0
        success = (try? container.decode(Bool.self, forKey: .success)) ?? false
        over_reason = (try? container.decode(Int.self, forKey: .over_reason)) ?? Int.min
        cards = (try? container.decode([Card].self, forKey: .cards)) ?? []
        rites = (try? container.decode([Rite].self, forKey: .rites)) ?? []
        sudan_card_pool = (try? container.decode([Card].self, forKey: .sudan_card_pool)) ?? []
        counter = (try? container.decode([String: Int].self, forKey: .counter)) ?? [:]
        event_status = (try? container.decode([String: Bool].self, forKey: .event_status)) ?? [:]
        timing_rounds = (try? container.decode([String: TimingRound].self, forKey: .timing_rounds)) ?? [:]
        gen_cards = (try? container.decode([String: Int].self, forKey: .gen_cards)) ?? [:]
        gen_tags = (try? container.decode([String: Int].self, forKey: .gen_tags)) ?? [:]
        ithink_card = try? container.decode(Card.self, forKey: .ithink_card)
        last_round_rite_data = (try? container.decode([String: [String: RiteSlotData]].self, forKey: .last_round_rite_data)) ?? [:]
        end_rites = (try? container.decode([String: Int].self, forKey: .end_rites)) ?? [:]
        auto_result_rites = (try? container.decode([Int].self, forKey: .auto_result_rites)) ?? []
        rite_auto_result = (try? container.decode(Bool.self, forKey: .rite_auto_result)) ?? false
        armageddon_rite_id = (try? container.decode(Int.self, forKey: .armageddon_rite_id)) ?? 0
    }
}
