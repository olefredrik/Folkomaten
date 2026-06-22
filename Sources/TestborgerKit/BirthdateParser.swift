import Foundation

/// Utleder fødselsdato fra et norsk fødselsnummer, inkludert de syntetiske
/// testnumrene fra BankID preprod / Skatteetatens Tenor.
///
/// Reglene som brukes:
/// - **Dag** (siffer 1–2): D-nummer legger 40 til dagen → trekk fra 40 hvis dag > 40.
/// - **Måned** (siffer 3–4): syntetiske testnummer legger 80 til måneden, H-nummer legger 40.
///   Trekk fra 80 hvis måned > 80, ellers 40 hvis måned > 40.
/// - **År/århundre**: utledes fra individnummer (siffer 7–9) etter Skatteetatens regler.
///   Tvetydige kombinasjoner (vanlige i syntetiske testnummer) faller tilbake til 1900-tallet,
///   noe som reproduserer fødselsdatoene i BankID preprod-uttrekkene.
public enum BirthdateParser {

    public static func birthDate(fromFnr fnr: String) -> Date? {
        let digits = Array(fnr.filter(\.isNumber))
        guard digits.count == 11 else { return nil }

        func number(_ range: Range<Int>) -> Int? { Int(String(digits[range])) }

        guard var day = number(0..<2),
              var month = number(2..<4),
              let yy = number(4..<6),
              let individ = number(6..<9) else { return nil }

        if day > 40 { day -= 40 }                 // D-nummer
        if month > 80 { month -= 80 }             // syntetisk (Tenor) testnummer
        else if month > 40 { month -= 40 }        // H-nummer

        guard (1...31).contains(day), (1...12).contains(month) else { return nil }

        let year: Int
        switch individ {
        case 0...499:                  year = 1900 + yy
        case 500...749 where yy >= 54: year = 1800 + yy
        case 500...999 where yy <= 39: year = 2000 + yy
        case 900...999 where yy >= 40: year = 1900 + yy
        default:                       year = 1900 + yy  // tvetydig testnummer → anta 1900-tallet
        }

        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo") ?? .current
        return calendar.date(from: components)
    }
}
