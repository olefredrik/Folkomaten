import SwiftUI
import AppKit
import FolkomatenKit

/// Driver hele appen fra AppKit. Klikk på menylinje-ikonet åpner en `NSPopover`
/// forankret til ikonet (den race-frie standardmåten for statuselementer). En
/// global hurtigtast åpner det samme – og når ikonet er skjult bak notch-en,
/// faller den tilbake til et flytende panel ved muspekeren.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = TestUserStore()
    private var statusItem: NSStatusItem?

    /// Fast størrelse på innholdet (matcher `MenuContentView`).
    private let contentSize = NSSize(width: 400, height: 480)

    /// Popover forankret til menylinje-ikonet (klikk + hurtigtast når ikonet vises).
    private lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient // lukkes automatisk når man klikker utenfor
        popover.contentSize = contentSize
        return popover
    }()

    /// Friskt innhold ved hver åpning, så popoveren aldri arver gammel
    /// layout/størrelse fra forrige visning (data ligger i den delte `store`).
    private func makeContentController() -> NSViewController {
        let hosting = NSHostingController(rootView: MenuContentView().environmentObject(store))
        hosting.preferredContentSize = contentSize
        return hosting
    }

    /// Flytende panel ved muspekeren – fallback når ikonet er skjult bak notch-en.
    private lazy var panel = PanelController(
        rootView: MenuContentView().environmentObject(store)
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ingen Dock-ikon – appen lever i menylinjen.
        NSApp.setActivationPolicy(.accessory)

        setUpStatusItem()

        // Global hurtigtast: virker uansett om menylinje-ikonet er synlig.
        GlobalHotKey.shared.setHandler { [weak self] in self?.toggleFromHotkey() }
        GlobalHotKey.shared.register(ShortcutSettings.current)
    }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = Self.menuBarIcon
        item.button?.action = #selector(statusItemClicked)
        item.button?.target = self
        statusItem = item
    }

    @objc private func statusItemClicked() {
        togglePopover()
    }

    /// Hurtigtasten: bruk popover når ikonet er synlig, ellers panelet ved pekeren.
    private func toggleFromHotkey() {
        if let button = statusItem?.button, buttonIsOnScreen(button) {
            togglePopover()
        } else {
            panel.toggle(anchorTo: nil)
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.contentViewController = makeContentController()
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    /// Sant når menylinje-knappen faktisk er synlig på en skjerm (ikke skjøvet
    /// vekk bak notch-en på en full menylinje).
    private func buttonIsOnScreen(_ button: NSStatusBarButton) -> Bool {
        guard let window = button.window, let screen = window.screen else { return false }
        let rect = window.convertToScreen(button.convert(button.bounds, to: nil))
        return screen.frame.intersects(rect)
    }

    /// Menylinje-ikonet. Fylte silhuetter leser tydelig i det lille
    /// template-formatet – `person.2.fill` («folk») er distinkt og på-merke.
    /// Bytt symbolnavnet her for et annet ikon.
    private static let iconSymbolName = "person.text.rectangle.fill"
    /// Punktstørrelse på menylinje-ikonet (standard er ~15; menylinjen tåler ~18).
    private static let iconPointSize: CGFloat = 18

    private static var menuBarIcon: NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: iconPointSize, weight: .regular)
        let image = NSImage(systemSymbolName: iconSymbolName, accessibilityDescription: "Folkomaten")?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
    }
}

@main
struct FolkomatenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Tom scene: all UI styres fra AppDelegate. `Settings` åpner ingen vindu
        // av seg selv, og tilfredsstiller kravet om minst én scene.
        Settings { EmptyView() }
    }
}
