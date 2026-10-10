import SwiftUI
struct GlobalDataView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var body: some View { Text("全局数据") }
}
