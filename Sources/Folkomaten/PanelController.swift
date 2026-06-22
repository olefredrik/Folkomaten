import AppKit
import SwiftUI

/// Identifikatoren som lar resten av appen finne og lukke panelet (se
/// `MenuContentView.closePanel()`) uten å kjenne til denne klassen.
let folkomatenPanelIdentifier = NSUserInterfaceItemIdentifier("FolkomatenPanel")

/// Et kantløst, popover-aktig panel som *kan* ta tastaturfokus, slik at
/// søkefeltet i innholdet virker.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Eier det flytende panelet som viser `MenuContentView`.
///
/// I motsetning til `MenuBarExtra` er dette panelet ikke avhengig av at
/// menylinje-ikonet er synlig: når ikonet er skjult (full menylinje / bak
/// notch-en) åpnes panelet i stedet ved muspekeren via den globale hurtigtasten.
@MainActor
final class PanelController {
    /// Innholdets faste størrelse (matcher `MenuContentView`).
    private let contentSize = NSSize(width: 400, height: 480)
    private let rootView: AnyView
    private var panel: NSPanel?

    init<Content: View>(rootView: Content) {
        self.rootView = AnyView(rootView)
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    /// Åpner panelet hvis det er skjult, lukker det hvis det er synlig.
    func toggle(anchorTo button: NSStatusBarButton?) {
        if isVisible {
            close()
        } else {
            open(anchorTo: button)
        }
    }

    func open(anchorTo button: NSStatusBarButton?) {
        let panel = ensurePanel()
        panel.setFrameOrigin(origin(anchorTo: button))
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
    }

    // MARK: - Oppsett

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }

        let content = rootView
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            )

        let panel = KeyablePanel(contentViewController: NSHostingController(rootView: content))
        panel.identifier = folkomatenPanelIdentifier
        panel.styleMask = [.borderless]
        panel.setContentSize(contentSize)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = true       // forsvinner når man bytter app
        panel.isMovableByWindowBackground = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow

        // Esc lukker panelet (men bare når det faktisk er synlig).
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible, event.keyCode == 53 else { return event }
            self.close()
            return nil
        }

        self.panel = panel
        return panel
    }

    // MARK: - Plassering

    /// Forankrer panelet under menylinje-knappen når den er synlig på en skjerm,
    /// ellers ved muspekeren (når ikonet er skjult bak notch-en).
    private func origin(anchorTo button: NSStatusBarButton?) -> NSPoint {
        let gap: CGFloat = 6

        if let button, let window = button.window {
            let rect = window.convertToScreen(button.convert(button.bounds, to: nil))
            if let screen = screen(containing: NSPoint(x: rect.midX, y: rect.midY)),
               screen.frame.intersects(rect) {
                let point = NSPoint(x: rect.midX - contentSize.width / 2,
                                    y: rect.minY - gap - contentSize.height)
                return clamp(point, to: screen)
            }
        }

        let mouse = NSEvent.mouseLocation
        let screen = screen(containing: mouse) ?? NSScreen.main ?? NSScreen.screens[0]
        let point = NSPoint(x: mouse.x - contentSize.width / 2,
                            y: mouse.y - contentSize.height - gap)
        return clamp(point, to: screen)
    }

    private func screen(containing point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
    }

    /// Holder panelet innenfor det synlige området av skjermen.
    private func clamp(_ point: NSPoint, to screen: NSScreen) -> NSPoint {
        let frame = screen.visibleFrame
        let margin: CGFloat = 8
        let x = min(max(point.x, frame.minX + margin), frame.maxX - contentSize.width - margin)
        let y = min(max(point.y, frame.minY + margin), frame.maxY - contentSize.height - margin)
        return NSPoint(x: x, y: y)
    }
}
