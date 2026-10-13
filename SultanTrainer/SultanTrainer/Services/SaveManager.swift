import Foundation
import os

/// 存档管理器，负责扫描、加载、备份和保存存档
class SaveManager {
    private static let logger = Logger(subsystem: "com.sultantrainer", category: "SaveManager")

    static let saveRootDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/com.DoubleCross.SultansGame/SAVEDATA")

    var currentSavePath: URL?
    var currentGlobalPath: URL?

    let backupDir: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/SultanTrainer/backups")

    let maxBackups = 10

    struct SaveInfo {
        let steamId: String
        let autoSavePath: URL
        let globalPath: URL
        let modifiedDate: Date
    }

    /// 扫描存档根目录，返回找到的存档列表
    func scanSaveDirectories() -> [SaveInfo] {
        var results: [SaveInfo] = []
        let fm = FileManager.default

        guard fm.fileExists(atPath: Self.saveRootDir.path) else { return results }

        guard let steamDirs = try? fm.contentsOfDirectory(
            at: Self.saveRootDir,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return results }

        for dir in steamDirs {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { continue }

            let autoSavePath = dir.appendingPathComponent("auto_save.json")
            let globalPath = dir.appendingPathComponent("global.json")

            guard fm.fileExists(atPath: autoSavePath.path) else { continue }

            let attrs = try? fm.attributesOfItem(atPath: autoSavePath.path)
            let modifiedDate = attrs?[.modificationDate] as? Date ?? Date.distantPast

            results.append(SaveInfo(
                steamId: dir.lastPathComponent,
                autoSavePath: autoSavePath,
                globalPath: globalPath,
                modifiedDate: modifiedDate
            ))
        }

        return results.sorted { $0.modifiedDate > $1.modifiedDate }
    }

