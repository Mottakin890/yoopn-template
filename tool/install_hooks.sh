#!/usr/bin/env bash
# Wire this repo's .githooks/ into git and create a local .env from the example.
# Safe to re-run.
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1
ROOT="$(pwd)"

chmod +x .githooks/* tool/*.sh supabase/probe.sh 2>/dev/null || true

git config core.hooksPath .githooks
echo "hooks installed  -> core.hooksPath = .githooks"

if [ ! -f .env ]; then
  cp .env.example .env
  echo ".env created     -> fill in SUPABASE_URL / SUPABASE_ANON_KEY (or leave the placeholders, the app fails fast with a clear error)"
else
  echo ".env exists      -> left untouched"
fi

echo
echo "next:"
echo "  flutter pub get"
echo "  flutter run -d <device>"
echo
echo "pre-commit now runs: secret scan + flutter analyze"
echo "  bypass for a WIP commit: git commit --no-verify"