// Views/QuickModify/QuickModifyView.swift
import SwiftUI

struct QuickModifyView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showConfirmDialog = false
    @State private var pendingAction: (() -> Void)?
    @State private var confirmTitle = ""
    @State private var confirmMessage = ""
    @State private var lastActionTime: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GroupBox("当前局 (auto_save.json)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        quickButton("金币+999") { addGold() }
                        quickButton("全属性满") { maxAttributes() }
                        quickButton("直接胜利") { instantVictory() }
                        quickButton("回合数+1") { incrementRound() }
                        quickButton("清空苏丹卡") { clearSudanCards() }
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("全局数据 (global.json)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        quickButton("升级点数+100") { addUpgradePoints() }
                        quickButton("解锁所有结局") { unlockAllEndings() }
                        quickButton("解锁所有升级") { unlockAllUpgrades() }
                        quickButton("完成所有任务") { completeAllQuests() }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
        .alert(confirmTitle, isPresented: $showConfirmDialog) {
            Button("取消", role: .cancel) {}
            Button("确认") {
                pendingAction?()
            }
        } message: {
            Text(confirmMessage)
        }
    }

    private func quickButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title) {
            confirmTitle = "确认修改"
            confirmMessage = "确定要执行「\(title)」吗？"
            pendingAction = action
            showConfirmDialog = true
        }
        .buttonStyle(.borderedProminent)
        .disabled(isButtonDisabled())
    }

    private func isButtonDisabled() -> Bool {
        guard let lastTime = lastActionTime else { return false }
        return Date().timeIntervalSince(lastTime) < 1.0
    }

    private func executeAction(_ action: () -> Void) {
        action()
        viewModel.markModified()
        lastActionTime = Date()
    }

    // MARK: - 当前局操作

    private func addGold() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            viewModel.quickModifiers.addGold(to: &save, amount: 999)
            viewModel.saveData = save
        }
    }

    private func maxAttributes() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            guard let character = save.cards.first(where: { $0.id >= 2000001 && $0.id <= 2000010 }) else { return }
            viewModel.quickModifiers.maxAllAttributes(in: &save, characterUid: character.uid)
            viewModel.saveData = save
        }
    }

    private func instantVictory() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            viewModel.quickModifiers.instantVictory(in: &save)
            viewModel.saveData = save
        }
    }

    private func incrementRound() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            viewModel.quickModifiers.incrementRound(in: &save)
            viewModel.saveData = save
        }
    }

    private func clearSudanCards() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            viewModel.quickModifiers.clearSudanCards(in: &save)
            viewModel.saveData = save
        }
    }

    // MARK: - 全局数据操作

    private func addUpgradePoints() {
        executeAction {
            guard var global = viewModel.globalData else { return }
            viewModel.quickModifiers.addUpgradePoints(to: &global, amount: 100)
            viewModel.globalData = global
        }
    }

    private func unlockAllEndings() {
        executeAction {
            guard var global = viewModel.globalData else { return }
            let allIds = Array(viewModel.configLoader.overTemplates.keys)
            viewModel.quickModifiers.unlockAllEndings(in: &global, allEndingIds: allIds.isEmpty ? [0, 1, 2, 3, 4, 5] : allIds)
            viewModel.globalData = global
        }
    }

    private func unlockAllUpgrades() {
        executeAction {
            guard var global = viewModel.globalData else { return }
            let allIds = Array(viewModel.configLoader.upgradeTemplates.keys)
            viewModel.quickModifiers.unlockAllUpgrades(in: &global, allUpgradeIds: allIds)
            viewModel.globalData = global
        }
    }

    private func completeAllQuests() {
        executeAction {
            guard var global = viewModel.globalData else { return }
            let allIds = Array(viewModel.configLoader.questTemplates.keys)
            viewModel.quickModifiers.completeAllQuests(in: &global, allQuestIds: allIds)
            viewModel.globalData = global
        }
    }
}
