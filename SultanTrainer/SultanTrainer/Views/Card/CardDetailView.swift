import SwiftUI

/// 卡牌详情弹窗视图
struct CardDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    /// 实例模式：传入卡牌实例
    let card: Card?
    /// 模板模式：传入模板ID
    let templateId: Int?
    /// 存档角色名（用于主角卡显示）
    let saveName: String?

    private var template: CardTemplate? {
        if let card = card {
            return viewModel.configLoader.cardTemplates[card.templateId]
        } else if let id = templateId {
            return viewModel.configLoader.cardTemplates[id]
        }
        return nil
    }

    private var isInstanceMode: Bool { card != nil }

    private var displayName: String {
        if let card = card {
            return viewModel.configLoader.getCardDisplayName(card: card, saveName: saveName)
        } else if let template = template {
            if let level = viewModel.configLoader.getSudanCardLevel(templateId: template.id) {
                return "\(template.name) (\(level))"
            }
            return template.name.isEmpty ? "\(template.id)" : template.name
        }
        return ""
    }

    private var category: CardCategory {
        if let template = template {
            return viewModel.configLoader.categorize(template: template)
        }
        return .other
    }

    private var rarityStars: String {
        guard let rare = template?.rare, rare > 0 else { return "" }
        return String(repeating: "★", count: rare)
    }

    /// 合并显示的属性标签：实例优先，否则用模板
    private var displayTag: [String: Int] {
        if let card = card {
            return card.tag
        }
        return template?.tag ?? [:]
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("卡牌详情")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 基本信息
                    basicInfoSection

                    if let template = template, !template.text.isEmpty {
                        Divider()
                        descriptionSection(template: template)
                    }

                    if !displayTag.isEmpty {
                        Divider()
                        tagSection
                    }

                    if let template = template, !template.equip_slots.isEmpty || !(card?.equips.isEmpty ?? true) {
                        Divider()
                        equipmentSection(template: template)
                    }

                    if isInstanceMode, let card = card {
                        Divider()
                        instanceInfoSection(card: card)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }

    // MARK: - 基本信息

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                if !rarityStars.isEmpty {
                    Text(rarityStars)
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 12) {
                Text(category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(4)

                if let title = template?.title, !title.isEmpty {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                Text("模板ID: \(template?.id ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let card = card {
                    Text("UID: \(card.uid)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 描述

    private func descriptionSection(template: CardTemplate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("描述")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(template.text)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 属性标签

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("属性")
                .font(.subheadline)
                .fontWeight(.medium)

            let sortedTag = displayTag.sorted { $0.key < $1.key }
            FlowLayout(spacing: 12) {
                ForEach(sortedTag, id: \.key) { key, value in
                    let displayName = viewModel.configLoader.getTagDisplayName(code: key)
                    HStack(spacing: 4) {
                        Text("\(displayName):")
                            .foregroundStyle(.secondary)
                        Text("\(value)")
                            .fontWeight(.medium)
                    }
                    .font(.callout)
                }
            }
        }
    }

    // MARK: - 装备信息

    private func equipmentSection(template: CardTemplate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !template.equip_slots.isEmpty {
                Text("装备槽: \(template.equip_slots.joined(separator: "、"))")
                    .font(.subheadline)
            }

            if let equips = card?.equips, !equips.isEmpty {
                Text("已装备")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ForEach(equips) { equip in
                    let equipName = viewModel.configLoader.getCardDisplayName(card: equip, saveName: saveName)
                    let equipTemplate = viewModel.configLoader.cardTemplates[equip.templateId]
                    let equipCategory = equipTemplate.map { viewModel.configLoader.categorize(template: $0) }

                    HStack {
                        Circle()
                            .fill(.secondary)
                            .frame(width: 4, height: 4)
                        Text(equipName)
                        if let cat = equipCategory {
                            Text("(\(cat.rawValue))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.callout)
                }
            }
        }
    }

    // MARK: - 实例信息

    private func instanceInfoSection(card: Card) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("实例信息")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 20) {
                Label("数量: \(card.count)", systemImage: "number")
                if card.life > 0 {
                    Label("生命: \(card.life)", systemImage: "heart.fill")
                }
                Label("位置: \(card.bagpos)", systemImage: "location.fill")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            if !card.custom_name.isEmpty || !card.custom_text.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if !card.custom_name.isEmpty {
                        Text("自定义名称: \(card.custom_name)")
                    }
                    if !card.custom_text.isEmpty {
                        Text("自定义文本: \(card.custom_text)")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
    }
}
