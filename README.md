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
- ✨ **Generer fil**: lag en fil med syntetiske testbrukere du kan laste opp i BankID preprod
  for å bestille dem (se [Bestille nye testbrukere](#bestille-nye-testbrukere)).
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

## Bestille nye testbrukere

For at testbrukerne skal virke mot BankID må de bestilles i BankID preprod sin bulk-order-portal:

1. Lag en fil i formatet over. Klikk **Generer…** i appen for å lage en med gyldige
   syntetiske fødselsnummer og tilfeldige navn.
2. Klikk **Bestill…** i appen (åpner <https://ra-preprod.bankidnorge.no/#!/bulk-order>)
   og last opp fila.
3. Trykk **Order** og vent til bestillingen er fullført.
4. Ta fila i bruk i appen med **Bruk i appen…**.

Generer-knappen lager bare fila. Brukerne fungerer først etter at de er bestilt i portalen.

## Innlogging i BankID preprod

Alle testbrukerne deler samme legitimasjon når du logger inn i BankID preprod:

- **Engangskode (OTP):** `otp`
- **Passord:** `qwer1234`

Se [BankIDs dokumentasjon](https://developer.bankid.no/bankid-with-biometrics/testing/#get-access-to-the-bankid-preprod-app)
for mer om tilgang til preprod-appen.

## Installasjon

Krever Swift 5.9+ (Command Line Tools holder).

```sh
git clone https://github.com/olefredrik/testborger.git
cd testborger
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
