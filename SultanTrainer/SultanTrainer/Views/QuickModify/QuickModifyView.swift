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
                        quickButton("金币+999") { viewModel.quickAddGold() }
                        quickButton("全属性满") { viewModel.quickMaxAttributes() }
                        quickButton("直接胜利") { viewModel.quickInstantVictory() }
                        quickButton("回合数+1") { viewModel.quickIncrementRound() }
                        quickButton("清空苏丹卡") { viewModel.quickClearSudanCards() }
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("全局数据 (global.json)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        quickButton("升级点数+100") { viewModel.quickAddUpgradePoints() }
                        quickButton("解锁所有结局") { viewModel.quickUnlockAllEndings() }
                        quickButton("解锁所有升级") { viewModel.quickUnlockAllUpgrades() }
                        quickButton("完成所有任务") { viewModel.quickCompleteAllQuests() }
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
                triggerCooldown()
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
        return lastActionTime != nil
    }

    private func triggerCooldown() {
        lastActionTime = Date()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(GameConstants.actionCooldown))
            lastActionTime = nil
        }
    }
}
