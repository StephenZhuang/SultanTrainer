// Services/ConfigLoader.swift
import Foundation
import os

/// 游戏配置加载器，负责定位config目录并加载模板数据
class ConfigLoader {
    private static let logger = Logger(subsystem: "com.sultantrainer", category: "ConfigLoader")

    var configDirectory: URL?
    var cardTemplates: [Int: CardTemplate] = [:]
    var tagTemplates: [String: TagTemplate] = [:]
    var upgradeTemplates: [Int: UpgradeTemplate] = [:]
    var questTemplates: [Int: QuestTemplate] = [:]
    var overTemplates: [Int: OverTemplate] = [:]
    var riteTemplates: [Int: RiteTemplate] = [:]
    
    /// 仪式改名映射：存档 custom_name key → 实际显示名
    /// 例如 "change_card_name_5000301_03" → "镜中的生灵"
    var cardNameChanges: [String: String] = [:]
    
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
    
    /// 加载所有配置文件（单个配置失败时记录日志并继续，不中断其他配置加载）
    func loadAllConfigs() {
        guard let configDir = configDirectory else {
            Self.logger.warning("配置目录未设置，跳过配置加载（降级模式）")
            return // 降级模式：不加载配置，UI只显示ID
        }

        do { try loadCardsConfig(from: configDir) }
        catch { Self.logger.error("加载卡牌配置失败: \(error.localizedDescription, privacy: .public)") }

        do { try loadTagConfig(from: configDir) }
        catch { Self.logger.error("加载标签配置失败: \(error.localizedDescription, privacy: .public)") }

        do { try loadUpgradeConfig(from: configDir) }
        catch { Self.logger.error("加载升级配置失败: \(error.localizedDescription, privacy: .public)") }

        do { try loadQuestConfig(from: configDir) }
        catch { Self.logger.error("加载任务配置失败: \(error.localizedDescription, privacy: .public)") }

        do { try loadOverConfig(from: configDir) }
        catch { Self.logger.error("加载结局配置失败: \(error.localizedDescription, privacy: .public)") }

        do { try loadRiteConfig(from: configDir) }
        catch { Self.logger.error("加载仪式配置失败: \(error.localizedDescription, privacy: .public)") }
    }
    
    /// 获取卡牌名称，找不到时返回ID字符串
    func getCardName(id: Int) -> String {
        return cardTemplates[id]?.name ?? "\(id)"
    }

    /// 获取仪式名称，找不到时返回ID字符串
    func getRiteName(id: Int) -> String {
        return riteTemplates[id]?.name ?? "\(id)"
    }

    /// 获取仪式描述文本
    func getRiteText(id: Int) -> String {
        return riteTemplates[id]?.text ?? ""
    }

    /// 获取仪式等待回合数（倒计时）
    func getRiteWaitingRound(id: Int) -> Int {
        return riteTemplates[id]?.waitingRound ?? 0
    }

