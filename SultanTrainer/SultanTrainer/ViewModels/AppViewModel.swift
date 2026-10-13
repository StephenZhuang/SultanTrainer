// ViewModels/AppViewModel.swift
import Foundation
import Combine

/// 全局视图模型，持有存档数据和修改状态
class AppViewModel: ObservableObject {
    // MARK: - 服务
    let configLoader = ConfigLoader()
    private let saveManager = SaveManager()
    let cardService: CardService
    private let quickModifiers = QuickModifiers()
    
    // MARK: - 存档数据
    @Published var saveData: SaveData?
    @Published var globalData: GlobalData?
    
    // MARK: - 状态
    @Published var isLoading = true
    @Published var hasUnsavedChanges = false
    @Published var lastSaveMessage: String?
    @Published var errorMessage: String?
    @Published var showSavePicker = false
    @Published var availableSaves: [SaveManager.SaveInfo] = []
    
    // MARK: - 导航
    @Published var selectedSidebarItem: SidebarItem? = .quickModify
    
    init() {
        self.cardService = CardService(configLoader: configLoader)
    }
    
    /// 启动时自动加载
    func initialize() {
        isLoading = true
        
        // 加载游戏配置
        _ = configLoader.locateConfigDirectory()
        configLoader.loadAllConfigs()
        
        // 扫描存档
        let saves = saveManager.scanSaveDirectories()
        availableSaves = saves
        
        if saves.isEmpty {
            isLoading = false
            errorMessage = "未检测到存档，请先运行游戏"
            return
        }
        
        if saves.count == 1 {
            loadSave(at: saves[0])
        } else {
            // 多个存档，让用户选择
            isLoading = false
            showSavePicker = true
        }
    }
    
