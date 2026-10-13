import SwiftUI

struct SavePickerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(viewModel.availableSaves, id: \.autoSavePath) { saveInfo in
                Button {
                    viewModel.loadSave(at: saveInfo)
                    viewModel.showSavePicker = false
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(saveInfo.steamId)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(saveInfo.modifiedDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("选择存档")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}
