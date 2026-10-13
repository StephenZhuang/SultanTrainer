import SwiftUI

struct GlobalDataView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var editingTotalPoint: Int = 0

    var body: some View {
        ScrollView {
            if let global = viewModel.globalData {
                VStack(alignment: .leading, spacing: 24) {
                    // 基本信息
                    GroupBox("基本信息") {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                            GridRow {
                                Text("总回合数:")
                                Text("\(global.totalRound)")
                            }
                            GridRow {
                                Text("总升级点数:")
                                editableIntField(
                                    value: $editingTotalPoint
                                )
                            }
                            GridRow {
                                Text("已使用点数:")
                                Text("\(global.usedPoint)")
                            }
                            GridRow {
                                Text("已完成局数:")
                                Text("\(global.doneRite.count)")
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // 已解锁结局
                    GroupBox("已解锁结局 (\(global.overID.count))") {
                        if global.overID.isEmpty {
                            Text("暂无").foregroundStyle(.secondary)
                        } else {
                            FlowLayout(spacing: 8) {
                                ForEach(global.overID.sorted(), id: \.self) { id in
                                    Text(viewModel.overTemplateName(id: id))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // 升级列表
                    GroupBox("已获取升级 (\(global.upgrade.count))") {
                        if global.upgrade.isEmpty {
                            Text("暂无").foregroundStyle(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], alignment: .leading, spacing: 4) {
                                ForEach(global.upgrade.sorted(by: { $0.key < $1.key }), id: \.key) { id, level in
                                    Text("\(viewModel.upgradeTemplateName(id)) (Lv.\(level))")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // 任务列表
                    GroupBox("任务状态 (\(global.quest.count))") {
                        if global.quest.isEmpty {
                            Text("暂无").foregroundStyle(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], alignment: .leading, spacing: 4) {
                                ForEach(global.quest.sorted(by: { $0.key < $1.key }), id: \.key) { id, status in
                                    let name = viewModel.questTemplateName(id)
                                    HStack {
                                        Text(name)
                                            .font(.caption)
                                        Spacer()
                                        Text(status == 2 ? "已完成" : "进行中")
                                            .font(.caption2)
                                            .foregroundStyle(status == 2 ? .green : .secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
                .onAppear {
                    editingTotalPoint = global.totalPoint
                }
                .onChange(of: editingTotalPoint) { oldValue, newValue in
                    guard oldValue != newValue,
                          viewModel.globalData?.totalPoint != newValue else { return }
                    Task { @MainActor in
                        viewModel.updateTotalPoint(newValue)
                    }
                }
            } else {
                Text("全局数据未加载")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func editableIntField(value: Binding<Int>) -> some View {
        HStack {
            TextField("", value: value, format: .number)
                .frame(width: 100)
                .textFieldStyle(.roundedBorder)
            Stepper("", value: value, in: 0...999999)
                .labelsHidden()
        }
    }
}

/// 简单的流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
