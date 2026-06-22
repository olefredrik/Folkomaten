import Foundation
import ServiceManagement

/// Styrer om appen starter automatisk ved innlogging, via `SMAppService` (macOS 13+).
///
/// `SMAppService.mainApp` krever en ekte `.app`-bundle. Under `swift run` finnes ikke
/// det, og da er funksjonen utilgjengelig (`isAvailable == false`).
@MainActor
final class LoginItemController: ObservableObject {

    /// Sant når appen er registrert som påloggingsobjekt.
    @Published private(set) var isEnabled = false
    /// Feilmelding fra siste forsøk på å endre status, hvis noe gikk galt.
    @Published private(set) var lastError: String?

    init() {
        refresh()
    }

    /// `SMAppService` virker bare når appen kjører fra en `.app`-bundle.
    var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app")
    }

    /// Leser gjeldende status fra systemet.
    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    /// Slår oppstart ved innlogging av eller på.
    func setEnabled(_ enabled: Bool) {
        guard isAvailable else { return }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }
}
