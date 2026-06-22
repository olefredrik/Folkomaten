# Folkomaten

En macOS menylinje-app som enkelt lar deg kopiere fødselsnummeret til en BankID-testbruker. De samme brukerne finnes også i Det Sentrale Folkeregisteret (DSF) sin database over gyldige testbrukere. Dette gjør Folkomaten til et nyttig verktøy når du bare trenger en testbruker kjapt, uten å måtte grave i sidesystemer eller lokale tekstfiler.

## Funksjoner

- 50 syntetiske eksempelbrukere er innebygd, så appen virker med en gang.
- **Kopier fødselsnummer** med ett klikk
- **Global hurtigtast**: åpne appen med `⌃⌥⌘F` uansett hvilken app du er i – også når menylinje-ikonet er skjult bak notch-en på en full menylinje. Snarveien kan endres i innstillingene.
- **Favoritter**: marker brukerne du bruker ofte, og filtrer på dem.
- **Fødselsdato** utledes fra fødselsnummeret (syntetiske Tenor-numre).
- **Søk** på navn eller fødselsnummer.
- **Hent nye testbrukere fra Tenor**: hent dine egne syntetiske testpersoner som finnes i folkeregisteret i test (se [Avansert bruk](docs/AVANSERT.md#hente-egne-testbrukere)).
- **Last inn egne filer**: leser både UTF-16 og UTF-8. Sist brukte fil huskes til neste oppstart (se [filformat](docs/AVANSERT.md#filformat)).
- **Start ved innlogging**: la appen starte automatisk når du logger inn.
- **Tøm liste**: start tomt. Valget huskes, og du henter de innebygde tilbake med **Last inn eksempelbrukere**.

## Installasjon

Krever Swift 5.9+ (Command Line Tools holder).

```sh
git clone https://github.com/olefredrik/Folkomaten.git
cd Folkomaten
./Scripts/build-app.sh    # lager Folkomaten.app
open Folkomaten.app
```

Appen lever i menylinjen (ingen Dock-ikon). Trykk `⌃⌥⌘F` eller klikk menylinje-ikonet for å åpne den.

## Innlogging i BankID preprod

Alle testbrukerne deler samme innlogging:

- **Engangskode (OTP):** `otp`
- **Passord:** `qwer1234`

Se [BankIDs dokumentasjon](https://developer.bankid.no/bankid-with-biometrics/testing/#get-access-to-the-bankid-preprod-app)
for tilgang til preprod-appen.

## Avansert bruk og utvikling

Vil du hente **dine egne** testbrukere fra Tenor, lese om filformatet, se hvordan
fødselsdato utledes, eller bygge videre på koden? Se **[docs/AVANSERT.md](docs/AVANSERT.md)**.

## Lisens

[MIT](LICENSE).

> «BankID» er et varemerke og brukes her kun beskrivende. Dette er et uavhengig verktøy uten tilknytning til BankID.
