import SwiftUI

struct RiteEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedRiteUid: Int?
    @State private var editingSlot: String?
    @State private var showCardPicker = false
    @State private var pendingSlotUid: Int?

    private var rites: [Rite] {
        viewModel.saveData?.rites ?? []
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

                    ForEach(sortedSlots(rite: rite), id: \.key) { slotKey, cardRef in
                        HStack {
                            Text(slotKey)
                                .frame(width: 30, alignment: .leading)
                                .font(.caption.monospaced())

                            if let ref = cardRef {
                                if let card = viewModel.saveData?.cards.first(where: { $0.uid == ref.uid }) {
                                    Text("UID: \(ref.uid)")
                                    Text("(\(viewModel.configLoader.getCardName(id: card.id)))")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("UID: \(ref.uid) (卡牌不存在)")
                                        .foregroundStyle(.red)
                                }
                            } else {
                                Text("空")
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("替换") {
                                editingSlot = slotKey
                                pendingSlotUid = cardRef?.uid
                                showCardPicker = true
                            }

                            if cardRef != nil {
                                Button("清空") {
                                    clearSlot(riteUid: riteUid, slot: slotKey)
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
                if let slot = editingSlot, let riteUid = selectedRiteUid {
                    assignCardToSlot(riteUid: riteUid, slot: slot, templateId: templateId)
                }
            }
            .environmentObject(viewModel)
        }
    }

    private func sortedSlots(rite: Rite) -> [(key: String, value: Rite.CardReference?)] {
        return rite.cards.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    private func clearSlot(riteUid: Int, slot: String) {
        guard var save = viewModel.saveData,
              let riteIndex = save.rites.firstIndex(where: { $0.uid == riteUid }) else { return }
        save.rites[riteIndex].cards[slot] = nil
        viewModel.saveData = save
        viewModel.markModified()
    }

    private func assignCardToSlot(riteUid: Int, slot: String, templateId: Int) {
        guard var save = viewModel.saveData,
              let riteIndex = save.rites.firstIndex(where: { $0.uid == riteUid }) else { return }

        // 查找或创建对应模板的卡牌
        if let existingCard = save.cards.first(where: { $0.id == templateId }) {
            save.rites[riteIndex].cards[slot] = Rite.CardReference(uid: existingCard.uid)
        } else {
            // 添加新卡牌再引用
            viewModel.cardService.addCard(to: &save, templateId: templateId)
            if let newCard = save.cards.last {
                save.rites[riteIndex].cards[slot] = Rite.CardReference(uid: newCard.uid)
            }
        }

        viewModel.saveData = save
        viewModel.markModified()
    }
}
