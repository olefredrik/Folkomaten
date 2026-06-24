import AppKit
import Carbon.HIToolbox

/// En tastatursnarvei: en virtuell tastkode pluss modifikatorer, med en
/// menneskelesbar visning (f.eks. «⌃⌥F»).
struct Shortcut: Equatable {
    var keyCode: UInt32
    var modifiers: NSEvent.ModifierFlags
    var display: String

    /// Standard: ⌃⌥F (F = virtuell tastkode 3).
    /// ⌃⌥ er bevisst valgt fordi apper (som VS Code) sjelden binder den, så
    /// den globale snarveien ikke kaprer kjente kombinasjoner.
    static let `default` = Shortcut(
        keyCode: 3,
        modifiers: [.control, .option],
        display: "⌃⌥F"
    )

    /// Modifikatorene omgjort til Carbon-maska `RegisterEventHotKey` forventer.
    var carbonModifiers: UInt32 {
        var flags: UInt32 = 0
        if modifiers.contains(.command) { flags |= UInt32(cmdKey) }
        if modifiers.contains(.option)  { flags |= UInt32(optionKey) }
        if modifiers.contains(.control) { flags |= UInt32(controlKey) }
        if modifiers.contains(.shift)   { flags |= UInt32(shiftKey) }
        return flags
    }

    /// Bygger visningsstrengen i konvensjonell rekkefølge (⌃⌥⇧⌘ + tast).
    static func describe(modifiers: NSEvent.ModifierFlags, key: String) -> String {
        var prefix = ""
        if modifiers.contains(.control) { prefix += "⌃" }
        if modifiers.contains(.option)  { prefix += "⌥" }
        if modifiers.contains(.shift)   { prefix += "⇧" }
        if modifiers.contains(.command) { prefix += "⌘" }
        return prefix + key.uppercased()
    }
}

/// Lagrer den valgte snarveien i `UserDefaults` slik at den huskes til neste oppstart.
enum ShortcutSettings {
    private static let keyCodeKey   = "shortcut.keyCode"
    private static let modifiersKey = "shortcut.modifiers"
    private static let displayKey   = "shortcut.display"

    static var current: Shortcut {
        get {
            let defaults = UserDefaults.standard
            guard defaults.object(forKey: keyCodeKey) != nil else { return .default }
            return Shortcut(
                keyCode: UInt32(defaults.integer(forKey: keyCodeKey)),
                modifiers: NSEvent.ModifierFlags(rawValue: UInt(defaults.integer(forKey: modifiersKey))),
                display: defaults.string(forKey: displayKey) ?? Shortcut.default.display
            )
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(Int(newValue.keyCode), forKey: keyCodeKey)
            defaults.set(Int(newValue.modifiers.rawValue), forKey: modifiersKey)
            defaults.set(newValue.display, forKey: displayKey)
        }
    }
}

/// Registrerer én systemglobal hurtigtast via Carbon, slik at appen kan åpnes
/// uansett hvilken app som er aktiv – og uavhengig av menylinje-ikonet.
@MainActor
final class GlobalHotKey {
    static let shared = GlobalHotKey()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: (() -> Void)?
    private let signature: OSType = 0x464F4C4B // 'FOLK'

    private init() {}

    /// Setter handleren som kjøres når hurtigtasten trykkes.
    func setHandler(_ handler: @escaping () -> Void) {
        self.handler = handler
        installEventHandlerIfNeeded()
    }

    /// Registrerer (eller om-registrerer) en snarvei.
    func register(_ shortcut: Shortcut) {
        unregister()
        let id = EventHotKeyID(signature: signature, id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode, shortcut.carbonModifiers, id,
            GetEventDispatcherTarget(), 0, &ref
        )
        if status == noErr { hotKeyRef = ref }
    }

    private func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = nil
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }
        var type = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let center = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { center.handler?() }
                return noErr
            },
            1, &type, context, &eventHandlerRef
        )
    }
}
