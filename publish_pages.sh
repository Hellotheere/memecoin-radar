#!/usr/bin/env bash
# Publiserer Memecoin-radar (statisk enkeltfil) til GitHub Pages.
# Ingen hemmeligheter i repoet eller i dette skriptet: git bruker gh sin innlogging via credential-helper (gh auth setup-git).
#
#   ./publish_pages.sh                 kopier ny index.html fra radaren; commit + push hvis innholdet er endret.
#                                      Uten gh-innlogging eller uten remote: oppdaterer bare lokalt og avslutter med 0 (stille no-op).
#   ./publish_pages.sh --setup [NAVN]  første gang (krever `gh auth login`): lager OFFENTLIG repo NAVN (standard memecoin-radar),
#                                      pusher og slår på GitHub Pages (main, /). Skriver ut den faste adressen.
#   ./publish_pages.sh --status        viser innlogging, remote og Pages-adresse.
#
# Historikk: hver publisering erstatter én enkelt commit (amend + force-with-lease), så repoet ikke vokser med ~370 kB
# for hver dataendring (vakten oppdaterer hvert 10. min). Kalles automatisk fra /workspace/memecoin-site/deploy.sh,
# som add_alert.py og build2.py --deploy kjører etter hver endring.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="${RADAR_SRC:-/workspace/memecoin-site/index.html}"
MODE="${1:-publish}"
exec 9>/tmp/radar-pages.lock
flock -w 60 9 || { echo "publish_pages: låst, hopper over"; exit 0; }
cd "$DIR"
have_auth() { command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; }
has_remote() { git remote get-url origin >/dev/null 2>&1; }

copy_page() {
  [ -s "$SRC" ] || { echo "publish_pages: fant ikke $SRC" >&2; exit 1; }
  local tmp; tmp="$(mktemp "$DIR/.index.XXXXXX")"
  cp "$SRC" "$tmp"
  # sanity: må være radaren med innebygde data, og ikke for liten
  if ! grep -q 'id="alerts-data"' "$tmp" || [ "$(wc -c <"$tmp")" -lt 50000 ]; then rm -f "$tmp"; echo "publish_pages: $SRC ser ikke ut som radaren – avbryter" >&2; exit 1; fi
  # vakt mot lekkasje: stopp hvis siden inneholder noe som ligner nøkler/tokens eller lokale stier
  if grep -Eq '(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|xox[abpr]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|/home/box/|ngrok-free\.(app|dev))' "$tmp"; then
    rm -f "$tmp"; echo "publish_pages: mulig hemmelighet/lokal sti i siden – publiserer IKKE" >&2; exit 1; fi
  chmod 644 "$tmp"; mv -f "$tmp" "$DIR/index.html"
}

commit_local() {
  git add index.html .nojekyll README.md publish_pages.sh .gitignore
  if git rev-parse -q --verify HEAD >/dev/null; then
    git diff --cached --quiet && return 1
    git commit -q --amend --no-edit --date=now -m "Memecoin-radar $(date -u +%Y-%m-%dT%H:%MZ)"
  else
    git commit -q -m "Memecoin-radar $(date -u +%Y-%m-%dT%H:%MZ)"
  fi
  return 0
}

case "$MODE" in
  --status)
    if have_auth; then echo "gh: innlogget som $(gh api user -q .login 2>/dev/null || echo '?')"; else echo "gh: IKKE innlogget (kjør: gh auth login)"; fi
    if has_remote; then echo "remote: $(git remote get-url origin)"; else echo "remote: ingen (kjør: ./publish_pages.sh --setup)"; fi
    if has_remote && have_auth; then gh api "repos/{owner}/{repo}/pages" -q .html_url 2>/dev/null || echo "Pages: ikke aktivert"; fi
    exit 0 ;;
  --setup)
    have_auth || { echo "Ikke innlogget i GitHub på boksen. Kjør først: gh auth login   (velg GitHub.com, HTTPS, logg inn i nettleser)"; exit 2; }
    NAME="${2:-memecoin-radar}"
    gh auth setup-git
    copy_page; commit_local || true
    OWNER="$(gh api user -q .login)"
    if ! has_remote; then gh repo create "$NAME" --public --description "Memecoin-radar – statisk side (kun research, ikke finansielle råd)" --source "$DIR" --remote origin; fi
    git push -q -u --force-with-lease origin main
    gh api -X POST "repos/$OWNER/$NAME/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
      || gh api -X PUT "repos/$OWNER/$NAME/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || true
    echo "Ferdig. Fast adresse (klar etter 1–2 min): https://$OWNER.github.io/$NAME/"
    exit 0 ;;
  publish|--quiet)
    copy_page
    if ! commit_local; then [ "$MODE" = --quiet ] || echo "publish_pages: uendret"; exit 0; fi
    if has_remote && have_auth; then
      git push -q --force-with-lease origin main && { [ "$MODE" = --quiet ] || echo "publish_pages: publisert"; }
    else
      [ "$MODE" = --quiet ] || echo "publish_pages: oppdatert lokalt (ikke publisert: $(have_auth && echo 'mangler remote – kjør --setup' || echo 'gh ikke innlogget'))"
    fi
    exit 0 ;;
  *) echo "Ukjent valg: $MODE (bruk --setup, --status eller ingenting)"; exit 2 ;;
esac
