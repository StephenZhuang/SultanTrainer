// Services/CardService.swift
import Foundation

/// 卡牌操作服务
class CardService {
    let configLoader: ConfigLoader
    
    init(configLoader: ConfigLoader) {
        self.configLoader = configLoader
    }
    
    /// 添加卡牌到存档
    func addCard(to save: inout SaveData, templateId: Int, count: Int = 1) {
        var card = Card(uid: save.card_uid_index, templateId: templateId, count: count)
        
        if let template = configLoader.cardTemplates[templateId] {
            card.tag = template.tag
            card.equip_slots = template.equip_slots
        }
        
        save.cards.append(card)
        save.card_uid_index += 1
    }
    
    /// 替换卡牌（删除旧的，添加新的）
    func replaceCard(in save: inout SaveData, cardUid: Int, newTemplateId: Int) {
        guard let index = save.cards.firstIndex(where: { $0.uid == cardUid }) else { return }
        save.cards.remove(at: index)
        addCard(to: &save, templateId: newTemplateId)
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
        let clampedValue = max(0, min(999, value))
        save.cards[index].tag[attribute.rawValue] = clampedValue
    }
    
    /// 获取卡牌的分类
    func categorize(card: Card) -> CardCategory {
        if let template = configLoader.cardTemplates[card.templateId] {
            return configLoader.categorize(template: template)
        }
        if card.templateId >= 2010001 && card.templateId <= 2010016 { return .sudan }
        if card.templateId >= 2000001 && card.templateId <= 2000010 { return .character }
        return .other
    }
}
