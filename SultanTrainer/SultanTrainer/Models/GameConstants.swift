import Foundation

/// 游戏常量定义，避免硬编码魔法数字
enum GameConstants {
    // MARK: - 卡牌模板 ID
    
    /// 主角卡模板ID（阿尔图）
    static let protagonistCardTemplateId = 2000001
    
    /// 主角分身卡模板ID
    static let avatarCardTemplateId = 2000861
    
    /// 苏丹卡ID范围（杀戮/纵欲/奢靡/征服各4级，共16张）
    static let sudanCardIdRange = 2010001...2010016
    
    // MARK: - 属性值范围
    
    /// 人物属性最大值
    static let attributeMaxValue = 999
    
    /// 人物属性最小值
    static let attributeMinValue = 0
    
    // MARK: - 计数器值范围
    
    /// 计数器最大值
    static let counterMaxValue = 999999
    
    // MARK: - UI 延迟
    
    /// 消息清除延迟（秒）
    static let messageClearDelay: TimeInterval = 2
    
    /// 操作冷却时间（秒）
    static let actionCooldown: TimeInterval = 1
}
