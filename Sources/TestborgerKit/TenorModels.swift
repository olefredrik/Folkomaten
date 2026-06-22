import Foundation

// MARK: - API-responser

/// Svaret fra `/soek/{kilde}` – treff-metadata pluss dokumentene i `dokumentListe`.
struct TenorResultat: Decodable {
    let dokumentListe: [TenorPerson]?
}

struct TenorPerson: Decodable {
    let identifikasjonsnummer: [TenorIdentifikasjonsnummer]?
    let navn: [TenorNavn]?

    var gjeldendeFnr: String? {
        let liste = identifikasjonsnummer ?? []
        return (liste.first { $0.erGjeldende == true } ?? liste.first)?.foedselsEllerDNummer
    }

    var gjeldendeNavn: TenorNavn? {
        let liste = navn ?? []
        return liste.first { $0.erGjeldende == true } ?? liste.first
    }
}

struct TenorIdentifikasjonsnummer: Decodable {
    let foedselsEllerDNummer: String
    let erGjeldende: Bool?
}

struct TenorNavn: Decodable {
    let fornavn: String?
    let etternavn: String?
    let erGjeldende: Bool?
}

// MARK: - Mapping til TestUser

extension TestUser {
    init?(tenorPerson: TenorPerson) {
        guard let fnr = tenorPerson.gjeldendeFnr, let navn = tenorPerson.gjeldendeNavn else { return nil }
        let firstName = (navn.fornavn ?? "").capitalized
        let lastName  = (navn.etternavn ?? "").capitalized
        let fullName  = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        self.init(
            fnr: fnr,
            fullName: fullName.isEmpty ? fnr : fullName,
            lastName: lastName,
            firstName: firstName
        )
    }
}