    /// 加载指定存档
    func loadSave(at saveInfo: SaveManager.SaveInfo) {
        isLoading = true
        errorMessage = nil
        
        do {
            saveData = try saveManager.loadSave(from: saveInfo.autoSavePath)
            saveManager.currentSavePath = saveInfo.autoSavePath
            
            if FileManager.default.fileExists(atPath: saveInfo.globalPath.path) {
                globalData = try saveManager.loadGlobal(from: saveInfo.globalPath)
                saveManager.currentGlobalPath = saveInfo.globalPath
            }
            
            hasUnsavedChanges = false
        } catch {
            errorMessage = "存档加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 保存存档
    func save() {
        guard saveData != nil else {
            errorMessage = "未加载存档，无法保存"
            return
        }
        guard saveManager.currentSavePath != nil else {
            errorMessage = "未找到存档路径"
            return
        }
        let save = saveData!
        let path = saveManager.currentSavePath!
        
        do {
            try saveManager.saveSave(save, to: path)
            hasUnsavedChanges = false
            lastSaveMessage = "已保存"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.messageClearDelay) {
                if self.lastSaveMessage == "已保存" {
                    self.lastSaveMessage = nil
                }
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
    
    /// 保存全局数据
    func saveGlobal() {
        guard globalData != nil else {
            errorMessage = "未加载全局数据，无法保存"
            return
        }
        guard saveManager.currentGlobalPath != nil else {
            errorMessage = "未找到全局数据路径"
            return
        }
        let global = globalData!
        let path = saveManager.currentGlobalPath!
        
        do {
            try saveManager.saveGlobal(global, to: path)
            lastSaveMessage = "已保存"
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
    
    /// 刷新存档（重新从磁盘读取）
    func reloadSave() {
        guard let savePath = saveManager.currentSavePath else { return }

        isLoading = true
        errorMessage = nil

        do {
            saveData = try saveManager.loadSave(from: savePath)

            if let globalPath = saveManager.currentGlobalPath,
               FileManager.default.fileExists(atPath: globalPath.path) {
                globalData = try saveManager.loadGlobal(from: globalPath)
            }

            hasUnsavedChanges = false
            lastSaveMessage = "已刷新"

            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.messageClearDelay) {
                if self.lastSaveMessage == "已刷新" {
                    self.lastSaveMessage = nil
                }
            }
        } catch {
            errorMessage = "刷新失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 标记数据已修改
    func markModified() {
        hasUnsavedChanges = true
    }

    // MARK: - 配置读取代理

    func counterName(id: String) -> String {
        configLoader.getCounterName(id: id)
    }

    func cardDisplayName(card: Card, saveName: String? = nil) -> String {
        configLoader.getCardDisplayName(card: card, saveName: saveName)
    }

    func categorizeCard(_ card: Card) -> CardCategory {
        cardService.categorize(card: card)
    }

    func categorizeTemplate(_ template: CardTemplate) -> CardCategory {
        configLoader.categorize(template: template)
    }

    func sudanCardLevel(templateId: Int) -> String? {
        configLoader.getSudanCardLevel(templateId: templateId)
    }

    func overTemplateName(id: Int) -> String {
        configLoader.overTemplates[id]?.name ?? "结局\(id)"
    }

    func upgradeTemplateName(_ id: String) -> String {
        configLoader.upgradeTemplates[Int(id) ?? 0]?.name ?? id
    }

    func questTemplateName(_ id: String) -> String {
        configLoader.questTemplates[Int(id) ?? 0]?.name ?? id
    }

    var cardTemplatesList: [CardTemplate] {
        Array(configLoader.cardTemplates.values)
    }

    var overEndingIds: [Int] {
        Array(configLoader.overTemplates.keys)
    }

    var upgradeIds: [Int] {
        Array(configLoader.upgradeTemplates.keys)
    }

    var questIds: [Int] {
        Array(configLoader.questTemplates.keys)
    }

    var characters: [Card] {
        guard let save = saveData else { return [] }
        return save.cards.filter { card in
            card.bagpos > 0 && cardService.categorize(card: card) == .character
        }
    }

    var rites: [Rite] {
        saveData?.rites ?? []
    }

    // MARK: - 计数器代理

    func setCounter(id: String, value: Int) {
        guard var save = saveData else { return }
        if id == "gold" {
            setGoldCardCount(value: value)
            return
        }
        save.counter[id] = value
        saveData = save
        markModified()
    }

    func setGoldCardCount(value: Int) {
        guard var save = saveData else { return }
        let goldCardTemplateId = 2000029
        if let index = save.cards.firstIndex(where: { $0.templateId == goldCardTemplateId }) {
            save.cards[index].count = value
        }
        saveData = save
        markModified()
    }

    // MARK: - 卡牌代理

    func addCard(templateId: Int) {
        guard var save = saveData else { return }
        cardService.addCard(to: &save, templateId: templateId)
        saveData = save
        markModified()
    }

    @discardableResult
    func deleteCard(uid: Int) -> Bool {
        guard var save = saveData else { return false }
        let result = cardService.deleteCard(from: &save, cardUid: uid)
        if result {
            saveData = save
            markModified()
        }
        return result
    }

    func replaceCard(uid: Int, newTemplateId: Int) -> Int? {
        guard var save = saveData else { return nil }
        let result = cardService.replaceCard(in: &save, cardUid: uid, newTemplateId: newTemplateId)
        saveData = save
        markModified()
        return result
    }

    // MARK: - 人物属性代理

    func updateCharacterAttribute(characterUid: Int, attr: AttributeType, value: Int) {
        guard var save = saveData else { return }
        cardService.updateCharacterAttribute(in: &save, characterUid: characterUid, attribute: attr, value: value)
        saveData = save
        markModified()
    }

    func setEquipSlot(characterUid: Int, slot: String, enabled: Bool) {
        guard var save = saveData else { return }
        cardService.setEquipSlot(in: &save, characterUid: characterUid, slot: slot, enabled: enabled)
        saveData = save
        markModified()
    }

    // MARK: - 仪式代理

    func assignCardToRiteSlot(riteIndex: Int, slotIndex: Int, templateId: Int) {
        guard var save = saveData else { return }
        guard riteIndex < save.rites.count, slotIndex < save.rites[riteIndex].cards.count else { return }

        if let existingCard = save.cards.first(where: { $0.templateId == templateId }) {
            save.rites[riteIndex].cards[slotIndex] = existingCard
        } else {
            let newUid = cardService.addCard(to: &save, templateId: templateId)
            if let newCard = save.cards.first(where: { $0.uid == newUid }) {
                save.rites[riteIndex].cards[slotIndex] = newCard
            }
        }

        saveData = save
        markModified()
    }

    func clearRiteSlot(riteIndex: Int, slotIndex: Int) {
        guard var save = saveData else { return }
        guard riteIndex < save.rites.count, slotIndex < save.rites[riteIndex].cards.count else { return }
        save.rites[riteIndex].cards[slotIndex] = nil
        saveData = save
        markModified()
    }

    // MARK: - 全局数据代理

    func updateTotalPoint(_ value: Int) {
        guard let global = globalData else { return }
        var updated = global
        updated.totalPoint = value
        globalData = updated
        markModified()
    }

    // MARK: - 快捷修改代理

    func quickAddGold() {
        guard var save = saveData else { return }
        quickModifiers.addGold(to: &save, amount: 999)
        saveData = save
        markModified()
    }

    func quickMaxAttributes() {
        guard var save = saveData else { return }
        guard let character = save.cards.first(where: { cardService.categorize(card: $0) == .character }) else { return }
        quickModifiers.maxAllAttributes(in: &save, characterUid: character.uid)
        saveData = save
        markModified()
    }

    func quickInstantVictory() {
        guard var save = saveData else { return }
        quickModifiers.instantVictory(in: &save)
        saveData = save
        markModified()
    }

    func quickIncrementRound() {
        guard var save = saveData else { return }
        quickModifiers.incrementRound(in: &save)
        saveData = save
        markModified()
    }

    func quickClearSudanCards() {
        guard var save = saveData else { return }
        quickModifiers.clearSudanCards(in: &save)
        saveData = save
        markModified()
    }

    func quickAddUpgradePoints() {
        guard var global = globalData else { return }
        quickModifiers.addUpgradePoints(to: &global, amount: 100)
        globalData = global
        markModified()
    }

    func quickUnlockAllEndings() {
        guard var global = globalData else { return }
        let allIds = overEndingIds
        quickModifiers.unlockAllEndings(in: &global, allEndingIds: allIds.isEmpty ? [0, 1, 2, 3, 4, 5] : allIds)
        globalData = global
        markModified()
    }

    func quickUnlockAllUpgrades() {
        guard var global = globalData else { return }
        let allIds = upgradeIds
        quickModifiers.unlockAllUpgrades(in: &global, allUpgradeIds: allIds)
        globalData = global
        markModified()
    }

    func quickCompleteAllQuests() {
        guard var global = globalData else { return }
        let allIds = questIds
        quickModifiers.completeAllQuests(in: &global, allQuestIds: allIds)
        globalData = global
        markModified()
    }
}
