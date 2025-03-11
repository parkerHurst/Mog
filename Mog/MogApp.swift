import SwiftUI

@main
struct MogApp: App {
    @StateObject private var mouseTracker = MouseTracker()
    
    var body: some Scene {
        WindowGroup {
            ContentView(mouseTracker: mouseTracker)
                .frame(minWidth: 400, minHeight: 400)
                .onDisappear {
                    NSApplication.shared.setActivationPolicy(.accessory)
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Mog") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
            CommandGroup(after: .appInfo) {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
        }
    }
}
