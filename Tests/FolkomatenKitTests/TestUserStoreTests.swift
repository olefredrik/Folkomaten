import Testing
import Foundation
@testable import FolkomatenKit

private func freshDefaults(_ name: String) -> UserDefaults {
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

@MainActor
@Test func clearEmptiesAndPersistsAcrossLaunches() {
    let defaults = freshDefaults("store-clear-test")

    let store = TestUserStore(defaults: defaults)
    #expect(!store.users.isEmpty)  // innebygde brukere som standard

    store.clear()
    #expect(store.users.isEmpty)

    // Ny «oppstart» med samme defaults skal fortsatt være tom.
    let reopened = TestUserStore(defaults: defaults)
    #expect(reopened.users.isEmpty)
}

@MainActor
@Test func isShowingEmbeddedReflectsSource() {
    let defaults = freshDefaults("store-embedded-flag-test")

    let store = TestUserStore(defaults: defaults)
    #expect(store.isShowingEmbedded)  // innebygde brukere som standard

    store.clear()
    #expect(!store.isShowingEmbedded)  // tom liste er ikke eksempelbrukerne

    store.loadEmbedded()
    #expect(store.isShowingEmbedded)
}

@MainActor
@Test func loadEmbeddedUndoesClear() {
    let defaults = freshDefaults("store-restore-test")

    let store = TestUserStore(defaults: defaults)
    store.clear()
    store.loadEmbedded()
    #expect(!store.users.isEmpty)

    // Valget om å vise eksempelbrukere skal også overleve omstart.
    let reopened = TestUserStore(defaults: defaults)
    #expect(!reopened.users.isEmpty)
}

// Fixture-fila er UTF-16LE med BOM og CRLF, slik BankID preprod leverer filene sine.
// Dekker disk-lesing med ekte bytes; `fileDataRoundTrips` dekker bare bytes i minnet.
@MainActor
@Test func parseFileReadsUTF16WithBOMFromDisk() throws {
    let url = try #require(
        Bundle.module.url(forResource: "testbrukere-preprod-utf16", withExtension: "txt")
    )

    let data = try Data(contentsOf: url)
    #expect(data.prefix(2) == Data([0xFF, 0xFE]))

    let users = try TestUserStore.parseFile(at: url)
    #expect(users.count == 10)
    #expect(users.first?.fnr == "05818697610")

    // Æ, Ø og Å overlever tegnsett-deteksjonen.
    #expect(users.contains { $0.lastName == "Ostehøvel" })
    #expect(users.contains { $0.firstName == "Øvrige" })
}
