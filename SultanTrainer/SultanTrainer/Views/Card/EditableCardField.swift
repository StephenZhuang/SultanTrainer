import SwiftUI

/// 可编辑的数值字段，用于卡牌列表中的数量和生命编辑
struct EditableCardField: View {
    let value: Int
    let range: ClosedRange<Int>
    let onUpdate: (Int) -> Void

    @State private var isEditing = false
    @State private var editText: String = ""

    var body: some View {
        Group {
            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                    .onSubmit {
                        commitEdit()
                    }
                    .onExitCommand {
                        cancelEdit()
                    }
            } else {
                Text("\(value)")
                    .frame(width: 50, alignment: .trailing)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startEdit()
                    }
            }
        }
    }

    private func startEdit() {
        editText = "\(value)"
        isEditing = true
    }

    private func commitEdit() {
        if let newValue = Int(editText) {
            let clamped = max(range.lowerBound, min(range.upperBound, newValue))
            onUpdate(clamped)
        }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }
}
