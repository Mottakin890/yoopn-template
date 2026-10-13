# YooPN Templates

A **credential-free mirror of the YooPN Flutter application**, published as a
working template. Everything a developer needs to see is here — the full
source, the native Android/iOS wiring, the backend migrations, 50 passing
tests and a CI pipeline — and nothing that identifies a real project or a
real account.

```sh
git clone <this-repo> && cd yoopn-templates
./tool/install_hooks.sh      # wires pre-commit hooks, creates .env from the example
flutter pub get
flutter run -d <device>
```

Verify it is healthy before you read a line of it:

```sh
flutter analyze    # No issues found!
flutter test       # All tests passed! (50 tests)
```

> Every identifier is a placeholder: Android/iOS bundle id `com.example.yoopn`,
> deep-link scheme `io.supabase.example`, Supabase project
> `https://YOUR-PROJECT-REF.supabase.co`. Fill in your own — see
> [`SECURITY.md`](SECURITY.md). There are **no credentials in this source tree**.

---

## What this template demonstrates

### Architecture — clean architecture, enforced by convention

Three features (`auth`, `dashboard`, `splash`), each with the same three
layers, dependencies pointing inward only:

```
lib/
  main.dart                  bootstrap: zone guard, crash handlers, DI, portrait lock
  app.dart                   global blocs + MaterialApp.router
  core/                      (27 files) cross-cutting: config, DI, routing, theme,
                             logging, telemetry, ads, error mapping
  features/<feature>/
    data/          datasources · models · repositories · tunnel
    domain/        entities · repository contracts · use cases
    presentation/  bloc (event/state/bloc) · view · widgets · helper
```

* **19 use cases**, one class per file, each a single public `call()`.
* **Repositories are contracts in `domain`, implementations in `data`.** The
  bloc never sees Dio, sqflite or `openvpn_flutter`.
* **`VpnTunnel` is an interface with two implementations** — `OpenVpnTunnel`
  on Android/iOS, `SimulatedVpnTunnel` on desktop/web. That is what keeps 50
  tests runnable headlessly against a real VPN client.
* **`VpnLocalDataSource` is conditional by platform** — sqflite on
  mobile/macOS, in-memory on web/Windows/Linux. One interface, two backing
  stores, selected in `core/utils/dependency_injection.dart`.

### State management — `flutter_bloc`, no exceptions

`VpnBloc` alone carries 7 events (`Toggled`, `ServerSelected`,
`ServersRequested`, `DetailChanged`, `TunnelSync`, `BackgroundRefreshed`,
`Failed`) and defends against the failure modes that actually ship bugs:

* **single-flight** in-flight fetch, and a 2s refresh budget so a rebuild
  cannot storm the network;
* auto-selection of the best relay that **preserves a manual pick**;
* a `connectedSince` timer and a live `connectionDetail` sub-stage
  (`Authenticating…`, `Assigning IP…`);
* a **generation guard** around the 3s tunnel poll so a late callback from a
  cancelled attempt cannot resurrect stale state.

Side effects are observable rather than hidden:
`AppBlocObserver` logs every transition, `Telemetry.track` records the
outcome, and neither can throw into the UI.

### Toolchain fluency

| Concern | Tool | Where it shows |
|---|---|---|
| SDK pinning | **FVM** 3.47.6 | `.fvmrc`, `.vscode/settings.json` |
| Static analysis | `flutter analyze`, `flutter_lints` | clean, and CI gates every commit |
| Formatting | `dart format` check in CI | — |
| Dependency integrity | `pubspec.lock` | CI fails if `pub get` mutates it |
| Native Android | Gradle **Kotlin DSL**, AGP 9, JDK 17 | `android/**/*.kts` |
| Native iOS | Xcode project + Network Extension target | `ios/`, `ios/VPNExtension/` |
| Secrets | `--dart-define`, `--dart-define-from-file`, dotenv | `core/config/`, `SECURITY.md` |
| Local storage | sqflite (+ `sqflite_common_ffi` for desktop tests) | `dashboard/data/datasources/` |
| Networking | Dio + a logging interceptor with truncated bodies | `core/utils/` |
| Routing | `go_router` with an auth-guard redirect + nav observer | `core/routes/` |
| DI | GetIt, idempotent `initDependencyInjection()` | `core/utils/` |
| Observability | tagged logger (`TUNNEL`/`VPN`/`GATE`/`TELEMETRY`/`PERM`) | `core/utils/app_logger.dart` |
| Testing | `flutter_test`, headless fakes | `test/` — 50 tests |
| CI | GitHub Actions, 4 jobs, `if-no-files-found`, artifact upload | `.github/workflows/ci.yml` |
| Secret scanning | gitleaks + pre-commit + fallback sweep | `.gitleaks.toml`, `.githooks/` |
| Dependency bots | Dependabot (actions + gradle) | `.github/dependabot.yml` |

### Native integration that actually works

Getting a real OpenVPN tunnel to work on Android is mostly platform
plumbing, and all of it is in this repo:

* `MainActivity.kt` forwards the **system VPN-consent result** to
  `OpenVPNFlutterPlugin.connectWhileGranted(...)`. Without it `connect()`
  hangs forever — the single most common failure with this plugin.
* `AndroidManifest.xml` declares `BIND_VPN_SERVICE`, the foreground-service
  types, and `POST_NOTIFICATIONS`.
* `packaging.jniLibs.useLegacyPackaging = true` keeps `ics-openvpn`'s `.so`
  unpacked. `gradle.properties` deliberately does **not** set
  `android.bundle.enableUncompressedNativeLibs` — AGP 9 removed it.
