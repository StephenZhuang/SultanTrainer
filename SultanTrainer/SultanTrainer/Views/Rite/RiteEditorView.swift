import SwiftUI

struct RiteEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedRiteUid: Int?
    @State private var editingSlotIndex: Int?
    @State private var showCardPicker = false
    @State private var pendingSlotUid: Int?
    @State private var remainingRoundsText: String = ""

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

                List {
                    ForEach(rites) { rite in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.getRiteName(riteId: rite.id))
                                .font(.body)
                            Text("ID: \(rite.id)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .background(selectedRiteUid == rite.uid ? Color.accentColor.opacity(0.15) : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRiteUid = rite.uid
                        }
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 250)

            // 右侧：仪式详情
            if let riteUid = selectedRiteUid,
               let rite = rites.first(where: { $0.uid == riteUid }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.getRiteName(riteId: rite.id))
                        .font(.title2)
                        .fontWeight(.semibold)

                    // 仪式描述
                    let riteText = viewModel.getRiteText(riteId: rite.id)
                    if !riteText.isEmpty {
                        Text(riteText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider()

                    // 剩余回合数
                    HStack {
                        Text("剩余回合数:")
                            .font(.subheadline)
                        TextField(remainingRoundsText.isEmpty ? "未设置" : "剩余回合数", text: $remainingRoundsText)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if let value = Int(remainingRoundsText) {
                                    viewModel.setRiteRemainingRounds(riteId: rite.id, value: value)
                                }
                            }
                        Button("确定") {
                            if let value = Int(remainingRoundsText) {
                                viewModel.setRiteRemainingRounds(riteId: rite.id, value: value)
                            }
                        }
                        if remainingRoundsText.isEmpty {
                            Text("(空表示未设置)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    Text("槽位")
                        .font(.subheadline)
                        .fontWeight(.medium)

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
                .frame(minWidth: 400)
                .id(riteUid)
                .onAppear {
                    updateRemainingRoundsText(for: rite.id)
                }
            } else {
                VStack {
                    Text("选择一个仪式查看详情")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minWidth: 400)
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

    private func updateRemainingRoundsText(for riteId: Int) {
        if let rounds = viewModel.getRiteRemainingRounds(riteId: riteId) {
            remainingRoundsText = String(rounds)
        } else {
            // 如果 end_rites 中没有，使用配置中的 waiting_round 作为默认值
            let waitingRound = viewModel.getRiteWaitingRound(riteId: riteId)
            remainingRoundsText = waitingRound > 0 ? String(waitingRound) : ""
        }
    }
}
