import SwiftUI

struct CharacterAttributeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedCharacterUid: Int?
    @State private var editingValues: [String: Int] = [:]
    @State private var hasAnimalHandlingSlot: Bool = false
    @State private var hasLockFriendship: Bool = false

    private var characters: [Card] {
        viewModel.characters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 人物选择
            HStack {
                Text("选择人物:")
                Picker("人物", selection: $selectedCharacterUid) {
                    Text("请选择").tag(nil as Int?)
                    ForEach(characters) { card in
                        Text(viewModel.cardDisplayName(card: card, saveName: viewModel.saveData?.name))
                            .tag(card.uid as Int?)
                    }
                }
                .frame(width: 200)
            }

            if let uid = selectedCharacterUid,
               let character = viewModel.saveData?.cards.first(where: { $0.uid == uid }) {

                // 属性区域
                GroupBox("属性") {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading)
                    ], spacing: 12) {
                        ForEach(AttributeType.allCases) { attr in
                            HStack {
                                Text(attr.displayName)
                                    .frame(width: 40, alignment: .leading)

                                TextField("", value: attributeBinding(for: attr, character: character), format: .number)
                                    .frame(width: 60)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: editingValues[attr.rawValue]) { _, newValue in
                                        if let val = newValue, val > 999 {
                                            editingValues[attr.rawValue] = 999
                                        }
                                    }

                                Stepper("", value: attributeBinding(for: attr, character: character), in: 0...999)
                                    .labelsHidden()

                                if let val = editingValues[attr.rawValue], val > 999 || val < 0 {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 装备区域
                GroupBox("装备") {
                    HStack {
                        Toggle("驯兽槽", isOn: $hasAnimalHandlingSlot)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                // 状态区域
                GroupBox("状态") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button("医治受伤") {
                                viewModel.removeHurtTag(characterUid: uid)
                            }
                            .disabled(!character.equips.contains { $0.templateId == 2000098 })

                            Button("医治诅咒") {
                                viewModel.removeCurseTag(characterUid: uid)
                            }
                            .disabled(!character.equips.contains { $0.templateId == 2000163 })

                            Spacer()
                        }

                        Toggle("命运的羁绊", isOn: $hasLockFriendship)
                            .onChange(of: hasLockFriendship) { _, newValue in
                                viewModel.setLockFriendship(characterUid: uid, enabled: newValue)
                            }
                    }
                    .padding(.vertical, 4)
                }

                Button("应用修改") {
                    applyAttributes(characterUid: uid)
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            if selectedCharacterUid == nil, let first = characters.first {
                selectedCharacterUid = first.uid
                loadEditingValues(for: first)
            }
        }
        .onChange(of: selectedCharacterUid) { _, newUid in
            if let uid = newUid,
               let character = viewModel.saveData?.cards.first(where: { $0.uid == uid }) {
                loadEditingValues(for: character)
            }
        }
    }

    private func attributeBinding(for attr: AttributeType, character: Card) -> Binding<Int> {
        return Binding(
            get: { editingValues[attr.rawValue] ?? character.tag[attr.rawValue] ?? 0 },
            set: { editingValues[attr.rawValue] = $0 }
        )
    }

    private func loadEditingValues(for character: Card) {
        for attr in AttributeType.allCases {
            editingValues[attr.rawValue] = character.tag[attr.rawValue] ?? 0
        }
        hasAnimalHandlingSlot = character.equip_slots.contains("animal_handling")
        hasLockFriendship = character.tag["lock_friendship"] == 1
    }

    private func applyAttributes(characterUid: Int) {
        for attr in AttributeType.allCases {
            if let value = editingValues[attr.rawValue] {
                viewModel.updateCharacterAttribute(characterUid: characterUid, attr: attr, value: value)
            }
        }
        viewModel.setEquipSlot(characterUid: characterUid, slot: "animal_handling", enabled: hasAnimalHandlingSlot)
    }
}
