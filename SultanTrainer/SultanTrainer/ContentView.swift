// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedTab: SidebarItem? = .quickModify
    @State private var showReloadConfirmation = false

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedTab) { item in
                Label(item.rawValue, systemImage: item.iconName)
                    .tag(item)
            }
            .navigationTitle("SultanTrainer")
            .frame(minWidth: 180)
        } detail: {
            detailView
        }
        .onChange(of: selectedTab) { _, newValue in
            Task { @MainActor in
                viewModel.selectedSidebarItem = newValue
            }
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

                    Divider()
                        .frame(height: 16)

                    Button {
                        if viewModel.hasUnsavedChanges {
                            showReloadConfirmation = true
                        } else {
                            viewModel.reloadSave()
                        }
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .alert("错误", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("刷新存档", isPresented: $showReloadConfirmation) {
            Button("取消", role: .cancel) {}
            Button("刷新", role: .destructive) {
                viewModel.reloadSave()
            }
        } message: {
            Text("当前未保存的修改将丢失，是否继续？")
        }
        .sheet(isPresented: $viewModel.showSavePicker) {
            SavePickerView()
                .environmentObject(viewModel)
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
            switch selectedTab ?? .quickModify {
            case .quickModify:
                QuickModifyView()
            case .cardManage:
                CardListView()
            case .characterAttribute:
                CharacterAttributeView()
            case .gemInlay:
                GemInlayView()
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