    /// 从指定路径加载存档
    func loadSave(from path: URL) throws -> SaveData {
        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            return try decoder.decode(SaveData.self, from: data)
        } catch let error as SaveError {
            throw error
        } catch {
            throw SaveError.parseFailed(path, underlying: error)
        }
    }

    /// 从指定路径加载全局数据
    func loadGlobal(from path: URL) throws -> GlobalData {
        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            return try decoder.decode(GlobalData.self, from: data)
        } catch let error as SaveError {
            throw error
        } catch {
            throw SaveError.parseFailed(path, underlying: error)
        }
    }

    /// 保存存档（自动备份 + 保留未建模字段 + 原子写入）
    func saveSave(_ save: SaveData, to path: URL) throws {
        let originalData: Data?
        if FileManager.default.fileExists(atPath: path.path) {
            do {
                originalData = try Data(contentsOf: path)
            } catch {
                Self.logger.error("读取原始存档数据失败: \(path.path, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
                throw SaveError.writeFailed(path, underlying: error)
            }
        } else {
            originalData = nil
        }
        do {
            try backupFile(at: path, to: backupDir)
        } catch {
            Self.logger.error("备份存档失败: \(path.path, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            throw SaveError.backupFailed(path, underlying: error)
        }
        try mergeWrite(save, originalData: originalData, to: path)
        currentSavePath = path
    }

    /// 保存全局数据（自动备份 + 保留未建模字段 + 原子写入）
    func saveGlobal(_ global: GlobalData, to path: URL) throws {
        let originalData: Data?
        if FileManager.default.fileExists(atPath: path.path) {
            do {
                originalData = try Data(contentsOf: path)
            } catch {
                Self.logger.error("读取原始全局数据失败: \(path.path, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
                throw SaveError.writeFailed(path, underlying: error)
            }
        } else {
            originalData = nil
        }
        do {
            try backupFile(at: path, to: backupDir)
        } catch {
            Self.logger.error("备份全局数据失败: \(path.path, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            throw SaveError.backupFailed(path, underlying: error)
        }
        try mergeWrite(global, originalData: originalData, to: path)
        currentGlobalPath = path
    }

    /// 备份文件
    func backupFile(at sourcePath: URL, to backupDir: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: backupDir.path) {
            try fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss_SSS"
        let timestamp = formatter.string(from: Date())
        let backupName = "\(sourcePath.deletingPathExtension().lastPathComponent)_\(timestamp).json"
        let backupPath = backupDir.appendingPathComponent(backupName)

        do {
            try fm.copyItem(at: sourcePath, to: backupPath)
        } catch {
            // Fallback: if destination already exists, remove and retry
            if fm.fileExists(atPath: backupPath.path) {
                try fm.removeItem(at: backupPath)
                try fm.copyItem(at: sourcePath, to: backupPath)
            } else {
                throw SaveError.backupFailed(sourcePath, underlying: error)
            }
        }

        try cleanupOldBackups(in: backupDir)
    }

    /// 原子写入：先写临时文件再rename
    func atomicWrite<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(value)

        let tempUrl = url.appendingPathExtension("tmp")
        try data.write(to: tempUrl, options: .atomic)

        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            _ = try fm.replaceItemAt(url, withItemAt: tempUrl, backupItemName: "save_crash_backup")
        } else {
            try fm.moveItem(at: tempUrl, to: url)
        }
    }

    /// 合并写入：编码新值，与原始 JSON 深度合并（保留未建模字段和卡牌 tag 中的未知键），原子写入
    private func mergeWrite<T: Encodable>(_ value: T, originalData: Data?, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let encodedData = try encoder.encode(value)

        var mergedData = encodedData
        if let originalData = originalData,
           let original = try? JSONSerialization.jsonObject(with: originalData) as? [String: Any],
           let encoded = try? JSONSerialization.jsonObject(with: encodedData) as? [String: Any] {
            let merged = deepMerge(original: original, updated: encoded)
            mergedData = try JSONSerialization.data(withJSONObject: merged, options: [.prettyPrinted, .withoutEscapingSlashes])
        }

        let tempUrl = url.appendingPathExtension("tmp")
        try mergedData.write(to: tempUrl, options: .atomic)

        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            _ = try fm.replaceItemAt(url, withItemAt: tempUrl, backupItemName: "save_crash_backup")
        } else {
            try fm.moveItem(at: tempUrl, to: url)
        }
    }

    /// 深度合并两个 JSON 对象，特别处理卡牌数组中的 tag 字典和仪式数组
    private func deepMerge(original: [String: Any], updated: [String: Any]) -> [String: Any] {
        var result = original

        for (key, newValue) in updated {
            // 特殊处理卡牌数组：cards, sudan_card_pool
            if (key == "cards" || key == "sudan_card_pool"),
               let originalArray = original[key] as? [[String: Any]],
               let updatedArray = newValue as? [[String: Any]] {
                result[key] = mergeCardArrays(original: originalArray, updated: updatedArray)
            } else if key == "rites",
                      let originalArray = original[key] as? [[String: Any]],
                      let updatedArray = newValue as? [[String: Any]] {
                // 特殊处理仪式数组：按 uid 匹配并深度合并
                result[key] = mergeRiteArrays(original: originalArray, updated: updatedArray)
            } else if let originalDict = original[key] as? [String: Any],
                      let updatedDict = newValue as? [String: Any] {
                // 递归合并嵌套字典
                result[key] = deepMerge(original: originalDict, updated: updatedDict)
            } else {
                // 直接覆盖
                result[key] = newValue
            }
        }

        return result
    }

    /// 合并卡牌数组，按 uid 匹配并深度合并每个卡牌的 tag 字典
    private func mergeCardArrays(original: [[String: Any]], updated: [[String: Any]]) -> [[String: Any]] {
        // 构建原始卡牌的 uid -> 原始数据映射
        var originalByUid: [Int: [String: Any]] = [:]
        for card in original {
            if let uid = card["uid"] as? Int {
                originalByUid[uid] = card
            }
        }

        var result: [[String: Any]] = []
        for updatedCard in updated {
            guard let uid = updatedCard["uid"] as? Int else {
                // 没有 uid 的卡牌直接添加
                result.append(updatedCard)
                continue
            }

            if let originalCard = originalByUid[uid] {
                // 找到匹配的原始卡牌，深度合并
                result.append(mergeCard(original: originalCard, updated: updatedCard))
            } else {
                // 新增卡牌，直接使用更新后的数据
                result.append(updatedCard)
            }
        }

        return result
    }

    /// 合并单个卡牌数据，特别处理 tag 字典
    private func mergeCard(original: [String: Any], updated: [String: Any]) -> [String: Any] {
        var result = original

        for (key, newValue) in updated {
            if key == "tag",
               let originalTag = original["tag"] as? [String: Int],
               let updatedTag = newValue as? [String: Int] {
                // 深度合并 tag 字典：保留原始的所有键，用新值覆盖已知键
                var mergedTag = originalTag
                for (tagKey, tagValue) in updatedTag {
                    mergedTag[tagKey] = tagValue
                }
                result["tag"] = mergedTag
            } else if let originalDict = original[key] as? [String: Any],
                      let updatedDict = newValue as? [String: Any] {
                // 递归合并其他嵌套字典（如 equip_slots 如果是字典）
                result[key] = deepMerge(original: originalDict, updated: updatedDict)
            } else {
                // 直接覆盖（包括 equips 数组等）
                result[key] = newValue
            }
        }

        return result
    }

    /// 合并仪式数组，按 uid 匹配并深度合并每个仪式
    private func mergeRiteArrays(original: [[String: Any]], updated: [[String: Any]]) -> [[String: Any]] {
        var originalByUid: [Int: [String: Any]] = [:]
        for rite in original {
            if let uid = rite["uid"] as? Int {
                originalByUid[uid] = rite
            }
        }

        var result: [[String: Any]] = []
        for updatedRite in updated {
            guard let uid = updatedRite["uid"] as? Int else {
                result.append(updatedRite)
                continue
            }

            if let originalRite = originalByUid[uid] {
                result.append(mergeRite(original: originalRite, updated: updatedRite))
            } else {
                result.append(updatedRite)
            }
        }

        return result
    }

    /// 合并单个仪式数据，深度合并 cards 数组中的每个卡牌
    private func mergeRite(original: [String: Any], updated: [String: Any]) -> [String: Any] {
        var result = original

        for (key, newValue) in updated {
            if key == "cards",
               let originalCards = original["cards"] as? [[String: Any]?],
               let updatedCards = newValue as? [[String: Any]?] {
                result["cards"] = mergeRiteCards(original: originalCards, updated: updatedCards)
            } else if let originalDict = original[key] as? [String: Any],
                      let updatedDict = newValue as? [String: Any] {
                result[key] = deepMerge(original: originalDict, updated: updatedDict)
            } else {
                result[key] = newValue
            }
        }

        return result
    }

    /// 合并仪式中的卡牌数组，按索引位置逐个合并（保留 null 槽位）
    private func mergeRiteCards(original: [[String: Any]?], updated: [[String: Any]?]) -> [[String: Any]?] {
        var result: [[String: Any]?] = []
        let count = max(original.count, updated.count)

        for i in 0..<count {
            let originalCard = i < original.count ? original[i] : nil
            let updatedCard = i < updated.count ? updated[i] : nil

            if let orig = originalCard, let upd = updatedCard {
                result.append(mergeCard(original: orig, updated: upd))
            } else if let upd = updatedCard {
                result.append(upd)
            } else if let orig = originalCard {
                result.append(orig)
            } else {
                result.append(nil)
            }
        }

        return result
    }

    // MARK: - Private

    private func cleanupOldBackups(in dir: URL) throws {
        let fm = FileManager.default
        let backups = try fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.creationDateKey]
        ).filter { $0.pathExtension == "json" }
        .sorted {
            let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return date1 > date2
        }

        if backups.count > maxBackups {
            for oldBackup in backups[maxBackups...] {
                try fm.removeItem(at: oldBackup)
            }
        }
    }
}
