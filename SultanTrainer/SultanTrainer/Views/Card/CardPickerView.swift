import SwiftUI

struct CardPickerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: CardCategory? = nil
    @State private var selectedRarity: CardRarity? = nil
    @State private var searchText = ""
    @State private var selectedTemplateId: Int?
    @State private var detailTemplateId: Int? = nil

    var onSelect: ((Int) -> Void)?

    private var filteredTemplates: [CardTemplate] {
        var templates = viewModel.cardTemplatesList

        // 苏丹卡只保留 2010001-2010016，排除 2000xxx 的重复卡
        templates = templates.filter {
            guard $0.type == "sudan" else { return true }
            return GameConstants.sudanCardIdRange.contains($0.id)
        }

        if let category = selectedCategory {
            templates = templates.filter { viewModel.categorizeTemplate($0) == category }
        }

        if let rarity = selectedRarity {
            templates = templates.filter { $0.rare == rarity.rawValue }
        }

        if !searchText.isEmpty {
            templates = templates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) || "\($0.id)".contains(searchText)
            }
        }

        return templates.sorted { $0.id < $1.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            HStack {
                Picker("类别", selection: $selectedCategory) {
                    Text("全部").tag(nil as CardCategory?)
                    ForEach(CardCategory.allCases) { category in
                        Text(category.rawValue).tag(category as CardCategory?)
                    }
                }
                .frame(width: 120)

                Picker("品级", selection: $selectedRarity) {
                    Text("全部").tag(nil as CardRarity?)
                    ForEach(CardRarity.allCases) { rarity in
                        Text(rarity.displayName).tag(rarity as CardRarity?)
                    }
                }
                .frame(width: 120)

                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()

            Divider()

            // 卡牌列表
            List(filteredTemplates, selection: $selectedTemplateId) { template in
                HStack {
                    Text(getTemplateName(template: template))
                        .font(.body)
                    Spacer()
                    Text("\(template.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.categorizeTemplate(template).rawValue)
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Button {
                        detailTemplateId = template.id
                    } label: {
                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                }
                .tag(template.id as Int?)
            }

            Divider()

            // 底部按钮
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("选择") {
                    if let id = selectedTemplateId {
                        onSelect?(id)
                        dismiss()
                    }
                }
                .disabled(selectedTemplateId == nil)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .sheet(item: Binding(
            get: { detailTemplateId.map { IdentifiableInt(value: $0) } },
            set: { detailTemplateId = $0?.value }
        )) { item in
            CardDetailView(card: nil, templateId: item.value, saveName: nil)
                .environmentObject(viewModel)
        }
    }

    private struct IdentifiableInt: Identifiable {
        let value: Int
        var id: Int { value }
    }

    private func getTemplateName(template: CardTemplate) -> String {
        let baseName = template.name.isEmpty ? "\(template.id)" : template.name
        if let level = viewModel.sudanCardLevel(templateId: template.id) {
            return "\(baseName) (\(level))"
        }
        return baseName
    }
}
