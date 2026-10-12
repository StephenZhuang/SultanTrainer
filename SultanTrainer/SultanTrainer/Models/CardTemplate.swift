// Models/CardTemplate.swift
import Foundation

/// 卡牌模板，来自 config/cards.json
struct CardTemplate: Codable, Identifiable {
    var id: Int
    var name: String
    var text: String
    var type: String
    var title: String
    var tag: [String: Int]
    var equip_slots: [String]

    private enum CodingKeys: String, CodingKey {
        case id, name, text, type, title, tag, equip_slots = "equips"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
        type = (try? container.decode(String.self, forKey: .type)) ?? ""
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        tag = (try? container.decode([String: Int].self, forKey: .tag)) ?? [:]
        equip_slots = (try? container.decode([String].self, forKey: .equip_slots)) ?? []
    }

    init(id: Int, name: String = "", text: String = "", type: String = "", title: String = "", tag: [String: Int] = [:], equip_slots: [String] = []) {
        self.id = id
        self.name = name
        self.text = text
        self.type = type
        self.title = title
        self.tag = tag
        self.equip_slots = equip_slots
    }
}

/// 标签模板，来自 config/tag.json
struct TagTemplate: Codable {
    var id: String
    var name: String
    var tag_rank: Int
    var can_visible: Bool
    var can_inherit: Bool
    var type: String

    private enum CodingKeys: String, CodingKey {
        case id, name, tag_rank, can_visible, can_inherit, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? ""
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        tag_rank = (try? container.decode(Int.self, forKey: .tag_rank)) ?? 0
        can_visible = (try? container.decode(Bool.self, forKey: .can_visible)) ?? false
        can_inherit = (try? container.decode(Bool.self, forKey: .can_inherit)) ?? false
        type = (try? container.decode(String.self, forKey: .type)) ?? ""
    }
}

/// 升级模板，来自 config/upgrade.json
struct UpgradeTemplate: Codable, Identifiable {
    var id: Int
    var name: String
    var text: String
    var cost: Int

    private enum CodingKeys: String, CodingKey {
        case id, name, text, cost
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
        cost = (try? container.decode(Int.self, forKey: .cost)) ?? 0
    }
}

/// 任务模板，来自 config/quest.json
struct QuestTemplate: Codable, Identifiable {
    var id: Int
    var name: String
    var text: String

    private enum CodingKeys: String, CodingKey {
        case id, name, text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
    }
}

/// 结局模板，来自 config/over.json
struct OverTemplate: Codable {
    var name: String
    var text: String

    private enum CodingKeys: String, CodingKey {
        case name, text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
    }
}
