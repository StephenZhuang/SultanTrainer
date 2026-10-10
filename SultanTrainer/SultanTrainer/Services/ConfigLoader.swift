// Services/ConfigLoader.swift
import Foundation

/// 游戏配置加载器，负责定位config目录并加载模板数据
class ConfigLoader {
    var configDirectory: URL?
    var cardTemplates: [Int: CardTemplate] = [:]
    var tagTemplates: [String: TagTemplate] = [:]
    var upgradeTemplates: [Int: UpgradeTemplate] = [:]
    var questTemplates: [Int: QuestTemplate] = [:]
    var overTemplates: [Int: OverTemplate] = [:]
    
    /// 自动定位游戏config目录
    func locateConfigDirectory() -> URL? {
        // 1. 已知路径
        let knownPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Steam/steamapps/common/Sultan's Game/Sultan's Game.app/Contents/Resources/Data/StreamingAssets/config")
        if FileManager.default.fileExists(atPath: knownPath.path) {
            configDirectory = knownPath
            return knownPath
        }
        
        // 2. Spotlight扫描
        if let spotlightPath = spotlightSearch() {
            configDirectory = spotlightPath
            return spotlightPath
        }
        
        return nil
    }
    
    /// 加载所有配置文件
    func loadAllConfigs() throws {
        guard let configDir = configDirectory else {
            return // 降级模式：不加载配置，UI只显示ID
        }
        
        try loadCardsConfig(from: configDir)
        try loadTagConfig(from: configDir)
        try loadUpgradeConfig(from: configDir)
        try loadQuestConfig(from: configDir)
        try loadOverConfig(from: configDir)
    }
    
    /// 获取卡牌名称，找不到时返回ID字符串
    func getCardName(id: Int) -> String {
        return cardTemplates[id]?.name ?? "\(id)"
    }
    
    /// 获取计数器名称
    func getCounterName(id: String) -> String {
        return tagTemplates[id]?.name ?? id
    }
    
    /// 卡牌分类
    func categorize(template: CardTemplate) -> CardCategory {
        if template.id >= 2010001 && template.id <= 2010016 {
            return .sudan
        }
        if template.id >= 2000001 && template.id <= 2000010 {
            return .character
        }
        let equipmentSlots = ["weapon", "cloth", "accessory", "animal_handling"]
        if template.equip_slots.contains(where: { equipmentSlots.contains($0) }) {
            return .equipment
        }
        if template.tag.keys.contains("book") {
            return .book
        }
        return .other
    }
    
    // MARK: - Private
    
    private func spotlightSearch() -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemFSName == 'cards.json'"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            
            for line in output.components(separatedBy: "\n") where !line.isEmpty {
                let url = URL(fileURLWithPath: line)
                let configDir = url.deletingLastPathComponent()
                let cardsPath = configDir.appendingPathComponent("cards.json")
                if FileManager.default.fileExists(atPath: cardsPath.path) {
                    return configDir
                }
            }
        } catch {
            // Spotlight搜索失败，降级处理
        }
        return nil
    }
    
    private func loadCardsConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("cards.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: CardTemplate].self, from: data) {
            for (_, template) in dict {
                cardTemplates[template.id] = template
            }
        } else if let array = try? JSONDecoder().decode([CardTemplate].self, from: data) {
            for template in array {
                cardTemplates[template.id] = template
            }
        }
    }
    
    private func loadTagConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("tag.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: TagTemplate].self, from: data) {
            for (_, template) in dict {
                tagTemplates[template.id] = template
            }
        } else if let array = try? JSONDecoder().decode([TagTemplate].self, from: data) {
            for template in array {
                tagTemplates[template.id] = template
            }
        }
    }
    
    private func loadUpgradeConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("upgrade.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: UpgradeTemplate].self, from: data) {
            for (_, template) in dict {
                upgradeTemplates[template.id] = template
            }
        } else if let array = try? JSONDecoder().decode([UpgradeTemplate].self, from: data) {
            for template in array {
                upgradeTemplates[template.id] = template
            }
        }
    }
    
    private func loadQuestConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("quest.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: QuestTemplate].self, from: data) {
            for (_, template) in dict {
                questTemplates[template.id] = template
            }
        } else if let array = try? JSONDecoder().decode([QuestTemplate].self, from: data) {
            for template in array {
                questTemplates[template.id] = template
            }
        }
    }
    
    private func loadOverConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("over.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: OverTemplate].self, from: data) {
            for (key, template) in dict {
                if let id = Int(key) {
                    overTemplates[id] = template
                }
            }
        }
    }
}
