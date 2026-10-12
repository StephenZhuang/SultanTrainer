import SwiftUI

struct CounterItem: Identifiable {
    let id: String
    let value: Int
}

struct CounterEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var editingCounterId: String?
    @State private var editingValue: Int = 0
    
    /// 金币卡牌的 templateId
    private let goldCardTemplateId = 2000029
    
    private var filteredCounters: [CounterItem] {
        guard let save = viewModel.saveData else { return [] }
        var counters: [CounterItem] = []
        
        // 金币：从 cards 数组中 id=2000029 的卡牌读取
        if let goldCard = save.cards.first(where: { $0.templateId == goldCardTemplateId }) {
            counters.append(CounterItem(id: "gold", value: goldCard.count))
        }
        
        // 金骰子：从 counter 字段读取
        if let diceCount = save.counter["7100006"] {
            counters.append(CounterItem(id: "7100006", value: diceCount))
        }
        
        if !searchText.isEmpty {
            counters = counters.filter {
                let name = viewModel.configLoader.getCounterName(id: $0.id)
                return $0.id.contains(searchText) || name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return counters.sorted { $0.id < $1.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Text("共 \(filteredCounters.count) 项")
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // 计数器表格
            Table(filteredCounters, selection: $editingCounterId) {
                TableColumn("名称") { counter in
                    Text(viewModel.configLoader.getCounterName(id: counter.id))
                }
                
                TableColumn("当前值") { counter in
                    Text("\(counter.value)")
                }
                .width(min: 60, ideal: 80)
                
                TableColumn("操作") { counter in
                    Button("编辑") {
                        editingCounterId = counter.id
                        editingValue = counter.value
                    }
                }
                .width(min: 50, ideal: 60)
            }
            
            // 编辑面板
            if let editId = editingCounterId {
                Divider()
                HStack {
                    Text(viewModel.configLoader.getCounterName(id: editId))
                    TextField("值", value: $editingValue, format: .number)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                    Stepper("", value: $editingValue, in: 0...999999)
                        .labelsHidden()
                    Button("应用") {
                        applyCounterValue(id: editId, value: editingValue)
                        editingCounterId = nil
                    }
                    .buttonStyle(.borderedProminent)
                    Button("取消") {
                        editingCounterId = nil
                    }
                }
                .padding()
            }
        }
    }
    
    private func applyCounterValue(id: String, value: Int) {
        guard var save = viewModel.saveData else { return }
        
        if id == "gold" {
            // 修改金币：找到 cards 数组中 id=2000029 的卡牌
            if let index = save.cards.firstIndex(where: { $0.templateId == goldCardTemplateId }) {
                save.cards[index].count = value
            }
        } else {
            // 修改其他计数器（金骰子）
            save.counter[id] = value
        }
        
        viewModel.saveData = save
        viewModel.markModified()
    }
}
