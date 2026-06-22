import Foundation

// MARK: - API-responser

/// Svaret fra `/soek/{kilde}` – treff-metadata pluss dokumentene i `dokumentListe`.
struct TenorResultat: Decodable {
    let dokumentListe: [TenorPerson]?
}

/// Et freg-dokument slik det kommer når vi ber om `vis=fornavn,etternavn,id`.
/// Feltene ligger flatt på dokumentet, ikke i nøstede lister.
struct TenorPerson: Decodable {
    let id: String?
    let fornavn: String?
    let etternavn: String?
}

// MARK: - Mapping til TestUser

extension TestUser {
    init?(tenorPerson: TenorPerson) {
        guard let fnr = tenorPerson.id, !fnr.isEmpty else { return nil }
        let firstName = (tenorPerson.fornavn ?? "").capitalized
        let lastName  = (tenorPerson.etternavn ?? "").capitalized
        let fullName  = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        self.init(
            fnr: fnr,
            fullName: fullName.isEmpty ? fnr : fullName,
            lastName: lastName,
            firstName: firstName
        )
    }
}
