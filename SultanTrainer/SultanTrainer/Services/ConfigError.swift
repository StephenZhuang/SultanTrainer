import Foundation

/// 配置加载相关错误
enum ConfigError: LocalizedError {
    case configDirectoryNotFound
    case loadFailed(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .configDirectoryNotFound: return "游戏配置目录未找到"
        case .loadFailed(let name, let err): return "配置 \(name) 加载失败: \(err.localizedDescription)"
        }
    }
}
