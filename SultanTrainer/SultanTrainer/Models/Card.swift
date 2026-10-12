import Foundation

/// 卡牌实例，对应存档中 cards/sudan_card_pool/equips 数组的元素
struct Card: Codable, Identifiable, Hashable {
    var uid: Int
    var templateId: Int
    var count: Int
    var life: Int
    var rareup: Int
    var tag: [String: Int]
    var equip_slots: [String]
    var equips: [Card]
    var bag: Int
    var bagpos: Int
    var custom_name: String
    var custom_text: String
    
    /// Identifiable 一致性：使用 uid 作为唯一标识
    var id: Int { uid }
    
    /// 便捷初始化，用于创建新卡牌实例
    init(uid: Int, templateId: Int, count: Int = 1, life: Int = 0, rareup: Int = 0,
         tag: [String: Int] = [:], equip_slots: [String] = [], equips: [Card] = [],
         bag: Int = 0, bagpos: Int = 0, custom_name: String = "", custom_text: String = "") {
        self.uid = uid
        self.templateId = templateId
        self.count = count
        self.life = life
        self.rareup = rareup
        self.tag = tag
        self.equip_slots = equip_slots
        self.equips = equips
        self.bag = bag
        self.bagpos = bagpos
        self.custom_name = custom_name
        self.custom_text = custom_text
    }
    
    // MARK: - Codable 容错解码
    
    private enum CodingKeys: String, CodingKey {
        case uid, templateId = "id", count, life, rareup, tag, equip_slots, equips, bag, bagpos, custom_name, custom_text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        templateId = try container.decode(Int.self, forKey: .templateId)
        count = (try? container.decode(Int.self, forKey: .count)) ?? 1
        life = (try? container.decode(Int.self, forKey: .life)) ?? 0
        rareup = (try? container.decode(Int.self, forKey: .rareup)) ?? 0
        tag = (try? container.decode([String: Int].self, forKey: .tag)) ?? [:]
        equip_slots = (try? container.decode([String].self, forKey: .equip_slots)) ?? []
        equips = (try? container.decode([Card].self, forKey: .equips)) ?? []
        bag = (try? container.decode(Int.self, forKey: .bag)) ?? 0
        bagpos = (try? container.decode(Int.self, forKey: .bagpos)) ?? 0
        custom_name = (try? container.decode(String.self, forKey: .custom_name)) ?? ""
        custom_text = (try? container.decode(String.self, forKey: .custom_text)) ?? ""
    }
}
