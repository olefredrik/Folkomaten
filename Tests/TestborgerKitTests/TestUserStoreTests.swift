import Testing
import Foundation
@testable import TestborgerKit

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
