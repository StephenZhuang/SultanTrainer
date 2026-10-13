// Services/CardService.swift
import Foundation

/// 卡牌操作服务
class CardService {
    static let zhEquipToEn: [String: String] = [
        "武器": "weapon", "服装": "cloth", "饰品": "accessory", "驯兽": "animal_handling"
    ]

    let configLoader: ConfigLoader
    
    init(configLoader: ConfigLoader) {
        self.configLoader = configLoader
    }
    
    /// 添加卡牌到存档（自动分配到背包下一个空位），返回新卡 UID
    @discardableResult
    func addCard(to save: inout SaveData, templateId: Int, count: Int = 1) -> Int {
        var card = Card(uid: save.card_uid_index, templateId: templateId, count: count)

        if let template = configLoader.cardTemplates[templateId] {
            card.tag = configLoader.convertTagKeys(template.tag)
            card.equip_slots = template.equip_slots.map { Self.zhEquipToEn[$0] ?? $0 }
            if template.type == "item" {
                card.tag["own"] = 1
            }
            if template.type == "char" {
                card.tag["adherent"] = 1
            }
        }

        let maxBagpos = save.cards.filter { $0.bag == 0 }.map { $0.bagpos }.max() ?? 0
        card.bagpos = maxBagpos + 1

        let newUid = card.uid
        save.cards.append(card)
        save.card_uid_index += 1
        return newUid
    }
    
    /// 替换卡牌（删除旧的，添加新的），保留原卡背包位置，更新仪式引用，返回新卡 UID
    func replaceCard(in save: inout SaveData, cardUid: Int, newTemplateId: Int) -> Int? {
        guard let index = save.cards.firstIndex(where: { $0.bag == 0 && $0.bagpos > 0 && $0.uid == cardUid })
                ?? save.cards.firstIndex(where: { $0.uid == cardUid }) else { return nil }
        let oldBag = save.cards[index].bag
        let oldBagpos = save.cards[index].bagpos
        
        save.cards.remove(at: index)
        let newUid = addCard(to: &save, templateId: newTemplateId)
        
        // 保留原卡的背包位置
        if let newIndex = save.cards.firstIndex(where: { $0.uid == newUid }) {
            save.cards[newIndex].bag = oldBag
            save.cards[newIndex].bagpos = oldBagpos
        }
        
        // 更新仪式中对原卡的引用
        var newCard: Card?
        if let newIndex = save.cards.firstIndex(where: { $0.uid == newUid }) {
            newCard = save.cards[newIndex]
        }
        if let newCard = newCard {
            for riteIndex in save.rites.indices {
                for slotIndex in save.rites[riteIndex].cards.indices {
                    if let card = save.rites[riteIndex].cards[slotIndex], card.uid == cardUid {
                        save.rites[riteIndex].cards[slotIndex] = newCard
                    }
                }
            }
        }
        
        return newUid
    }
    
    /// 删除卡牌，如果被仪式引用则返回false
    func deleteCard(from save: inout SaveData, cardUid: Int) -> Bool {
        if isCardInRite(save: save, cardUid: cardUid) {
            return false
        }
        save.cards.removeAll { $0.uid == cardUid }
        return true
    }
    
    /// 检查卡牌是否被仪式引用
    func isCardInRite(save: SaveData, cardUid: Int) -> Bool {
        for rite in save.rites {
            for card in rite.cards {
                if let card = card, card.uid == cardUid {
                    return true
                }
            }
        }
        return false
    }
    
    /// 修改人物属性
    func updateCharacterAttribute(in save: inout SaveData, characterUid: Int, attribute: AttributeType, value: Int) {
        guard let index = save.cards.firstIndex(where: { $0.uid == characterUid }) else { return }
        let clampedValue = attribute.clamp(value)
        if clampedValue == 0 {
            save.cards[index].tag.removeValue(forKey: attribute.rawValue)
        } else {
            save.cards[index].tag[attribute.rawValue] = clampedValue
        }
    }
    
    /// 设置人物卡的装备槽位（添加或移除）
    func setEquipSlot(in save: inout SaveData, characterUid: Int, slot: String, enabled: Bool) {
        guard let index = save.cards.firstIndex(where: { $0.uid == characterUid }) else { return }
        if enabled {
            if !save.cards[index].equip_slots.contains(slot) {
                save.cards[index].equip_slots.append(slot)
            }
        } else {
            save.cards[index].equip_slots.removeAll { $0 == slot }
        }
    }

    /// 获取卡牌的分类
    func categorize(card: Card) -> CardCategory {
        if let template = configLoader.cardTemplates[card.templateId] {
            return configLoader.categorize(template: template)
        }
        if GameConstants.sudanCardIdRange.contains(card.templateId) { return .sudan }
        let equipmentSlots = ["weapon", "cloth", "accessory", "animal_handling"]
        if card.equip_slots.contains(where: { equipmentSlots.contains($0) }) { return .equipment }
        return .other
    }
}
