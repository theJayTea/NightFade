import SwiftUI

@main
struct NightFadeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var debugModeEnabled = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(debugModeEnabled: $debugModeEnabled)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Night Fade") {
                    showAboutWindow()
                }
            }
            
            CommandGroup(replacing: .newItem) {
                Button(debugModeEnabled ? "Disable Debug Mode" : "Enable Debug Mode") {
                    debugModeEnabled.toggle()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Learn More (open GitHub Readme)") {
                    if let url = URL(string: "https://github.com/theJayTea/NightFade#readme") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Check for Updates") {
                    if let url = URL(string: "https://github.com/theJayTea/NightFade/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    private func showAboutWindow() {
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        aboutWindow.title = "About Night Fade"
        aboutWindow.isReleasedWhenClosed = false
        aboutWindow.center()
        aboutWindow.contentView = NSHostingView(rootView: AboutView())
        aboutWindow.makeKeyAndOrderFront(nil)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}