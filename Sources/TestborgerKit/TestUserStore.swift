import Foundation
import Combine

/// Holder testbrukerne og favorittene, og tar seg av innlasting og persistens.
///
/// - Standard datasett er den innebygde eksempelfila (`Resources/testbrukere.txt`).
/// - Brukeren kan laste inn egne filer; sist brukte fil huskes og lastes ved oppstart.
/// - Favoritter lagres som fødselsnummer i `UserDefaults` og gjelder på tvers av datasett.
@MainActor
public final class TestUserStore: ObservableObject {

    @Published public private(set) var users: [TestUser] = []
    @Published public private(set) var favorites: Set<String> = []
    /// Navnet på kilden som vises i UI (filnavn, eller «Innebygde testbrukere»).
    @Published public private(set) var sourceName: String = ""

    private let defaults: UserDefaults
    private let favoritesKey = "favoriteFnrs"
    private let lastFileKey = "lastLoadedFilePath"
    private let clearedKey = "userClearedList"
    private let embeddedSourceName = "Innebygde testbrukere"
    private let emptySourceName = "Ingen testbrukere"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.favorites = Set(defaults.stringArray(forKey: favoritesKey) ?? [])
        loadInitial()
    }

    // MARK: - Innlasting

    private func loadInitial() {
        // Brukeren har bevisst tømt lista – ikke fall tilbake til de innebygde.
        if defaults.bool(forKey: clearedKey) {
            users = []
            sourceName = emptySourceName
            return
        }
        if let path = defaults.string(forKey: lastFileKey) {
            let url = URL(fileURLWithPath: path)
            if let loaded = try? Self.parseFile(at: url), !loaded.isEmpty {
                users = loaded
                sourceName = url.lastPathComponent
                return
            }
            // Sist brukte fil finnes ikke lenger – fall tilbake til innebygd.
            defaults.removeObject(forKey: lastFileKey)
        }
        loadEmbedded()
    }

    /// Sant når det innebygde eksempel-datasettet vises nå.
    public var isShowingEmbedded: Bool { sourceName == embeddedSourceName }

    /// Last inn det innebygde eksempel-datasettet.
    public func loadEmbedded() {
        users = Self.embeddedUsers()
        sourceName = embeddedSourceName
        defaults.removeObject(forKey: lastFileKey)
        defaults.removeObject(forKey: clearedKey)
    }

    /// Last inn testbrukere fra en fil valgt av brukeren. Husker filstien til neste oppstart.
    public func loadFile(at url: URL) throws {
        let loaded = try Self.parseFile(at: url)
        users = loaded
        sourceName = url.lastPathComponent
        defaults.set(url.path, forKey: lastFileKey)
        defaults.removeObject(forKey: clearedKey)
    }

    /// Tøm lista. Valget huskes, så appen starter tom også ved neste oppstart, helt til
    /// brukeren laster inn en fil eller de innebygde eksempelbrukerne igjen.
    public func clear() {
        users = []
        sourceName = emptySourceName
        defaults.removeObject(forKey: lastFileKey)
        defaults.set(true, forKey: clearedKey)
    }

    // MARK: - Favoritter

    public func isFavorite(_ user: TestUser) -> Bool { favorites.contains(user.fnr) }

    public func toggleFavorite(_ user: TestUser) {
        if favorites.contains(user.fnr) {
            favorites.remove(user.fnr)
        } else {
            favorites.insert(user.fnr)
        }
        defaults.set(Array(favorites), forKey: favoritesKey)
    }

    // MARK: - Filtrering

    /// Filtrert og alfabetisk sortert liste for visning.
    public func filtered(search: String, onlyFavorites: Bool) -> [TestUser] {
        var result = users

        if onlyFavorites {
            result = result.filter { favorites.contains($0.fnr) }
        }

        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.fullName.lowercased().contains(query) || $0.fnr.contains(query)
            }
        }

        return result.sorted {
            $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending
        }
    }

    // MARK: - Parsing

    static func embeddedUsers() -> [TestUser] {
        guard let url = Bundle.module.url(forResource: "testbrukere", withExtension: "txt"),
              let users = try? parseFile(at: url) else {
            return []
        }
        return users
    }

    /// Leser en fil med auto-detektert tegnsett (håndterer UTF-16LE fra BankID preprod
    /// så vel som UTF-8) og parser linjene til testbrukere.
    static func parseFile(at url: URL) throws -> [TestUser] {
        var usedEncoding: String.Encoding = .utf8
        let content = try String(contentsOf: url, usedEncoding: &usedEncoding)
        return content
            .split(whereSeparator: \.isNewline)
            .compactMap { TestUser(line: String($0)) }
    }
}
