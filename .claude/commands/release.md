# /release — Tagg og publiser en ny versjon

Tagger en ny versjon av Folkomaten og pusher taggen. Release-workflowen
(`.github/workflows/release.yml`) bygger da `Folkomaten.app`, zipper den og
publiserer en GitHub Release automatisk.

**Versjonskilde:** Taggen styrer versjonen. `release.yml` sender `VERSION=<tag uten v>`
til `build-app.sh`, så `CFBundleShortVersionString` følger taggen. Den hardkodede
`VERSION` i `build-app.sh` er bare en fallback for lokale bygg og trenger ikke bumpes.

**Argument:** ønsket versjon uten «v», f.eks. `/release 1.1.0`. Utelatt → vurder bump-type
(patch/minor/major) ut fra endringene siden siste tag og foreslå ny versjon med begrunnelse.

## Steg

1. `git checkout main && git pull --ff-only` — vær på siste main.
2. Sjekk at arbeidstreet er rent (`git status --short`). Hvis ikke: stopp og rapporter.
3. Bestem versjon (semver):
   - **Med argument** (`/release 1.2.0`): bruk det direkte.
   - **Uten argument**: vurder bump-type ut fra endringene siden siste tag.
     - Hent siste tag: `git tag --sort=-v:refname | head -1`. Finnes ingen tag → foreslå `1.0.0` som første release.
     - Se på commitene siden da: `git log <siste-tag>..HEAD --oneline`.
     - Klassifiser etter Conventional Commits og velg høyeste som forekommer:
       - `feat!:`/`fix!:` eller `BREAKING CHANGE:` i body → **major**
       - minst én `feat:` → **minor**
       - ellers (`fix:`, `perf:`, `refactor:`, `docs:`, `chore:`, `ci:`, …) → **patch**
     - Foreslå ny versjon og **forklar kort hvilke commits som avgjorde** bump-typen. Be om bekreftelse.
   Valider at versjonen er gyldig semver `X.Y.Z`. Avbryt hvis taggen `vX.Y.Z` allerede finnes (`git rev-parse "vX.Y.Z"` lykkes).
4. Tagg og push:
   ```sh
   git tag vX.Y.Z && git push origin vX.Y.Z
   ```
   (Tag-push er eksplisitt bedt om ved å kjøre denne kommandoen, så det er greit å pushe taggen her — men aldri push til selve `main`.)
5. Følg opp og rapporter:
   - Kjøring: `gh run list --workflow=release.yml --limit 1` (evt. `gh run watch`).
   - Release: `gh release view "vX.Y.Z" --web`.
   - Si fra når releasen er publisert, og minn om at appen er ad-hoc-signert (Gatekeeper-advarsel ved nedlasting til notarisering evt. legges til).

**Husk:** ingen Claude-attribusjon i tagger, commit-meldinger eller releaser.
