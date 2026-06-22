# Avansert bruk og utvikling

Det meste her trenger du ikke: appen kommer med innebygde testbrukere som virker
med en gang. Dette dokumentet er for deg som vil hente **dine egne** testbrukere
fra Tenor, eller bygge videre på koden.

## Hente egne testbrukere

Testbrukerne hentes fra Tenor, så de finnes i folkeregisteret (DSF) i test. Deretter bestiller
du dem i BankID preprod før de virker mot BankID:

1. Klikk **Hent fra Tenor…** og velg antall. Appen henter brukerne og lagrer dem som fil. Krever [oppsett](#oppsett-tilgang-til-tenor).
2. Klikk **Bestill…** (åpner <https://ra-preprod.bankidnorge.no/#!/bulk-order>) og last opp fila.
3. Trykk **Order** og vent til bestillingen er fullført.
4. Klikk **Bruk i appen…** og velg fila.

Appen henter kun ordinære fødselsnummer (ikke D-nummer), myndige og bosatte personer,
slik at alle kan bestilles. Den overhenter litt og trimmer ned, så du får antallet du ba om.

Brukerne virker mot BankID først når de er bestilt i portalen.

## Oppsett: tilgang til Tenor

For å hente fra Tenor må appen autentisere seg mot Skatteetatens søke-API via Maskinporten.
Dette gjør du én gang per maskin.

### 1. Be om tilgang

Send e-post til <Tenor@skatteetaten.no>. Oppgi organisasjonsnummer og be om tilgang til
scopet `skatteetaten:testnorge/testdata.read`.

### 2. Opprett en Maskinporten-klient

Logg inn i [selvbetjeningen for test](https://sjolvbetjening.test.samarbeid.digdir.no/)
og opprett en klient:

1. Legg til scopet `skatteetaten:testnorge/testdata.read`.
2. Sett access token-levetid, for eksempel 120 sekunder.
3. Legg til en nøkkel, og velg å få en generert nøkkel. Last ned privatnøkkelen (PEM).
4. Noter **Klient ID** og nøkkelens **kid**.

### 3. Legg inn nøkkel og Klient ID

Åpne **Hent fra Tenor… → Innstillinger…** og fyll inn:

1. **Klient ID** fra portalen.
2. **Nøkkel-ID (kid)** fra nøkkelen du la til.
3. **Privat nøkkel (PEM)** du lastet ned.
4. Klikk **Lagre**.

Legitimasjonen lagres i en fil under `~/Library/Application Support/Folkomaten/`
(kun lesbar for deg, rettigheter `0600`) og forlater aldri maskinen. Nå virker
**Hent fra Tenor…**.

## Filformat

Du kan laste inn egne filer i appen. Én testbruker per linje, komma-separert:

```
fødselsnummer,fullt navn,etternavn,fornavn
04869248709,Frode Aas,Aas,Frode
```

Appen leser både UTF-16 (slik BankID preprod lager filene) og UTF-8.
Fødselsnumrene er syntetiske og tilhører ingen virkelige personer.

## Hvordan fødselsdato utledes

Fra et 11-sifret fødselsnummer `DDMMÅÅiiikk`:

- **Dag** (1–2): D-nummer legger 40 til dagen, så det trekkes fra.
- **Måned** (3–4): syntetiske numre legger 80 til måneden, H-nummer legger 40, så det trekkes fra.
- **År** (5–6) og **århundre** fra individnummeret (7–9) etter Skatteetatens regler. Tvetydige syntetiske numre antas å være på 1900-tallet.

Se [`BirthdateParser`](../Sources/FolkomatenKit/BirthdateParser.swift) og [testene](../Tests/FolkomatenKitTests/BirthdateParserTests.swift).

## Teknisk

- Menylinje-UI med AppKit `NSStatusItem` + `NSPopover`, og en global hurtigtast (Carbon `RegisterEventHotKey`) som åpner et flytende panel når ikonet er skjult. SwiftUI for selve innholdet. macOS 13+.
- Swift Package med to mål: `FolkomatenKit` (logikk og data, testbar) og `Folkomaten` (appen). Bygges fra kommandolinjen, uten Xcode-prosjektfil.
- For utvikling: `swift run` kjører appen, `swift test` kjører testene.
