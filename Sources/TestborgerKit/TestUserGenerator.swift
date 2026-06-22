import Foundation

/// Genererer syntetiske BankID-testbrukere: gyldige Tenor-fødselsnummer (måned + 80 og
/// korrekte mod-11-kontrollsiffer) med tilfeldige norske navn.
///
/// Fila lastes opp i BankID preprod sin bulk-order-portal for å bestille brukerne, og
/// leses deretter inn i appen. Formatet er det samme appen ellers leser:
/// `fødselsnummer,fullt navn,etternavn,fornavn`, kodet som UTF-16 med BOM.
public enum TestUserGenerator {

    private static let firstNames = [
        "Frode", "Espen", "Dag", "Gunhild", "Bjørn", "Knut", "Roar", "Else", "Wenche",
        "Kari", "Astrid", "Leif", "Petter", "Camilla", "Magnus", "Geir", "Per", "Tone",
        "Rune", "Nora", "Stein", "Erik", "Trygve", "Anette", "Ola", "Berit", "Ida",
        "Silje", "Kjersti", "Hanne", "Mette", "Liv", "Solveig", "Arne", "Inger", "Marit",
    ]

    private static let lastNames = [
        "Aas", "Næss", "Sæther", "Hansen", "Iversen", "Johnsen", "Eriksen", "Pedersen",
        "Karlsen", "Bø", "Kristoffersen", "Sørensen", "Gundersen", "Vik", "Kristiansen",
        "Strøm", "Lien", "Isaksen", "Nilsen", "Haugen", "Wold", "Henriksen", "Solberg",
        "Tangen", "Berg", "Larsen", "Johansen", "Andreassen", "Olsen", "Dahl",
    ]

    /// Lag `count` unike, tilfeldige testbrukere.
    public static func generate(count: Int) -> [TestUser] {
        var users: [TestUser] = []
        var seen = Set<String>()
        while users.count < count {
            guard let fnr = randomFnr(), seen.insert(fnr).inserted else { continue }
            let first = firstNames.randomElement()!
            let last = lastNames.randomElement()!
            users.append(TestUser(
                fnr: fnr,
                fullName: "\(first) \(last)",
                lastName: last,
                firstName: first
            ))
        }
        return users
    }

    /// Serialiser til BankID preprod sitt filformat: komma-separert, UTF-16 med BOM.
    public static func fileData(for users: [TestUser]) -> Data {
        let text = users.map(line(for:)).joined(separator: "\r\n") + "\r\n"
        return text.data(using: .utf16) ?? Data()
    }

    static func line(for user: TestUser) -> String {
        "\(user.fnr),\(user.fullName),\(user.lastName),\(user.firstName)"
    }

    // MARK: - Fødselsnummer

    private static func randomFnr() -> String? {
        let year = Int.random(in: 1945...2004)
        let month = Int.random(in: 1...12)
        let day = Int.random(in: 1...28)         // alltid en gyldig dato, uansett måned
        let yy = year % 100

        // Individnummeret koder århundret etter Skatteetatens regler (se BirthdateParser).
        let individ = year < 2000 ? Int.random(in: 0...499) : Int.random(in: 500...999)

        let storedMonth = month + 80             // syntetisk Tenor-nummer
        var digits = [
            day / 10, day % 10,
            storedMonth / 10, storedMonth % 10,
            yy / 10, yy % 10,
            individ / 100, (individ / 10) % 10, individ % 10,
        ]

        guard let k1 = controlDigit(digits, weights: [3, 7, 6, 1, 8, 9, 4, 5, 2]) else { return nil }
        digits.append(k1)
        guard let k2 = controlDigit(digits, weights: [5, 4, 3, 2, 7, 6, 5, 4, 3, 2]) else { return nil }
        digits.append(k2)

        return digits.map(String.init).joined()
    }

    /// Mod-11-kontrollsiffer. Returnerer `nil` hvis sifferet blir 10 (da er nummeret ugyldig
    /// og må forkastes), slik at kalleren kan prøve på nytt med andre siffer.
    private static func controlDigit(_ digits: [Int], weights: [Int]) -> Int? {
        let sum = zip(digits, weights).reduce(0) { $0 + $1.0 * $1.1 }
        let remainder = sum % 11
        let control = remainder == 0 ? 0 : 11 - remainder
        return control == 10 ? nil : control
    }
}
