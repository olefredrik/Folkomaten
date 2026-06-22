import Testing
import Foundation
@testable import TestborgerKit

/// Validerer et fødselsnummer ved å regne ut mod-11-kontrollsifrene på nytt.
private func hasValidControlDigits(_ fnr: String) -> Bool {
    let d = fnr.compactMap { $0.wholeNumberValue }
    guard d.count == 11 else { return false }

    func control(_ digits: ArraySlice<Int>, _ weights: [Int]) -> Int? {
        let sum = zip(digits, weights).reduce(0) { $0 + $1.0 * $1.1 }
        let rem = sum % 11
        let c = rem == 0 ? 0 : 11 - rem
        return c == 10 ? nil : c
    }

    guard let k1 = control(d[0..<9], [3, 7, 6, 1, 8, 9, 4, 5, 2]), k1 == d[9],
          let k2 = control(d[0..<10], [5, 4, 3, 2, 7, 6, 5, 4, 3, 2]), k2 == d[10]
    else { return false }
    return true
}

@Test func generatesRequestedCount() {
    #expect(TestUserGenerator.generate(count: 0).isEmpty)
    #expect(TestUserGenerator.generate(count: 37).count == 37)
}

@Test func generatedNumbersAreValidAndParseable() {
    let users = TestUserGenerator.generate(count: 200)
    for user in users {
        let allDigits = user.fnr.allSatisfy(\.isNumber)
        #expect(user.fnr.count == 11)
        #expect(allDigits)
        #expect(hasValidControlDigits(user.fnr), "Ugyldig kontrollsiffer: \(user.fnr)")
        #expect(user.birthDate != nil, "Fødselsdato kunne ikke utledes: \(user.fnr)")
    }
}

@Test func generatedNumbersAreUnique() {
    let users = TestUserGenerator.generate(count: 300)
    #expect(Set(users.map(\.fnr)).count == users.count)
}

@Test func fileDataRoundTrips() {
    let users = TestUserGenerator.generate(count: 25)
    let data = TestUserGenerator.fileData(for: users)

    // UTF-16 BOM (little-endian: FF FE) først.
    #expect(data.prefix(2) == Data([0xFF, 0xFE]))

    let text = String(data: data, encoding: .utf16)!
    let parsed = text.split(whereSeparator: \.isNewline).compactMap { TestUser(line: String($0)) }

    #expect(parsed.count == users.count)
    #expect(parsed.map(\.fnr) == users.map(\.fnr))
    #expect(parsed.first?.fullName == users.first?.fullName)
}
