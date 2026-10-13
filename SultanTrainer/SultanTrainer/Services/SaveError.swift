import Foundation

/// 存档操作相关错误
enum SaveError: LocalizedError {
    case fileNotFound(URL)
    case parseFailed(URL, underlying: Error)
    case writeFailed(URL, underlying: Error)
    case backupFailed(URL, underlying: Error)
    case noSaveLoaded

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url): return "存档文件不存在: \(url.lastPathComponent)"
        case .parseFailed(let url, let err): return "存档解析失败 \(url.lastPathComponent): \(err.localizedDescription)"
        case .writeFailed(let url, let err): return "存档写入失败 \(url.lastPathComponent): \(err.localizedDescription)"
        case .backupFailed(let url, let err): return "备份失败 \(url.lastPathComponent): \(err.localizedDescription)"
        case .noSaveLoaded: return "未加载存档"
        }
    }
}
