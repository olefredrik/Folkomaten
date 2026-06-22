import Foundation

/// En BankID-testbruker lest fra en komma-separert linje:
/// `fødselsnummer,fullt navn,etternavn,fornavn`.
public struct TestUser: Identifiable, Hashable {
    public let fnr: String
    public let fullName: String
    public let lastName: String
    public let firstName: String

    public var id: String { fnr }

    /// Fødselsdato utledet fra fødselsnummeret.
    public var birthDate: Date? { BirthdateParser.birthDate(fromFnr: fnr) }

    /// Fødselsdato formatert som `dd.MM.yyyy`, eller «—» om den ikke kan utledes.
    public var birthDateFormatted: String {
        guard let date = birthDate else { return "—" }
        return TestUser.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.timeZone = TimeZone(identifier: "Europe/Oslo")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    public init(fnr: String, fullName: String, lastName: String, firstName: String) {
        self.fnr = fnr
        self.fullName = fullName
        self.lastName = lastName
        self.firstName = firstName
    }

    /// Parser én linje. Returnerer `nil` for tomme linjer eller linjer uten et gyldig
    /// 11-sifret fødselsnummer i første felt.
    public init?(line: String) {
        let parts = line
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count >= 4 else { return nil }

        let fnr = parts[0]
        guard fnr.count == 11, fnr.allSatisfy(\.isNumber) else { return nil }

        self.init(fnr: fnr, fullName: parts[1], lastName: parts[2], firstName: parts[3])
    }
}
