import Testing
import Foundation
@testable import FolkomatenKit

/// Fast referansedato (22.06.2026) så aldersutregningen er deterministisk.
private let referenceDate: Date = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Oslo") ?? .current
    return calendar.date(from: DateComponents(year: 2026, month: 6, day: 22))!
}()

/// D-nummer kjennes igjen på at dagen (de to første sifrene) er lagt til 40.
@Test func detectsDNumbers() {
    #expect(TestUserFilter.isDNumber("51887000763"))   // Åpen Biografi, dag 51 → 11
    #expect(TestUserFilter.isDNumber("59867600781"))   // Engasjert Vare, dag 59 → 19
    #expect(!TestUserFilter.isDNumber("07877999402"))  // Gåen Sandkasse, dag 07
    #expect(!TestUserFilter.isDNumber("05869797539"))  // Eventyrlig Kusine, dag 05
}

/// Alder utledes fra fødselsnummeret på referansedatoen.
@Test func computesAge() {
    #expect(TestUserFilter.age(of: "05869797539", on: referenceDate) == 29)  // 05.06.1997
    #expect(TestUserFilter.age(of: "01811550100", on: referenceDate) == 11)  // 01.01.2015 (konstruert mindreårig)
}

/// D-numre og mindreårige skal ikke kunne bestilles; ordinære myndige skal.
@Test func ordersOnlyAdultsWithOrdinaryFnr() {
    // Ordinært fødselsnummer, myndig → kan bestilles.
    #expect(TestUserFilter.isOrderable("05869797539", on: referenceDate))

    // D-nummer, men ellers myndig → avvises.
    #expect(!TestUserFilter.isOrderable("51887000763", on: referenceDate))

    // Mindreårig (født 2015) → avvises.
    #expect(!TestUserFilter.isOrderable("01811550100", on: referenceDate))
}

/// Ingen av de innebygde eksempelbrukerne er D-numre etter at lista er ryddet,
/// og alle er myndige.
@MainActor @Test func embeddedUsersAreAllOrderable() {
    for user in TestUserStore.embeddedUsers() {
        #expect(TestUserFilter.isOrderable(user.fnr, on: referenceDate),
                "\(user.fnr) (\(user.fullName)) skulle vært bestillbar")
    }
}
