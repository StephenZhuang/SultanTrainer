import Foundation

/// 存档管理器，负责扫描、加载、备份和保存存档
class SaveManager {
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
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        return try decoder.decode(SaveData.self, from: data)
    }

    /// 从指定路径加载全局数据
    func loadGlobal(from path: URL) throws -> GlobalData {
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        return try decoder.decode(GlobalData.self, from: data)
    }

    /// 保存存档（自动备份 + 保留未建模字段 + 原子写入）
    func saveSave(_ save: SaveData, to path: URL) throws {
        let originalData = try? Data(contentsOf: path)
        try backupFile(at: path, to: backupDir)
        try mergeWrite(save, originalData: originalData, to: path)
        currentSavePath = path
    }

    /// 保存全局数据（自动备份 + 保留未建模字段 + 原子写入）
    func saveGlobal(_ global: GlobalData, to path: URL) throws {
        let originalData = try? Data(contentsOf: path)
        try backupFile(at: path, to: backupDir)
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
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let backupName = "\(sourcePath.deletingPathExtension().lastPathComponent)_\(timestamp).json"
        let backupPath = backupDir.appendingPathComponent(backupName)

        try fm.copyItem(at: sourcePath, to: backupPath)

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
            try fm.removeItem(at: url)
        }
        try fm.moveItem(at: tempUrl, to: url)
    }

    /// 合并写入：编码新值，与原始 JSON 合并（保留未建模字段），原子写入
    private func mergeWrite<T: Encodable>(_ value: T, originalData: Data?, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let encodedData = try encoder.encode(value)

        var mergedData = encodedData
        if let originalData = originalData,
           let original = try? JSONSerialization.jsonObject(with: originalData) as? [String: Any],
           let encoded = try? JSONSerialization.jsonObject(with: encodedData) as? [String: Any] {
            var merged = original
            for (key, val) in encoded {
                merged[key] = val
            }
            mergedData = try JSONSerialization.data(withJSONObject: merged, options: [.prettyPrinted, .withoutEscapingSlashes])
        }

        let tempUrl = url.appendingPathExtension("tmp")
        try mergedData.write(to: tempUrl, options: .atomic)

        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
        try fm.moveItem(at: tempUrl, to: url)
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
