import SwiftUI

struct CardPickerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: CardCategory? = nil
    @State private var searchText = ""
    @State private var selectedTemplateId: Int?
    
    var onSelect: ((Int) -> Void)?
    
    private var filteredTemplates: [CardTemplate] {
        var templates = Array(viewModel.configLoader.cardTemplates.values)
        
        if let category = selectedCategory {
            templates = templates.filter { viewModel.configLoader.categorize(template: $0) == category }
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
                
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            
            Divider()
            
            // 卡牌列表
            List(filteredTemplates, selection: $selectedTemplateId) { template in
                HStack {
                    Text(template.name.isEmpty ? "\(template.id)" : template.name)
                        .font(.body)
                    Spacer()
                    Text("\(template.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.configLoader.categorize(template: template).rawValue)
                        .font(.caption)
                        .foregroundStyle(.blue)
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
    }
}