    /// 获取卡牌显示名称：玩家改名 > 仪式改名 > 存档角色名（主角卡/分身卡）> 模板名（苏丹卡追加等级）
    func getCardDisplayName(card: Card, saveName: String? = nil, playerCardName: [String: String]? = nil) -> String {
        if let playerCardName = playerCardName, let name = playerCardName["\(card.templateId)"] {
            return name
        }
        if !card.custom_name.isEmpty {
            if let resolved = cardNameChanges[card.custom_name] {
                return resolved
            }
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

    /// 英文code→中文名映射（用于详情弹窗显示属性标签）
    var enTagToZh: [String: String] {
        var result: [String: String] = [:]
        for (_, template) in tagTemplates {
            result[template.code] = template.name
        }
        return result
    }

    /// 获取标签的中文显示名（英文code转中文，找不到则返回原值）
    func getTagDisplayName(code: String) -> String {
        return enTagToZh[code] ?? code
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
            Self.logger.warning("Spotlight搜索配置文件失败: \(error.localizedDescription, privacy: .public)")
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
        } else {
            Self.logger.error("卡牌配置解码失败: 无法解析为字典或数组格式")
            throw ConfigError.loadFailed("cards.json", underlying: NSError(domain: "ConfigLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "解码失败"]))
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
        } else {
            Self.logger.error("标签配置解码失败: 无法解析为字典或数组格式")
            throw ConfigError.loadFailed("tag.json", underlying: NSError(domain: "ConfigLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "解码失败"]))
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
        } else {
            Self.logger.error("升级配置解码失败: 无法解析为字典或数组格式")
            throw ConfigError.loadFailed("upgrade.json", underlying: NSError(domain: "ConfigLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "解码失败"]))
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
        } else {
            Self.logger.error("任务配置解码失败: 无法解析为字典或数组格式")
            throw ConfigError.loadFailed("quest.json", underlying: NSError(domain: "ConfigLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "解码失败"]))
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
        } else {
            Self.logger.error("结局配置解码失败: 无法解析为字典格式")
            throw ConfigError.loadFailed("over.json", underlying: NSError(domain: "ConfigLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "解码失败"]))
        }
    }

    private func loadRiteConfig(from configDir: URL) throws {
        let riteDir = configDir.appendingPathComponent("rite")
        guard FileManager.default.fileExists(atPath: riteDir.path) else {
            Self.logger.warning("仪式配置目录不存在: \(riteDir.path, privacy: .public)")
            return
        }
        let files = try FileManager.default.contentsOfDirectory(at: riteDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        for file in files {
            do {
                let rawData = try Data(contentsOf: file)
                let data = try stripJSONComments(from: rawData)
                if let template = try? JSONDecoder().decode(RiteTemplate.self, from: data) {
                    riteTemplates[template.id] = template
                }
                extractCardNameChanges(from: data)
            } catch {
                Self.logger.warning("加载仪式配置失败 \(file.lastPathComponent): \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// 从仪式配置原始 JSON 中提取 change_card_name 映射
    /// 存档 custom_name 格式: "change_card_name_5000301_03"（下划线、无slot后缀）
    /// 配置 key 格式: "change_card_name.5000301_03.s1"（点号、有slot后缀）
    private func extractCardNameChanges(from data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return }
        var stack: [Any] = [json]
        while let current = stack.popLast() {
            if let dict = current as? [String: Any] {
                for (key, value) in dict {
                    if let name = value as? String, key.hasPrefix("change_card_name.") || key.hasPrefix("total.change_card_name.") {
                        // 将配置 key 转换为存档 custom_name 格式：
                        // "change_card_name.5000301_03.s1" → "change_card_name_5000301_03"
                        // "total.change_card_name.5008205_01.2000195" → "change_card_name_5008205_01"
                        let normalized = key.replacingOccurrences(of: ".", with: "_")
                            .replacingOccurrences(of: "total_change_card_name_", with: "change_card_name_")
                        // 去掉末尾的 slot 后缀（如 _s1, _s2）或额外的 ID 段（如 _2000195）
                        let saveKey: String
                        if let range = normalized.range(of: "_s", options: .backwards),
                           range.upperBound < normalized.endIndex,
                           normalized[range.upperBound...].allSatisfy({ $0.isNumber }) {
                            saveKey = String(normalized[..<range.lowerBound])
                        } else if let lastUnderscore = normalized.lastIndex(of: "_"),
                                  lastUnderscore > normalized.index(normalized.startIndex, offsetBy: "change_card_name".count) {
                            saveKey = String(normalized[..<lastUnderscore])
                        } else {
                            saveKey = normalized
                        }
                        cardNameChanges[saveKey] = name
                    } else {
                        stack.append(value)
                    }
                }
            } else if let array = current as? [Any] {
                stack.append(contentsOf: array)
            }
        }
    }
}
