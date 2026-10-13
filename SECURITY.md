# Security & credential policy

This repository is a **template**. It ships the complete YooPN application
source, but by design it contains **no live credential of any kind** — no
Supabase project, no AdMob account, no keystore, no OAuth client, no API key.

Everything environment-specific is injected at build time or read from a
git-ignored `.env`.

---

## 1. What must never enter version control

| Item | Where it lives instead | Guard |
|---|---|---|
| `SUPABASE_URL` | `.env` (dev) / `--dart-define` (release) | `.gitignore`, `guard` CI job, pre-commit |
| `SUPABASE_ANON_KEY` | same | same |
| `service_role` key | **nowhere in a client app, ever** | denylist rule in `.gitleaks.toml` |
| `ADMOB_APP_ID` / ad unit ids | `--dart-define` | `.gitleaks.toml` `admob-production-unit` |
| Android signing (`key.properties`, `*.jks`) | `android/key.properties`, keystore outside the repo | `.gitignore`, CI file check |
| `google-services.json` / `GoogleService-Info.plist` | local, git-ignored | `.gitignore`, CI file check |
| Redirect URL scheme / bundle ids | placeholders `io.supabase.example`, `com.example.yoopn` | — |

`.env.example` is the **only** env-shaped file that is committed, and it
contains placeholders (`https://YOUR-PROJECT-REF.supabase.co`,
`YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY`) that are explicitly recognised by
the scanner's allowlist — so a placeholder can never be mistaken for a live
key, and a live key can never be laundered through that file.

---

## 2. How configuration resolves

`lib/core/config/supabase_config.dart` resolves each value in a fixed order:

1. `--dart-define=SUPABASE_URL=…` (compile-time, `String.fromEnvironment`)
2. the bundled `.env` asset (development only)
3. failure → `StateError` naming the key and the source that was checked

Two consequences worth knowing:

* **Release builds must use `--dart-define`.** `pubspec.yaml` lists `.env`
  as an asset for local development, which means the file is packaged into
  the APK. Anyone can extract it. `SupabaseConfig.load()` logs a warning
  under `CONFIG` whenever a release build resolves from `.env`.
* **Placeholders fail fast.** `_require()` rejects values matching
  `YOUR_… / your_… / changeme / xxxx / <project / ${`, so a freshly cloned
  repo produces a clear "SUPABASE_URL is not configured" error instead of a
  DNS failure against a non-existent Supabase project.

Preferred release form — keeps secrets off the command line and out of
shell history:

```sh
flutter build apk --release --dart-define-from-file=.secrets.json
```

`tool/install_hooks.sh` and `CI` both demonstrate this path.

---

## 3. The guards

```sh
./tool/install_hooks.sh        # wire .githooks/ + create .env from the example
./tool/scan_secrets.sh         # scan the working tree
./tool/scan_secrets.sh --staged
./tool/scan_secrets.sh --history
```

* `.gitleaks.toml` — extends gitleaks' default ruleset and adds
  Supabase publishable keys, concrete `*.supabase.co` project URLs,
  production AdMob unit ids, Firebase client secrets, and keystore
  passwords. A private-key / `sb_secret_` / `AIza` / `AKIA` denylist is
  applied *after* the allowlist, so no path can be used to excuse those.
* `.githooks/pre-commit` — secret scan first, then `flutter analyze`. Both
  are hard failures; `git commit --no-verify` exists for WIP only.
* `guard` job in `.github/workflows/ci.yml` — gitleaks over the full
  history, the portable fallback sweep, and two structural assertions:
  `.env` is untracked, and no keystore/signing file is tracked. Everything
  downstream (`quality`, `build`) is gated on it, so a leak fails the
  pipeline before any build runs.

`gitleaks` is optional locally — `tool/scan_secrets.sh` falls back to a
built-in regex sweep rather than silently passing when the binary is
absent.

---

## 4. If you introduce a credential

1. Add the variable to `.env.example` as a `YOUR_…` placeholder with a
   comment saying where to obtain it.
2. Read it in `core/config/` via `String.fromEnvironment` with a `.env`
   fallback. Never `const` a value into `lib/`.
3. Add a matching rule to `.gitleaks.toml` if the existing ones do not
   already cover that provider.
4. `git add -A && ./tool/scan_secrets.sh --staged` before committing.

## 5. If a secret is ever committed

Rotation beats deletion — assume anything pushed is compromised:

1. Rotate the credential in the provider's dashboard first.
2. `git rm --cached .env`, then rewrite history
   (`git filter-repo --invert-paths --path .env`).
3. Force-push, tell collaborators to re-clone, and re-run
   `./tool/scan_secrets.sh --history` to confirm.

## 6. Reporting

This is a portfolio template with no live secrets to abuse; there is no
security contact to file against. For issues with the credential-handling
code itself, open a GitHub issue describing the failure mode, not a real
key.

## 7. Licensing note

`openvpn_flutter`, `ics-openvpn` and `OpenVPNAdapter` are **GPL-3.0**.
Anything you build from this template and distribute inherits those
obligations. See `LICENSE.md`.