* `POST_NOTIFICATIONS` is requested on the first frame
  (`core/utils/notification_permission.dart`), because the plugin's service
  runs `foregroundServiceType="systemExempted"` and stalls its handshake when
  the persistent notification is suppressed. Denial is logged, not fatal.
* iOS ships the `PacketTunnelProvider.swift` template, the App Group id and
  the provider bundle id that `OpenVpnTunnel` reads — plus
  `ios/VPNExtension/README.md` for the one Xcode step that cannot be scripted.

### Resilience details that survive review

* **The VPNGate CSV parser is tolerant by construction** (`csvToJson`):
  handles commas inside quoted fields, skips `*`/`#` header rows, and the
  parse is isolated so one malformed row cannot take down the fetch.
* **Per-route timeouts** on the tunnel (30s total, 8s floor), a 2s grace
  window for the engine's initial reset emission, and a 3s polling fallback
  for missed callbacks. Timeouts name the stage they died at.
* **`VpnException` → `VpnFailure` mapping** (`core/errors/vpn_failures.dart`)
  so the user sees *"Could not read the server configuration — try another
  relay"*, never a raw plugin stack trace.
* **Server sourcing degrades in order**: bundled snapshot → memory → sqflite
  → live API (5 attempts, 15-min TTL) → merge → background persist. The app
  is useful with no network at all.
* **`Telemetry` never throws** — Supabase down, table missing, RLS rejecting
  the insert: analytics silently no-op rather than crash the app.

### Telemetry backend

Supabase Postgres instead of a heavyweight SDK, so there is no second
project to configure. `supabase/migrations/` creates two tables with
insert-only grants for the client key:

```sh
./supabase/probe.sh      # both inserts must print HTTP 201 OK
```

---

## Credential handling (the point of this template)

Resolution order is fixed in `lib/core/config/supabase_config.dart`:

1. `--dart-define=SUPABASE_URL=…` — compile-time, nothing written to disk
2. `.env` bundled as an asset — **development only**; a release build that
   resolves this way logs a warning under `CONFIG`
3. otherwise a `StateError` naming the key and the source checked

```sh
# development
cp .env.example .env

# release — keeps the key out of the APK and off the command line
flutter build apk --release --dart-define-from-file=.secrets.json
```

Three layers enforce it, and the last one runs in CI:

| Layer | Mechanism |
|---|---|
| **Pre-commit** | `.githooks/pre-commit` → `tool/scan_secrets.sh --staged`, then `flutter analyze` |
| **Scanner** | `.gitleaks.toml` — default ruleset plus Supabase keys, concrete `*.supabase.co` refs, production AdMob ids, Firebase secrets, keystore passwords |
| **CI `guard` job** | gitleaks over the full history, fallback sweep, plus assertions that `.env` and keystores are untracked. `quality` and `build` both `needs: guard` |

Placeholders are *not* secrets: `.env.example` holds
`https://YOUR-PROJECT-REF.supabase.co` and the scanner's allowlist recognises
exactly those shapes — so a placeholder can never be mistaken for a key, and a
real key can never hide in the one file that is committed. `_require()` also
rejects placeholder-shaped values at runtime, so a fresh clone fails with
*"SUPABASE_URL is not configured"* instead of a DNS error against a
non-existent project.

Full policy: [`SECURITY.md`](SECURITY.md).

---

## Layout

```
.
├── lib/                     application source (8.7k lines, 108 Dart files)
├── test/                    50 tests — bloc, tunnel, entities, CSV, cache, telemetry, ads
├── tool/
│   ├── fetch_snapshot.dart  refreshes assets/servers_snapshot.json from VPNGate
│   ├── scan_secrets.sh      secret scanner (gitleaks + fallback)
│   └── install_hooks.sh     one-command local setup
├── supabase/                migrations, RLS fix, probe.sh
├── android/                 Gradle KTS + MainActivity.kt (VPN-consent forwarding)
├── ios/                     Xcode project + VPNExtension template
├── .github/workflows/ci.yml guard → quality → build
├── .gitleaks.toml           credential rules
├── .githooks/pre-commit     secret scan + analyze
├── CONTEXT.md               architecture notes, decisions log, verification steps
└── VPN_SETUP.md             tunnel setup, platform specifics, troubleshooting
```

## Adopting it

1. `cp .env.example .env` → fill in Supabase.
2. Change `name:` in `pubspec.yaml` and the 254 `package:yoopn_templates/`
   imports (`sed -i 's|package:yoopn_templates/|package:<your_app>/|g'` on
   `*.dart`).
3. Change `namespace`/`applicationId` in `android/app/build.gradle.kts`,
   move `android/app/src/main/kotlin/com/example/yoopn/` to match, and update
   `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`.
4. Align the deep-link scheme in `android/app/src/main/AndroidManifest.xml`,
   `ios/Runner/Info.plist`, `.env` and the Supabase redirect allowlist.
5. Update the App Group / provider bundle id in
   `lib/features/dashboard/data/tunnel/openvpn_tunnel.dart`.
6. Re-run `./tool/scan_secrets.sh --history`.

Steps 2–5 are exactly what `com.vis.yoopn` → `com.example.yoopn` did in this
repository, so the diff is the reference implementation.

## Licence

`openvpn_flutter`, `ics-openvpn` and `OpenVPNAdapter` are GPL-3.0; anything
distributed from this template inherits that obligation — see `LICENSE.md`.