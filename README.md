# Folkomaten

En macOS menylinje-app for å kopiere fødselsnummeret til BankID-testbrukere. Du får
testbrukerne rett i menylinjen og slipper å lete i en tekstfil.

## Funksjoner

- **Kopier fødselsnummer** med ett klikk (klikk raden eller kopier-ikonet).
- **Favoritter**: marker brukerne du bruker ofte, og filtrer på dem.
- **Fødselsdato** utledes fra fødselsnummeret (syntetiske Tenor-numre, D-nummer og århundre fra individnummer).
- **Søk** på navn eller fødselsnummer.
- **Last inn egne filer**: leser både UTF-16 (slik BankID preprod lager dem) og UTF-8. Sist brukte fil huskes til neste oppstart.
- **Hent fra Tenor**: hent syntetiske testpersoner som finnes i folkeregisteret i test (se [Hente testbrukere](#hente-testbrukere)).
- **Start ved innlogging**: la appen starte automatisk når du logger inn.
- **Tøm liste**: start tomt. Valget huskes, og du henter de innebygde tilbake med **Last inn eksempelbrukere**.
- 50 syntetiske eksempelbrukere er innebygd, så appen virker med en gang.

## Filformat

Én testbruker per linje, komma-separert:

```
fødselsnummer,fullt navn,etternavn,fornavn
04869248709,Frode Aas,Aas,Frode
```

Fødselsnumrene er syntetiske og tilhører ingen virkelige personer.

## Hente testbrukere

Testbrukerne hentes fra Tenor, så de finnes i folkeregisteret i test. Deretter bestiller
du dem i BankID preprod før de virker mot BankID:

1. Klikk **Hent fra Tenor…** og velg antall. Appen henter brukerne og lagrer dem som fil. Krever [oppsett](#oppsett-tilgang-til-tenor).
2. Klikk **Bestill…** (åpner <https://ra-preprod.bankidnorge.no/#!/bulk-order>) og last opp fila.
3. Trykk **Order** og vent til bestillingen er fullført.
4. Klikk **Bruk i appen…** og velg fila.

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

Den private nøkkelen lagres i macOS-nøkkelringen og forlater aldri maskinen. Nå virker
**Hent fra Tenor…**.

## Innlogging i BankID preprod

Alle testbrukerne deler samme innlogging:

- **Engangskode (OTP):** `otp`
- **Passord:** `qwer1234`

Se [BankIDs dokumentasjon](https://developer.bankid.no/bankid-with-biometrics/testing/#get-access-to-the-bankid-preprod-app)
for tilgang til preprod-appen.

## Installasjon

Krever Swift 5.9+ (Command Line Tools holder).

```sh
cd Folkomaten
./Scripts/build-app.sh    # lager Folkomaten.app
open Folkomaten.app
```

For utvikling: `swift run` kjører appen, `swift test` kjører testene.

## Hvordan fødselsdato utledes

Fra et 11-sifret fødselsnummer `DDMMÅÅiiikk`:

- **Dag** (1–2): D-nummer legger 40 til dagen, så det trekkes fra.
- **Måned** (3–4): syntetiske numre legger 80 til måneden, H-nummer legger 40, så det trekkes fra.
- **År** (5–6) og **århundre** fra individnummeret (7–9) etter Skatteetatens regler. Tvetydige syntetiske numre antas å være på 1900-tallet.

Se [`BirthdateParser`](Sources/FolkomatenKit/BirthdateParser.swift) og [testene](Tests/FolkomatenKitTests/BirthdateParserTests.swift).

## Teknisk

- SwiftUI `MenuBarExtra`, macOS 13+.
- Swift Package med to mål: `FolkomatenKit` (logikk og data, testbar) og `Folkomaten` (appen). Bygges fra kommandolinjen, uten Xcode-prosjektfil.

## Lisens

[MIT](LICENSE).

> «BankID» er et varemerke og brukes her kun beskrivende. Dette er et uavhengig verktøy uten tilknytning til BankID.
