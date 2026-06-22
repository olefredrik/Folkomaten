# Testborger

En liten **macOS menylinje-app** for å kopiere fødselsnummeret til testbrukere fra preprod- og testmiljøet til BankID.
Du får testbrukerne rett i menylinjen og slipper å lete i en tekstfil på skrivebordet.

## Funksjoner

- 📋 **Ett klikk kopierer fødselsnummeret** til utklippstavlen (klikk raden eller kopier-ikonet).
- ⭐ **Favoritter**: marker testbrukerne du bruker ofte, og filtrer på dem.
- 🎂 **Fødselsdato** utledes automatisk fra fødselsnummeret (håndterer syntetiske Tenor-numre,
  D-nummer og århundre fra individnummer).
- 🔎 **Søk** på navn eller fødselsnummer.
- 📂 **Last inn egne filer**: leser både UTF-16 (slik BankID preprod genererer dem) og UTF-8.
  Appen husker sist brukte fil til neste oppstart.
- 🔗 **Hent fra Tenor**: hent ekte syntetiske testpersoner fra Tenor testdatasøk, slik at de
  finnes i folkeregisteret i test (se [Hente nye testbrukere](#hente-nye-testbrukere)).
- 🚀 **Start ved innlogging**: huk av for at appen skal starte automatisk når du logger inn.
- 🧹 **Tøm liste**: start friskt med egne testbrukere. Valget huskes til neste oppstart, og du
  kan når som helst hente de innebygde tilbake med **Last inn eksempelbrukere**.
- 50 syntetiske eksempelbrukere er innebygd, så appen virker rett ut av boksen.

## Filformat

Én testbruker per linje, komma-separert:

```
fødselsnummer,fullt navn,etternavn,fornavn
04869248709,Frode Aas,Aas,Frode
```

Fødselsnumrene er **syntetiske** testnumre fra Tenor og tilhører ingen virkelige personer.

## Hente nye testbrukere

Testbrukerne hentes fra Tenor, slik at de finnes i folkeregisteret i test. Deretter
bestilles de i BankID preprod sin bulk-order-portal før de virker mot BankID:

1. Klikk **Hent fra Tenor…** i appen og velg antall. Appen henter testpersoner og lagrer
   dem som en fil i formatet over. (Krever oppsett, se [Oppsett: tilgang til Tenor](#oppsett-tilgang-til-tenor).)
2. Klikk **Bestill…** i appen (åpner <https://ra-preprod.bankidnorge.no/#!/bulk-order>)
   og last opp fila.
3. Trykk **Order** og vent til bestillingen er fullført.
4. Ta fila i bruk i appen med **Bruk i appen…**.

Brukerne fungerer mot BankID først etter at de er bestilt i portalen.

## Oppsett: tilgang til Tenor

For å hente testbrukere fra Tenor må appen autentisere seg mot Skatteetatens søke-API via
Maskinporten. Dette settes opp én gang per maskin.

### 1. Be om tilgang til scopet

Send en e-post til <Tenor@skatteetaten.no> med organisasjonsnummeret deres og be om tilgang
til scopet `skatteetaten:testnorge/testdata.read`.

### 2. Opprett en Maskinporten-klient

Logg inn i [Samarbeidsportalen](https://sjolvbetjening.samarbeid.digdir.no/) (Digdirs
selvbetjening for Maskinporten) og opprett en ny klient i **ver2 (test)**-miljøet:

1. Legg til scopet `skatteetaten:testnorge/testdata.read`.
2. Sett access token-levetid (f.eks. 120 sekunder).
3. Lagre klienten og noter **Client ID**.

### 3. Legg inn nøkkel og Client ID i appen

Åpne **Hent fra Tenor… → Innstillinger…** i appen:

1. Klikk **Generer og kopier JWK**. Appen lager et ES256-nøkkelpar, fyller inn den private
   nøkkelen og kopierer den offentlige nøkkelen (JWK) til utklippstavlen.
2. Lim inn JWK-en som en nøkkel på klienten i Samarbeidsportalen.
3. Lim inn **Client ID** i appen og klikk **Lagre**.

Den private nøkkelen lagres trygt i macOS-nøkkelringen og forlater aldri maskinen din.
Når dette er gjort, virker **Hent fra Tenor…**.

## Innlogging i BankID preprod

Alle testbrukerne deler samme legitimasjon når du logger inn i BankID preprod:

- **Engangskode (OTP):** `otp`
- **Passord:** `qwer1234`

Se [BankIDs dokumentasjon](https://developer.bankid.no/bankid-with-biometrics/testing/#get-access-to-the-bankid-preprod-app)
for mer om tilgang til preprod-appen.

## Installasjon

Krever Swift 5.9+ (Command Line Tools holder).

```sh
cd Testborger
./Scripts/build-app.sh          # lager Testborger.app
open Testborger.app
```

For utvikling: `swift run` (kjører appen direkte) og `swift test` (kjører testene).

Vil du ha appen ved oppstart, huk av **Start ved innlogging** i appen.

## Hvordan fødselsdato utledes

Fra et 11-sifret fødselsnummer `DDMMÅÅiiik k`:

- **Dag** (1–2): D-nummer legger 40 til dagen → trekkes fra.
- **Måned** (3–4): syntetiske testnumre legger 80 til måneden, H-nummer legger 40 → trekkes fra.
- **År** (5–6) + **århundre** fra individnummeret (7–9) etter Skatteetatens regler.
  Tvetydige kombinasjoner i syntetiske testnumre antas å være på 1900-tallet.

Se [`BirthdateParser`](Sources/TestborgerKit/BirthdateParser.swift) og testene i
[`Tests/`](Tests/TestborgerKitTests/BirthdateParserTests.swift).

## Teknisk

- SwiftUI `MenuBarExtra`, macOS 13+.
- Swift Package med to mål: `TestborgerKit` (logikk + data, fullt testbar) og `Testborger`
  (menylinje-appen). Alt bygges fra kommandolinjen, uten Xcode-prosjektfil.

## Lisens

[MIT](LICENSE).

> «BankID» er et varemerke og brukes her kun beskrivende. Dette er et uavhengig
> verktøy uten tilknytning til BankID.
