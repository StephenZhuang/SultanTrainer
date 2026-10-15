// Services/GemInlayService.swift
import Foundation

/// 宝石镶嵌服务
class GemInlayService {
    let configLoader: ConfigLoader
    
    init(configLoader: ConfigLoader) {
        self.configLoader = configLoader
    }
    
    private func isEquipment(_ card: Card) -> Bool {
        guard let template = configLoader.cardTemplates[card.templateId] else { return false }
        return template.tag["装备"] == 1
    }
    
    private func isGem(_ card: Card) -> Bool {
        guard let template = configLoader.cardTemplates[card.templateId] else { return false }
        return template.tag["宝石"] == 1
    }
    
    /// 获取背包中的装备列表（模板 tag 中有"装备"标签的卡牌）
    func getEquipmentList(from save: SaveData) -> [Card] {
        return save.cards.filter { card in
            card.bagpos > 0 && isEquipment(card)
        }
    }
    
    /// 获取背包中的宝石列表（模板 tag 中有"宝石"标签的卡牌）
    func getGemList(from save: SaveData) -> [Card] {
        return save.cards.filter { card in
            card.bagpos > 0 && isGem(card)
        }
    }
    
    /// 检查装备是否已镶嵌宝石
    func isInlaid(equipment: Card) -> Bool {
        return equipment.tag["bejewel"] == 1
    }
    
    /// 获取装备上已镶嵌的宝石
    func getInlaidGem(from equipment: Card) -> Card? {
        guard isInlaid(equipment: equipment) else { return nil }
        return equipment.equips.first { isGem($0) }
    }
    
    /// 镶嵌宝石到装备（如果已有宝石则替换）
    /// - Returns: 被替换下来的旧宝石（如果有）
    func inlayGem(to equipmentUid: Int, gemUid: Int, in save: inout SaveData) -> Card? {
        guard let equipmentIndex = save.cards.firstIndex(where: { $0.uid == equipmentUid }) else {
            return nil
        }
        guard let gemIndex = save.cards.firstIndex(where: { $0.uid == gemUid }) else {
            return nil
        }
        
        var oldGem: Card? = nil
        
        // 如果已镶嵌，先拆下旧宝石
        if isInlaid(equipment: save.cards[equipmentIndex]) {
            oldGem = getInlaidGem(from: save.cards[equipmentIndex])
            save.cards[equipmentIndex].equips.removeAll { isGem($0) }
        }
        
        // 获取宝石卡牌
        let gem = save.cards[gemIndex]
        
        // 将宝石镶嵌到装备上
        var inlaidGem = gem
        inlaidGem.bag = -1  // 标记为已镶嵌
        inlaidGem.bagpos = 0
        
        save.cards[equipmentIndex].equips.append(inlaidGem)
        save.cards[equipmentIndex].tag["bejewel"] = 1
        
        // 从背包中移除宝石
        save.cards.remove(at: gemIndex)
        
        return oldGem
    }
    
    /// 拆卸装备上的宝石
    /// - Returns: 拆下的宝石
    func removeGem(from equipmentUid: Int, in save: inout SaveData) -> Card? {
        guard let equipmentIndex = save.cards.firstIndex(where: { $0.uid == equipmentUid }) else {
            return nil
        }
        guard isInlaid(equipment: save.cards[equipmentIndex]) else {
            return nil
        }
        
        // 获取宝石
        guard let gem = getInlaidGem(from: save.cards[equipmentIndex]) else {
            return nil
        }
        
        // 从装备上移除宝石
        save.cards[equipmentIndex].equips.removeAll { isGem($0) }
        save.cards[equipmentIndex].tag.removeValue(forKey: "bejewel")
        
        // 将宝石放回背包
        var returnedGem = gem
        returnedGem.bag = 0
        let maxBagpos = save.cards.filter { $0.bag == 0 }.map { $0.bagpos }.max() ?? 0
        returnedGem.bagpos = maxBagpos + 1
        
        save.cards.append(returnedGem)
        
        return returnedGem
    }
    
    /// 获取卡牌显示名称
    func getCardDisplayName(card: Card) -> String {
        if let template = configLoader.cardTemplates[card.templateId] {
            return template.name
        }
        return "未知卡牌(\(card.templateId))"
    }
    
    /// 获取宝石属性描述
    func getGemAttributeDescription(gem: Card) -> String {
        let attributeNames: [String: String] = [
            "physique": "体魄",
            "charm": "魅力",
            "wisdom": "智慧",
            "conceal": "隐匿",
            "battle": "战斗",
            "social": "社交",
            "survival": "生存",
            "magic": "魔力",
            "knowledge": "学识"
        ]
        
        var attributes: [String] = []
        for (key, value) in gem.tag {
            if let name = attributeNames[key], value > 0 {
                attributes.append("\(name)+\(value)")
            }
        }
        
        return attributes.isEmpty ? "无属性加成" : attributes.joined(separator: " ")
    }
}
