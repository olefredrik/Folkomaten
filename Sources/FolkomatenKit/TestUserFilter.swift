import Foundation

/// Avgjør om en testperson kan bestilles som en aktiv BankID-testbruker.
///
/// Filteret utledes fra fødselsnummeret alene (ingen nettverkskall), slik at det
/// er deterministisk og kan enhetstestes:
/// - **D-nummer** (midlertidig ID, dag + 40) avvises – mange testsystemer tar kun
///   imot ordinære fødselsnummer.
/// - **Mindreårige** (under `minimumAge` år) avvises.
///
/// Døde/ikke-bosatte holdes ute server-side i `TenorClient` via KQL
/// (`personstatus:bosatt`).
public enum TestUserFilter {

    /// Kalenderen som brukes til datoutregning – samme som `BirthdateParser`.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo") ?? .current
        return calendar
    }()

    /// Sant når fødselsnummeret er et D-nummer (de to første sifrene, dagen, er
    /// lagt til 40).
    public static func isDNumber(_ fnr: String) -> Bool {
        let digits = Array(fnr.filter(\.isNumber))
        guard digits.count == 11, let day = Int(String(digits[0..<2])) else { return false }
        return day > 40
    }

    /// Alder i hele år på `referenceDate`, utledet fra fødselsnummeret, eller `nil`
    /// hvis datoen ikke kan utledes.
    public static func age(of fnr: String, on referenceDate: Date) -> Int? {
        guard let birthDate = BirthdateParser.birthDate(fromFnr: fnr) else { return nil }
        return calendar.dateComponents([.year], from: birthDate, to: referenceDate).year
    }

    /// Sant når brukeren kan bestilles: ordinært fødselsnummer (ikke D-nummer) og
    /// myndig (minst `minimumAge` år) på `referenceDate`.
    public static func isOrderable(_ fnr: String, on referenceDate: Date, minimumAge: Int = 18) -> Bool {
        guard !isDNumber(fnr) else { return false }
        guard let age = age(of: fnr, on: referenceDate), age >= minimumAge else { return false }
        return true
    }
}
