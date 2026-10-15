import Foundation

/// 卡牌类别
enum CardCategory: String, CaseIterable, Identifiable {
    case character = "人物"
    case equipment = "装备"
    case book = "书籍"
    case sudan = "苏丹卡"
    case other = "其他"
    
    var id: String { rawValue }
}

/// 卡牌品级
enum CardRarity: Int, CaseIterable, Identifiable {
    case rock = 1
    case bronze = 2
    case silver = 3
    case gold = 4

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .rock: return "岩石"
        case .bronze: return "青铜"
        case .silver: return "白银"
        case .gold: return "黄金"
        }
    }
}

/// 人物属性类型
enum AttributeType: String, CaseIterable, Identifiable {
    case physique = "physique"
    case charm = "charm"
    case wisdom = "wisdom"
    case conceal = "conceal"
    case battle = "battle"
    case social = "social"
    case survival = "survival"
    case magic = "magic"
    case knowledge = "knowledge"
    
    var id: String { rawValue }
    
    /// 中文显示名
    var displayName: String {
        switch self {
        case .physique: return "体魄"
        case .charm: return "魅力"
        case .wisdom: return "智慧"
        case .conceal: return "隐匿"
        case .battle: return "战斗"
        case .social: return "社交"
        case .survival: return "生存"
        case .magic: return "魔力"
        case .knowledge: return "学识"
        }
    }
    
    /// 将值限制在合法范围内 (0-999)
    func clamp(_ value: Int) -> Int {
        max(GameConstants.attributeMinValue, min(GameConstants.attributeMaxValue, value))
    }
}

/// 计数器作用域
enum CounterScope: String, CaseIterable, Identifiable {
    case session = "局内状态"
    case persistent = "跨局数据"
    case achievement = "成就"
    case crossSession = "跨局累计"
    case completion = "完成记录"
    case unlock = "解锁"
    
    var id: String { rawValue }
    
    /// 根据计数器ID前缀判断作用域
    init?(fromId id: String) {
        guard let prefix = Int(String(id.prefix(4))) else { return nil }
        switch prefix {
        case 7000: self = .session
        case 7100: self = .persistent
        case 7200: self = .achievement
        case 7210: self = .crossSession
        case 7220: self = .completion
        case 7230: self = .unlock
        default: return nil
        }
    }
}

/// 侧边栏导航项
enum SidebarItem: String, CaseIterable, Identifiable {
    case quickModify = "快捷修改"
    case cardManage = "卡牌管理"
    case characterAttribute = "人物属性"
    case gemInlay = "宝石镶嵌"
    case counter = "计数器"
    case rite = "仪式"
    case globalData = "全局数据"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .quickModify: return "bolt.fill"
        case .cardManage: return "rectangle.stack.fill"
        case .characterAttribute: return "person.fill"
        case .gemInlay: return "diamond.fill"
        case .counter: return "number"
        case .rite: return "star.fill"
        case .globalData: return "globe"
        }
    }
}
