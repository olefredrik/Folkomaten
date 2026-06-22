import SwiftUI
import AppKit
import TestborgerKit

/// Skjuler Dock-ikonet slik at appen kun lever i menylinjen (også når den kjøres
/// uten en `LSUIElement`-Info.plist, f.eks. via `swift run`).
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct TestborgerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TestUserStore()

    var body: some Scene {
        MenuBarExtra("Testborger", systemImage: "person.text.rectangle") {
            MenuContentView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)

    }
}
