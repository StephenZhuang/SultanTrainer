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
    var rare: Int
    var is_only: Bool
    var resource: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, text, type, title, tag, equip_slots = "equips", rare, is_only, resource
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
        rare = (try? container.decode(Int.self, forKey: .rare)) ?? 0
        // is_only: 兼容 int→bool
        if let b = try? container.decode(Bool.self, forKey: .is_only) {
            is_only = b
        } else if let i = try? container.decode(Int.self, forKey: .is_only) {
            is_only = i != 0
        } else {
            is_only = false
        }
        resource = try? container.decode(String.self, forKey: .resource)
    }

    init(id: Int, name: String = "", text: String = "", type: String = "", title: String = "", tag: [String: Int] = [:], equip_slots: [String] = [], rare: Int = 0, is_only: Bool = false, resource: String? = nil) {
        self.id = id
        self.name = name
        self.text = text
        self.type = type
        self.title = title
        self.tag = tag
        self.equip_slots = equip_slots
        self.rare = rare
        self.is_only = is_only
        self.resource = resource
    }
}

/// 标签模板，来自 config/tag.json
struct TagTemplate: Codable {
    var id: Int
    var name: String
    var code: String
    var tag_rank: Int
    var can_visible: Bool
    var can_inherit: Bool
    var can_add: Bool
    var type: String
    var can_nagiative_and_zero: Bool
    var text: String?
    var tips: String?
    var fail_tag: String?
    var tag_vanishing: Int?
    var attributes: [String: Int]?

    private enum CodingKeys: String, CodingKey {
        case id, name, code, tag_rank, can_visible, can_inherit, can_add, type
        case can_nagiative_and_zero, text, tips, fail_tag, tag_vanishing, attributes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(Int.self, forKey: .id)) ?? 0
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        code = (try? container.decode(String.self, forKey: .code)) ?? ""
        tag_rank = (try? container.decode(Int.self, forKey: .tag_rank)) ?? 0
        can_visible = Self.decodeBool(container, forKey: .can_visible)
        can_inherit = Self.decodeBool(container, forKey: .can_inherit)
        can_add = Self.decodeBool(container, forKey: .can_add)
        type = (try? container.decode(String.self, forKey: .type)) ?? ""
        can_nagiative_and_zero = Self.decodeBool(container, forKey: .can_nagiative_and_zero)
        text = try? container.decode(String.self, forKey: .text)
        tips = try? container.decode(String.self, forKey: .tips)
        fail_tag = try? container.decode(String.self, forKey: .fail_tag)
        tag_vanishing = try? container.decode(Int.self, forKey: .tag_vanishing)
        attributes = try? container.decode([String: Int].self, forKey: .attributes)
    }

    private static func decodeBool(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Bool {
        if let b = try? container.decode(Bool.self, forKey: key) { return b }
        if let i = try? container.decode(Int.self, forKey: key) { return i != 0 }
        return false
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
