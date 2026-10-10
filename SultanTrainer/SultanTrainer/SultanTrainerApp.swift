import SwiftUI

@main
struct SultanTrainerApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.initialize()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
    }
}
