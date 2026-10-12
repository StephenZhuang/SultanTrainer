import SwiftUI

struct CardListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedCardUid: Int?
    @State private var filterCategory: CardCategory? = nil
    @State private var searchText = ""
    @State private var showPicker = false
    @State private var pickerMode: PickerMode = .add
    @State private var showDeleteConfirm = false
    @State private var showReplaceConfirm = false
    @State private var pendingReplaceTemplateId: Int?
    
    enum PickerMode {
        case add, replace
    }
    
    private var filteredCards: [Card] {
        guard let save = viewModel.saveData else { return [] }
        var cards = save.cards.filter { $0.bagpos > 0 }

        // 同一 (bag, bagpos) 可能有多张堆叠卡，游戏 UI 只显示第一张
        var seen = Set<String>()
        cards = cards.filter { seen.insert("\($0.bag)_\($0.bagpos)").inserted }

        if let category = filterCategory {
            cards = cards.filter { viewModel.cardService.categorize(card: $0) == category }
        }

        if !searchText.isEmpty {
            cards = cards.filter {
                let name = viewModel.configLoader.getCardDisplayName(card: $0, saveName: save.name)
                return name.localizedCaseInsensitiveContains(searchText) || "\($0.templateId)".contains(searchText) || "\($0.uid)".contains(searchText)
            }
        }

        return cards.sorted {
            if $0.bag != $1.bag { return $0.bag < $1.bag }
            return $0.bagpos < $1.bagpos
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 操作栏
            HStack {
                Button("添加卡牌") {
                    pickerMode = .add
                    showPicker = true
                }
                Button("替换卡牌") {
                    guard selectedCardUid != nil else { return }
                    pickerMode = .replace
                    showPicker = true
                }
                .disabled(selectedCardUid == nil)
                
                Button("删除卡牌") {
                    guard selectedCardUid != nil else { return }
                    showDeleteConfirm = true
                }
                .disabled(selectedCardUid == nil)
                
                Spacer()
            }
            .padding()
            
            // 筛选栏
            HStack {
                Picker("类别", selection: $filterCategory) {
                    Text("全部").tag(nil as CardCategory?)
                    ForEach(CardCategory.allCases) { category in
                        Text(category.rawValue).tag(category as CardCategory?)
                    }
                }
                .frame(width: 120)
                
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Text("共 \(filteredCards.count) 张")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            // 卡牌表格
            Table(filteredCards, selection: $selectedCardUid) {
                TableColumn("位置") { card in
                    Text("\(card.bagpos)")
                }
                .width(min: 40, ideal: 50)

                TableColumn("UID") { card in
                    Text("\(card.uid)")
                }
                .width(min: 50, ideal: 60)
                
                TableColumn("名称") { card in
                    Text(viewModel.configLoader.getCardDisplayName(card: card, saveName: viewModel.saveData?.name))
                }
                
                TableColumn("类别") { card in
                    Text(viewModel.cardService.categorize(card: card).rawValue)
                }
                .width(min: 50, ideal: 60)
                
                TableColumn("数量") { card in
                    Text("\(card.count)")
                }
                .width(min: 40, ideal: 50)
                
                TableColumn("生命") { card in
                    Text("\(card.life)")
                }
                .width(min: 40, ideal: 50)
            }
        }
        .sheet(isPresented: $showPicker) {
            CardPickerView { templateId in
                switch pickerMode {
                case .add:
                    addCard(templateId: templateId)
                case .replace:
                    pendingReplaceTemplateId = templateId
                    showReplaceConfirm = true
                }
            }
            .environmentObject(viewModel)
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteSelectedCard()
            }
        } message: {
            if let uid = selectedCardUid,
               let card = viewModel.saveData?.cards.first(where: { $0.uid == uid }) {
                let name = viewModel.configLoader.getCardDisplayName(card: card, saveName: viewModel.saveData?.name)
                Text("确定要删除「\(name)」(UID: \(uid)) 吗？")
            }
        }
        .alert("确认替换", isPresented: $showReplaceConfirm) {
            Button("取消", role: .cancel) { pendingReplaceTemplateId = nil }
            Button("替换") {
                if let uid = selectedCardUid, let templateId = pendingReplaceTemplateId {
                    replaceCard(uid: uid, templateId: templateId)
                }
                pendingReplaceTemplateId = nil
            }
        } message: {
            Text("确定要替换选中的卡牌吗？")
        }
    }
    
    private func addCard(templateId: Int) {
        guard var save = viewModel.saveData else { return }
        viewModel.cardService.addCard(to: &save, templateId: templateId)
        viewModel.saveData = save
        viewModel.markModified()
    }
    
    private func deleteSelectedCard() {
        guard var save = viewModel.saveData, let uid = selectedCardUid else { return }
        if viewModel.cardService.deleteCard(from: &save, cardUid: uid) {
            viewModel.saveData = save
            viewModel.markModified()
            selectedCardUid = nil
        } else {
            viewModel.errorMessage = "该卡牌正在仪式中使用，无法删除"
        }
    }
    
    private func replaceCard(uid: Int, templateId: Int) {
        guard var save = viewModel.saveData else { return }
        viewModel.cardService.replaceCard(in: &save, cardUid: uid, newTemplateId: templateId)
        viewModel.saveData = save
        viewModel.markModified()
    }
}
