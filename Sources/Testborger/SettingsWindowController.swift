import AppKit
import SwiftUI

/// Håndterer innstillingsvinduet som et frittstående NSWindow.
/// Bruker NSWindowController fremfor SwiftUI Window-scene for å fungere
/// korrekt i en .accessory-policy menylinjeapp.
@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let hosting = NSHostingController(rootView: MaskinportenSettingsView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "Maskinporten-innstillinger"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 440, height: 470))
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
