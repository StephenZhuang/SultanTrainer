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

    /// 获取卡牌显示名称：custom_name > 存档角色名（主角卡/分身卡）> 模板名（苏丹卡追加等级）
    func getCardDisplayName(card: Card, saveName: String? = nil) -> String {
        if !card.custom_name.isEmpty {
            return card.custom_name
        }
        if let saveName = saveName, !saveName.isEmpty {
            if card.templateId == 2000001 {
                return saveName
            }
            if card.templateId == 2000861 {
                return saveName + "的分身"
            }
        }
        let baseName = getCardName(id: card.templateId)
        if let level = getSudanCardLevel(templateId: card.templateId) {
            return "\(baseName) (\(level))"
        }
        return baseName
    }

    /// 获取苏丹卡等级名称（岩石/青铜/白银/黄金），非苏丹卡返回 nil
    func getSudanCardLevel(templateId: Int) -> String? {
        guard let template = cardTemplates[templateId], template.type == "sudan" else { return nil }
        guard let rarity = CardRarity(rawValue: template.rare) else { return nil }
        return rarity.displayName
    }

    /// 计数器名称映射（硬编码，游戏配置中无此数据）
    private let counterNames: [String: String] = [
        "gold": "金币",
        "7100006": "金骰子"
    ]

    /// 获取可修改的计数器 ID 列表（有实际修改意义的计数器）
    func getEditableCounterIds() -> Set<String> {
        return Set(counterNames.keys)
    }

    /// 获取计数器名称
    func getCounterName(id: String) -> String {
        return counterNames[id] ?? id
    }

    /// 卡牌分类
    func categorize(template: CardTemplate) -> CardCategory {
        if template.type == "sudan" { return .sudan }
        if template.type == "char" { return .character }
        if template.tag.keys.contains("装备") { return .equipment }
        let equipmentNames = ["武器", "服装", "饰品", "驯兽"]
        if template.equip_slots.contains(where: { equipmentNames.contains($0) }) {
            return .equipment
        }
        if template.tag.keys.contains("读物") { return .book }
        return .other
    }

    /// 可修改属性的中文名→英文code映射（can_add=1 且 can_visible=1 的 tag）
    var zhTagToEn: [String: String] {
        var result: [String: String] = [:]
        for (_, template) in tagTemplates {
            if template.can_add && template.can_visible {
                result[template.name] = template.code
            }
        }
        return result
    }

    /// 转换卡牌 tag 的 key：可修改属性用英文 id，其他保持中文
    func convertTagKeys(_ tag: [String: Int]) -> [String: Int] {
        let mapping = zhTagToEn
        var result: [String: Int] = [:]
        for (key, value) in tag {
            if let enKey = mapping[key] {
                result[enKey] = value
            } else {
                result[key] = value
            }
        }
        return result
    }
    
    // MARK: - Private
    
    /// 剥除 JSON 中的 JavaScript 风格注释（// 和 /* */）及尾随逗号，返回标准 JSON 数据
    /// 注意：不会剥除字符串字面量内的 // 或 /* */
    private func stripJSONComments(from data: Data) throws -> Data {
        var result = Data()
        result.reserveCapacity(data.count)
        
        var i = 0
        let bytes = [UInt8](data)
        let count = bytes.count
        
        while i < count {
            let b = bytes[i]
            
            // 字符串字面量：原样保留
            if b == UInt8(ascii: "\"") {
                result.append(b)
                i += 1
                while i < count {
                    let sb = bytes[i]
                    result.append(sb)
                    if sb == UInt8(ascii: "\\") {
                        // 转义字符：追加下一个字节
                        i += 1
                        if i < count {
                            result.append(bytes[i])
                            i += 1
                        }
                    } else if sb == UInt8(ascii: "\"") {
                        i += 1
                        break
                    } else {
                        i += 1
                    }
                }
                continue
            }
            
            // 单行注释 //
            if b == UInt8(ascii: "/") && i + 1 < count {
                let next = bytes[i + 1]
                if next == UInt8(ascii: "/") {
                    // 跳过到行尾（包括 \n）
                    while i < count && bytes[i] != UInt8(ascii: "\n") {
                        i += 1
                    }
                    continue
                } else if next == UInt8(ascii: "*") {
                    // 块注释 /* ... */
                    i += 2
                    while i < count {
                        if bytes[i] == UInt8(ascii: "*") && i + 1 < count && bytes[i + 1] == UInt8(ascii: "/") {
                            i += 2
                            break
                        }
                        i += 1
                    }
                    continue
                }
            }
            
            result.append(b)
            i += 1
        }
        
        // 剥除尾随逗号：,] 和 ,}（包括中间有空白/换行的情况）
        if let text = String(data: result, encoding: .utf8),
           let regex = try? NSRegularExpression(pattern: ",(\\s*[\\]\\}])", options: []) {
            let nsResult = NSMutableString(string: text)
            regex.replaceMatches(in: nsResult, range: NSRange(text.startIndex..., in: text), withTemplate: "$1")
            if let finalText = nsResult as String?, let finalData = finalText.data(using: .utf8) {
                return finalData
            }
        }
        
        return result
    }
    
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
        let rawData = try Data(contentsOf: url)
        let data = try stripJSONComments(from: rawData)
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
        let rawData = try Data(contentsOf: url)
        let data = try stripJSONComments(from: rawData)
        if let dict = try? JSONDecoder().decode([String: TagTemplate].self, from: data) {
            for (_, template) in dict {
                tagTemplates[template.code] = template
            }
        } else if let array = try? JSONDecoder().decode([TagTemplate].self, from: data) {
            for template in array {
                tagTemplates[template.code] = template
            }
        }
    }
    
    private func loadUpgradeConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("upgrade.json")
        let rawData = try Data(contentsOf: url)
        let data = try stripJSONComments(from: rawData)
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
        let rawData = try Data(contentsOf: url)
        let data = try stripJSONComments(from: rawData)
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
        let rawData = try Data(contentsOf: url)
        let data = try stripJSONComments(from: rawData)
        if let dict = try? JSONDecoder().decode([String: OverTemplate].self, from: data) {
            for (key, template) in dict {
                if let id = Int(key) {
                    overTemplates[id] = template
                }
            }
        }
    }
}
