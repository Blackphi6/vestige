import SwiftUI

@main
struct VestigeApp: App {
    @StateObject private var updateChecker = UpdateCheckViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(updateChecker)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView()
                    .environmentObject(updateChecker)
            }
        }
    }
}
