import Foundation

// MARK: - API-responser

struct TenorPerson: Decodable {
    let identifikasjonsnummer: [TenorIdentifikasjonsnummer]
    let navn: [TenorNavn]

    var gjeldendeFnr: String? {
        identifikasjonsnummer.first { $0.erGjeldende }?.foedselsEllerDNummer
    }

    var gjeldendeNavn: TenorNavn? {
        navn.first { $0.erGjeldende }
    }
}

struct TenorIdentifikasjonsnummer: Decodable {
    let foedselsEllerDNummer: String
    let erGjeldende: Bool
}

struct TenorNavn: Decodable {
    let fornavn: String
    let etternavn: String
    let erGjeldende: Bool
}

// MARK: - Mapping til TestUser

extension TestUser {
    init?(tenorPerson: TenorPerson) {
        guard let fnr = tenorPerson.gjeldendeFnr,
              let navn = tenorPerson.gjeldendeNavn else { return nil }
        let firstName = navn.fornavn.capitalized
        let lastName  = navn.etternavn.capitalized
        self.init(
            fnr: fnr,
            fullName: "\(firstName) \(lastName)",
            lastName: lastName,
            firstName: firstName
        )
    }
}
