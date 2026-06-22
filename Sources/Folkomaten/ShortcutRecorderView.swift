import SwiftUI
import AppKit

/// En liten snarvei-velger: klikk for å ta opp, trykk så ønsket tastkombinasjon.
/// Krever minst én modifikator, og Esc avbryter opptaket.
struct ShortcutRecorderView: View {
    @State private var shortcut = ShortcutSettings.current
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            isRecording ? stopRecording() : startRecording()
        } label: {
            Text(isRecording ? "Trykk snarvei…" : shortcut.display)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 96)
        }
        .help(isRecording ? "Trykk ønsket tastkombinasjon (Esc avbryter)"
                          : "Klikk for å endre hurtigtasten")
        .onDisappear(perform: stopRecording)
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            record(event)
            return nil // svelg tasten så den ikke trigger annen UI
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private func record(_ event: NSEvent) {
        if event.keyCode == 53 { stopRecording(); return } // Esc avbryter

        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let key = event.charactersIgnoringModifiers ?? ""

        // Krev minst én modifikator, ellers kan en enkelt tast kapre tastaturet globalt.
        guard !modifiers.isEmpty, !key.isEmpty else {
            NSSound.beep()
            return
        }

        let new = Shortcut(
            keyCode: UInt32(event.keyCode),
            modifiers: modifiers,
            display: Shortcut.describe(modifiers: modifiers, key: key)
        )
        shortcut = new
        ShortcutSettings.current = new
        GlobalHotKey.shared.register(new)
        stopRecording()
    }
}
