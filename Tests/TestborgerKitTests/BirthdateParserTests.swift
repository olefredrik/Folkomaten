import Testing
import Foundation
@testable import TestborgerKit

private func formatted(_ fnr: String) -> String? {
    guard let date = BirthdateParser.birthDate(fromFnr: fnr) else { return nil }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "nb_NO")
    formatter.timeZone = TimeZone(identifier: "Europe/Oslo")
    formatter.dateFormat = "dd.MM.yyyy"
    return formatter.string(from: date)
}

/// Verifisert mot skjermbildet i oppgaven (syntetiske Tenor-numre, måned + 80).
@Test func verifiedScreenshotNumbers() {
    #expect(formatted("21906977751") == "21.10.1969")  // individnummer 777 → 1900-talls fallback
    #expect(formatted("08925498190") == "08.12.1954")
    #expect(formatted("25898999575") == "25.09.1989")
    #expect(formatted("31810849196") == "31.01.1908")
    #expect(formatted("21836499880") == "21.03.1964")
}

/// En av de innebygde eksempelbrukerne.
@Test func embeddedSampleUser() {
    #expect(formatted("04869248709") == "04.06.1992")  // Frode Aas
}

/// D-nummer: 40 lagt til dagen.
@Test func dNumber() {
    #expect(formatted("41059912345") == "01.05.1999")
}

/// Individnummer 500–999 med år 00–39 → 2000-tallet.
@Test func year2000s() {
    #expect(formatted("01010550112") == "01.01.2005")
}

/// Ugyldig input gir nil.
@Test func invalidInput() {
    #expect(BirthdateParser.birthDate(fromFnr: "123") == nil)
    #expect(BirthdateParser.birthDate(fromFnr: "abcdefghijk") == nil)
    #expect(BirthdateParser.birthDate(fromFnr: "") == nil)
}

/// Alle innebygde testbrukere skal kunne parses og gi en gyldig fødselsdato.
@MainActor @Test func allEmbeddedUsersParse() {
    let users = TestUserStore.embeddedUsers()
    #expect(users.count == 50)
    for user in users {
        #expect(user.birthDate != nil, "Mangler fødselsdato for \(user.fnr) (\(user.fullName))")
    }
}
