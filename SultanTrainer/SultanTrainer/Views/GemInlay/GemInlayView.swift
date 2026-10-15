// Views/GemInlay/GemInlayView.swift
import SwiftUI

struct GemInlayView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var selectedEquipmentUid: Int?
    @State private var selectedGemUid: Int?
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
    var body: some View {
        HSplitView {
            // 左侧：装备列表
            equipmentListPanel
                .frame(minWidth: 300)
            
            // 右侧：宝石列表和操作
            gemListAndOperationPanel
                .frame(minWidth: 350)
        }
        .alert("操作成功", isPresented: $showSuccessMessage) {
            Button("确定") { }
        } message: {
            Text(successMessage)
        }
    }
    
    // MARK: - 装备列表面板
    
    private var equipmentListPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("装备列表")
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider()
            
            if viewModel.equipmentList.isEmpty {
                ContentUnavailableView(
                    "无装备",
                    systemImage: "tray",
                    description: Text("背包中没有可镶嵌宝石的装备")
                )
            } else {
                List(viewModel.equipmentList, selection: $selectedEquipmentUid) { equipment in
                    EquipmentRow(
                        equipment: equipment,
                        viewModel: viewModel
                    )
                    .tag(equipment.uid)
                }
            }
        }
    }
    
    // MARK: - 宝石列表和操作面板
    
    private var gemListAndOperationPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 宝石列表
            Text("宝石列表")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Divider()
            
            if viewModel.gemList.isEmpty {
                ContentUnavailableView(
                    "无宝石",
                    systemImage: "diamond",
                    description: Text("背包中没有可镶嵌的宝石")
                )
                .frame(maxHeight: .infinity)
            } else {
                List(viewModel.gemList, selection: $selectedGemUid) { gem in
                    GemRow(
                        gem: gem,
                        viewModel: viewModel
                    )
                    .tag(gem.uid)
                }
                .frame(maxHeight: .infinity)
            }
            
            Divider()
            
            // 操作按钮
            operationPanel
                .padding()
        }
    }
    
    // MARK: - 操作面板
    
    private var operationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let equipmentUid = selectedEquipmentUid,
               let equipment = viewModel.equipmentList.first(where: { $0.uid == equipmentUid }) {
                
                // 装备信息
                VStack(alignment: .leading, spacing: 4) {
                    Text("选中装备：\(viewModel.getCardDisplayName(card: equipment))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if viewModel.isInlaid(equipment: equipment) {
                        if let gem = viewModel.getInlaidGem(from: equipment) {
                            Text("已镶嵌：\(viewModel.getCardDisplayName(card: gem))")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("属性：\(viewModel.getGemAttributeDescription(gem: gem))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("未镶嵌宝石")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    // 镶嵌/替换按钮
                    Button {
                        performInlay(equipment: equipment)
                    } label: {
                        Label(
                            viewModel.isInlaid(equipment: equipment) ? "替换宝石" : "镶嵌宝石",
                            systemImage: "diamond.fill"
                        )
                    }
                    .disabled(selectedGemUid == nil)
                    
                    // 拆卸按钮
                    if viewModel.isInlaid(equipment: equipment) {
                        Button(role: .destructive) {
                            performRemove(equipment: equipment)
                        } label: {
                            Label("拆卸宝石", systemImage: "trash")
                        }
                    }
                }
            } else {
                Text("请选择一件装备")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - 操作方法
    
    private func performInlay(equipment: Card) {
        guard let gemUid = selectedGemUid else { return }
        
        let oldGem = viewModel.inlayGem(equipmentUid: equipment.uid, gemUid: gemUid)
        
        if let oldGem = oldGem {
            successMessage = "已替换宝石\n旧宝石「\(viewModel.getCardDisplayName(card: oldGem))」已返回背包"
        } else {
            successMessage = "已成功镶嵌宝石"
        }
        showSuccessMessage = true
        
        // 清除选择
        selectedGemUid = nil
    }
    
    private func performRemove(equipment: Card) {
        if let gem = viewModel.removeGem(equipmentUid: equipment.uid) {
            successMessage = "已拆卸宝石「\(viewModel.getCardDisplayName(card: gem))」\n宝石已返回背包"
            showSuccessMessage = true
        }
    }
}

// MARK: - 装备行视图

struct EquipmentRow: View {
    let equipment: Card
    let viewModel: AppViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.getCardDisplayName(card: equipment))
                    .font(.system(size: 13))
                
                if viewModel.isInlaid(equipment: equipment) {
                    if let gem = viewModel.getInlaidGem(from: equipment) {
                        Text("镶嵌：\(viewModel.getCardDisplayName(card: gem))")
                            .font(.system(size: 11))
                            .foregroundStyle(.blue)
                    }
                } else {
                    Text("未镶嵌")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if viewModel.isInlaid(equipment: equipment) {
                Image(systemName: "diamond.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 12))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 宝石行视图

struct GemRow: View {
    let gem: Card
    let viewModel: AppViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.getCardDisplayName(card: gem))
                    .font(.system(size: 13))
                
                Text(viewModel.getGemAttributeDescription(gem: gem))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "diamond")
                .foregroundStyle(.green)
                .font(.system(size: 12))
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    GemInlayView()
        .environmentObject(AppViewModel())
}
