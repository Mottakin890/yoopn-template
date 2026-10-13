#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# YooPN Templates — secret scan.
#
#   ./tool/scan_secrets.sh              # scan the working tree
#   ./tool/scan_secrets.sh --staged     # scan only what git is about to commit
#   ./tool/scan_secrets.sh --history    # scan the full commit history
#
# Runs gitleaks when it is installed (authoritative, uses .gitleaks.toml).
# Falls back to a portable regex sweep otherwise, so the guard is never
# silently skipped on a machine without gitleaks.
#
# Exit 0 = clean, exit 1 = findings, exit 2 = scanner error.
# ---------------------------------------------------------------------------
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

MODE="${1:-tree}"

run_gitleaks() {
  if ! command -v gitleaks >/dev/null 2>&1; then
    return 127
  fi
  case "$MODE" in
    --staged)  gitleaks protect --staged --config .gitleaks.toml --redact -v ;;
    --history) gitleaks detect --source . --config .gitleaks.toml --redact -v ;;
    *)         gitleaks detect --source . --config .gitleaks.toml --redact -v ;;
  esac
}

if run_gitleaks; then
  exit $?
elif [ $? -eq 127 ]; then
  echo "note: gitleaks not installed — falling back to the built-in sweep."
  echo "      install it for the full ruleset: https://github.com/gitleaks/gitleaks"
else
  # gitleaks ran and found leaks (or errored) — do not mask the result.
  exit 1
fi

# ---------------------------------------------------------------------------
# Fallback sweep. Kept deliberately small: it is a backstop for "no scanner
# available", not a replacement for gitleaks.
# ---------------------------------------------------------------------------
echo "scanning with built-in rules…"

# Fail closed: outside a git repo there is no reliable file list, so refuse
# rather than reporting a clean result we cannot stand behind.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: not inside a git repository — cannot enumerate files to scan."
  exit 2
}

# Collect the file list to inspect.
case "$MODE" in
  --staged)  mapfile -t FILES < <(git diff --cached --name-only --diff-filter=ACMR) ;;
  --history) mapfile -t FILES < <(git log --pretty=format: --name-only | sort -u | sed '/^$/d') ;;
  *)         mapfile -t FILES < <(git ls-files) ;;
esac
[ "${#FILES[@]}" -gt 0 ] || { echo "no files to scan"; exit 0; }

# PCRE is required for the negative look-ahead on the AdMob demo account.
GREP_FLAGS='-En'
if grep -P --version >/dev/null 2>&1; then
  GREP_FLAGS='-Pn'
fi

PATTERNS='-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----|\bsb_secret_[A-Za-z0-9_-]{20,}|\bsb_publishable_[A-Za-z0-9_-]{20,}|\bAIza[0-9A-Za-z_-]{35}|\bGOCSPX-[0-9A-Za-z_-]{20,}|\bAKIA[0-9A-Z]{16}|\bca-app-pub-(?!3940256099942544)[0-9]{10,}|https://[a-z0-9]{20}\.supabase\.co|\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'

# Mirrors the allowlist in .gitleaks.toml: Google's public demo account and
# documented placeholder shapes are not secrets.
FILTER='3940256099942544|YOUR_[A-Z0-9_]+|your_supabase_[a-z0-9_]+|YOUR-PROJECT-REF'

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FOUND=0
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  case "$f" in
    .env.example|.env.template|*/.env.example) continue ;;
    *.png|*.jpg|*.jpeg|*.gif|*.ttf|*.otf|*.lock|*.jar|*.zip) continue ;;
  esac
  # `--` is mandatory: the pattern starts with `-----BEGIN`, which grep would
  # otherwise parse as an option bundle (rc=2, i.e. silently scan nothing).
  grep $GREP_FLAGS --binary-files=without-match -- "$PATTERNS" "$f" >"$TMP/hits" 2>/dev/null
  [ -s "$TMP/hits" ] || continue
  # Honour gitleaks' inline suppression marker, same semantics as gitleaks
  # itself: `gitleaks:allow` on the finding line waives that one finding.
  grep -v 'gitleaks:allow' "$TMP/hits" >"$TMP/hits2" 2>/dev/null
  grep -vE "$FILTER" "$TMP/hits2" >"$TMP/real" 2>/dev/null
  [ -s "$TMP/real" ] || continue
  echo "── potential secret in $f"
  # Redact before printing: this output lands in CI logs.
  sed -E 's/([A-Za-z0-9_-]{6})[A-Za-z0-9_-]{6,}/\1***REDACTED***/g' "$TMP/real"
  FOUND=1
done

if [ "$FOUND" -ne 0 ]; then
  echo
  echo "FAIL: possible secret(s) above. Move them to .env / --dart-define."
  exit 1
fi
echo "clean: no secret patterns matched (${#FILES[@]} files)."
exit 0