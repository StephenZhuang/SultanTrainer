import SwiftUI

struct CounterItem: Identifiable {
    let id: String
    let value: Int
}

struct CounterEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var filterScope: CounterScope? = nil
    @State private var searchText = ""
    @State private var editingCounterId: String?
    @State private var editingValue: Int = 0
    
    private var filteredCounters: [CounterItem] {
        guard let save = viewModel.saveData else { return [] }
        var counters = save.counter.map { CounterItem(id: $0.key, value: $0.value) }
        
        if let scope = filterScope {
            counters = counters.filter { counter in
                CounterScope(fromId: counter.id) == scope
            }
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
            // 筛选栏
            HStack {
                Picker("作用域", selection: $filterScope) {
                    Text("全部").tag(nil as CounterScope?)
                    ForEach(CounterScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope as CounterScope?)
                    }
                }
                .frame(width: 120)
                
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Text("共 \(filteredCounters.count) 项")
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // 计数器表格
            Table(filteredCounters, selection: $editingCounterId) {
                TableColumn("ID") { counter in
                    Text(counter.id)
                }
                
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
                    Text("计数器 \(editId)")
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
        save.counter[id] = value
        viewModel.saveData = save
        viewModel.markModified()
    }
}
