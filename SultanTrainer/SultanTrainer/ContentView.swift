// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $viewModel.selectedSidebarItem) { item in
                Label(item.rawValue, systemImage: item.iconName)
                    .tag(item)
            }
            .navigationTitle("SultanTrainer")
            .frame(minWidth: 180)
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    if viewModel.hasUnsavedChanges {
                        Text("已修改 ·")
                            .foregroundStyle(.orange)
                    }
                    if let msg = viewModel.lastSaveMessage {
                        Text(msg)
                            .foregroundStyle(.green)
                    }
                    Button("保存") {
                        viewModel.save()
                        viewModel.saveGlobal()
                    }
                    .disabled(!viewModel.hasUnsavedChanges)
                }
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if viewModel.isLoading {
            ProgressView("加载中...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.saveData == nil && viewModel.errorMessage != nil {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text(viewModel.errorMessage ?? "")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch viewModel.selectedSidebarItem ?? .quickModify {
            case .quickModify:
                QuickModifyView()
            case .cardManage:
                CardListView()
            case .characterAttribute:
                CharacterAttributeView()
            case .counter:
                CounterEditorView()
            case .rite:
                RiteEditorView()
            case .globalData:
                GlobalDataView()
            }
        }
    }
}
