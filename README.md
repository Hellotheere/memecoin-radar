# Memecoin-radar – fast adresse på GitHub Pages

Statisk enkeltfil (`index.html`) med innebygd data. Kun research – ikke finansielle råd, ingen handel.

## Status nå
Alt er klart lokalt i `/workspace/radar-pages/` (git-repo på `main`, `index.html`, `.nojekyll`, `publish_pages.sh`).
Det som mangler er én GitHub-innlogging på boksen – den kan bare eieren gjøre.

## Det eieren må gjøre (én gang, ca. 3 min)
1. Ha en GitHub-konto (gratis): https://github.com/signup
2. Logg inn på boksen (åpne terminal/skrivebordet til boksen, eller be Grok kjøre kommandoen og fullfør i nettleseren):
   ```
   gh auth login --hostname github.com --git-protocol https --web
   ```
   Skriv inn engangskoden på https://github.com/login/device og godkjenn.
3. Opprett repo og slå på Pages:
   ```
   /workspace/radar-pages/publish_pages.sh --setup memecoin-radar
   ```
   Fast adresse blir: `https://<ditt-github-navn>.github.io/memecoin-radar/`

## Slik holdes kopien oppdatert
- `add_alert.py` kjører `/workspace/memecoin-site/deploy.sh` etter hver endring (vakten, hvert 10. min), og
  `build2.py --deploy` gjør det samme. `deploy.sh` kaller `publish_pages.sh --quiet`.
- `publish_pages.sh` kopierer `/workspace/memecoin-site/index.html`, og pusher bare hvis innholdet er endret.
  Uten innlogging/remote er det en stille no-op (exit 0), så vakten påvirkes ikke.
- Én commit erstattes hver gang (amend + `--force-with-lease`) så repoet ikke vokser.
- GitHub Pages bufrer i ca. 10 min; siden laster selv inn nye data hvert 2. min.

## Ingen hemmeligheter
- Ingen token lagres i repoet eller skriptet; git bruker `gh` sin innlogging (credential-helper, `gh auth setup-git`).
- Skriptet nekter å publisere hvis siden inneholder noe som ligner nøkler/tokens, private nøkler, `/home/box/` eller ngrok-adresser.
- Siden er offentlig (som ngrok-adressen i dag): varsler, følgeliste og Elon/Trump-feed er synlige for alle med lenken.

## Merk
- Følgeliste-kopiering, Sjekk og live-kurser fungerer likt (offentlige API-er fra nettleseren).
- ngrok-adressen og appen på 127.0.0.1:8712 fortsetter som før.
