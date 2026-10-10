import Foundation

/// 快捷修改器，封装常用的存档修改操作
class QuickModifiers {

    /// 金币+amount（修改counter中金币计数器）
    func addGold(to save: inout SaveData, amount: Int) {
        let goldKey = "7000100"
        let current = save.counter[goldKey] ?? 0
        save.counter[goldKey] = current + amount
    }

    /// 全属性满（修改主角卡的tag字段）
    func maxAllAttributes(in save: inout SaveData, characterUid: Int) {
        guard let index = save.cards.firstIndex(where: { $0.uid == characterUid }) else { return }
        for attr in AttributeType.allCases {
            save.cards[index].tag[attr.rawValue] = 999
        }
    }

    /// 直接胜利（苏丹卡全部life=0 + success=true）
    func instantVictory(in save: inout SaveData) {
        for i in save.sudan_card_pool.indices {
            save.sudan_card_pool[i].life = 0
        }
        save.success = true
    }

    /// 回合数+1
    func incrementRound(in save: inout SaveData) {
        save.round += 1
    }

    /// 清空苏丹卡池
    func clearSudanCards(in save: inout SaveData) {
        save.sudan_card_pool.removeAll()
    }

    /// 解锁所有结局
    func unlockAllEndings(in global: inout GlobalData, allEndingIds: [Int]) {
        let existingSet = Set(global.overID)
        let newIds = allEndingIds.filter { !existingSet.contains($0) }
        global.overID.append(contentsOf: newIds)
    }

    /// 升级点数+amount
    func addUpgradePoints(to global: inout GlobalData, amount: Int) {
        global.totalPoint += amount
    }

    /// 解锁所有升级
    func unlockAllUpgrades(in global: inout GlobalData, allUpgradeIds: [Int]) {
        for id in allUpgradeIds {
            global.upgrade["\(id)"] = 1
        }
    }

    /// 完成所有任务
    func completeAllQuests(in global: inout GlobalData, allQuestIds: [Int]) {
        for id in allQuestIds {
            global.quest["\(id)"] = 2
        }
    }
}
