import SwiftUI

struct RiteEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedRiteUid: Int?
    @State private var editingSlotIndex: Int?
    @State private var showCardPicker = false
    @State private var pendingSlotUid: Int?

    private var rites: [Rite] {
        viewModel.rites
    }

    var body: some View {
        HSplitView {
            // 左侧：仪式列表
            VStack(alignment: .leading) {
                Text("仪式列表")
                    .font(.headline)
                    .padding(.bottom, 4)

                List(rites, selection: $selectedRiteUid) { rite in
                    VStack(alignment: .leading) {
                        Text("仪式 \(rite.id)")
                            .font(.body)
                        Text("UID: \(rite.uid)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(rite.uid as Int?)
                }
            }
            .frame(minWidth: 200)

            // 右侧：槽位详情
            if let riteUid = selectedRiteUid,
               let rite = rites.first(where: { $0.uid == riteUid }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("仪式 \(rite.id) - 槽位")
                        .font(.headline)

                    ForEach(Array(rite.cards.enumerated()), id: \.offset) { index, card in
                        HStack {
                            Text("s\(index + 1)")
                                .frame(width: 30, alignment: .leading)
                                .font(.caption.monospaced())

                            if let card = card {
                                Text("UID: \(card.uid)")
                                Text("(\(viewModel.cardDisplayName(card: card, saveName: viewModel.saveData?.name)))")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("空")
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("替换") {
                                editingSlotIndex = index
                                pendingSlotUid = card?.uid
                                showCardPicker = true
                            }

                            if card != nil {
                                Button("清空") {
                                    if let riteIndex = rites.firstIndex(where: { $0.uid == riteUid }) {
                                        viewModel.clearRiteSlot(riteIndex: riteIndex, slotIndex: index)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Spacer()
                }
                .padding()
            } else {
                VStack {
                    Text("选择一个仪式查看槽位")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showCardPicker) {
            CardPickerView { templateId in
                if let slotIndex = editingSlotIndex,
                   let riteIndex = rites.firstIndex(where: { $0.uid == selectedRiteUid }) {
                    viewModel.assignCardToRiteSlot(riteIndex: riteIndex, slotIndex: slotIndex, templateId: templateId)
                }
            }
            .environmentObject(viewModel)
        }
    }
}
