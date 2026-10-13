# YooPN — Flutter VPN Client Template

A production-shaped Flutter application built to demonstrate **architecture, state management, security engineering, and native-integration depth** — not just a UI that compiles.

It ships the complete source of a working VPN client: a real OpenVPN tunnel, a live relay directory with offline-first caching, Supabase auth with three sign-in methods, a rewarded-ad monetisation gate, and crash telemetry — with **zero credentials in the tree**.

```sh
git clone <this-repo> && cd yoopn-templates
./tool/install_hooks.sh        # wires pre-commit guards, creates .env from the example
flutter pub get
flutter run -d <device>
```

Verify before you read:

```sh
flutter analyze    # No issues found!
flutter test       # All tests passed! (74 tests)
```

---

## Contents

- [What this demonstrates](#what-this-demonstrates)
- [Architecture](#architecture)
- [Type safety: the failure system](#type-safety-the-failure-system)
- [State management](#state-management)
- [Design system](#design-system)
- [Resilience](#resilience)
- [Security](#security)
- [Native integration](#native-integration)
- [Tooling](#tooling)
- [Numbers](#numbers)

---

## What this demonstrates

| Area | Evidence |
|---|---|
| **Clean Architecture** | 3 features × 3 layers, dependencies pointing inward only, 17 single-purpose use cases |
| **MVVM** | BLoC as ViewModel — no `setState` business logic, no second state container |
| **Type-safe errors** | 15-member `enum` + typed resolver; a new failure state is a compile error, not a runtime surprise |
| **Repository pattern** | Contracts in `domain`, implementations in `data`, datasources behind interfaces |
| **Dependency injection** | GetIt composition root, 20 registrations, platform strategies resolved at wiring time |
| **Offline-first** | 5-tier server sourcing that stays useful with the network unplugged |
| **Security engineering** | 3-layer credential defence, CI that unpacks the APK to *prove* no key shipped |
| **Concurrency** | Single-flight dedup, promise-chaining serialisation, generation guards against stale callbacks |
| **Design system** | 25 colour + 29 type tokens, zero literals outside the token files |
| **Native integration** | Android VPN-consent forwarding, iOS Network Extension target, real OpenVPN engine |

---

## Architecture

```
lib/
  main.dart                  bootstrap: error zone, crash handlers, DI, orientation lock
  app.dart                   MultiBlocProvider + MaterialApp.router
  core/                      29 files — cross-cutting, feature-agnostic
    ads/                     AdMob config, rewarded gate, counter store
    config/                  SupabaseConfig, placeholder guard
    errors/                  typed VPN failure system
    routes/                  AppPages, router + auth redirect
    telemetry/               Supabase telemetry, navigator observer
    themes/                  AppColors, AppTextStyles, AppTheme
    utils/                   logger, GetIt DI, Dio interceptor, validators
  features/<feature>/
    data/          datasources · models · repositories · tunnel
    domain/        entities · repository contracts · use cases
    presentation/  bloc · view · widgets · helper
```

**Dependency rule — enforced, not aspirational:**

```
presentation ──▶ domain ◀── data
       │                     │
       └─────── core ◀───────┘      (core never imports a feature)
```

- `domain/` imports no Flutter, no `dio`, no `sqflite`.
- `presentation/` never imports `data/` — blocs see repository contracts only.
- Repository **contracts** live in `domain`, **implementations** in `data`.
- Cross-layer wiring happens exclusively in `core/utils/dependency_injection.dart`.

The seams are real, not decorative:

```dart
abstract interface class VpnRepository { ... }        // domain
class VpnRepositoryImpl implements VpnRepository { ... }  // data
class VpnTunnel { ... }                               // port
class OpenVpnTunnel implements VpnTunnel { ... }       // Android/iOS
class SimulatedVpnTunnel implements VpnTunnel { ... }  // desktop/web
```

That `VpnTunnel` abstraction is what lets the entire suite run headlessly
against a real VPN client. `VpnLocalDataSource` and `AdCounterStore` each ship a
sqflite implementation and an in-memory one, selected by platform at wiring time.

### Repository pattern

```
bloc ──▶ use case ──▶ repository contract ◀── repository impl ──▶ datasource
```

Datasources own Dio, sqflite, `rootBundle` and `openvpn_flutter`. A repository
orchestrates them; it never leaks a `Map<String, dynamic>` upward. Entities are
what reach the presentation layer.

---

## Type safety: the failure system

The part of this codebase I'd most want reviewed.

A VPN client fails in a dozen distinguishable ways — the user denied the VPN
permission, the relay rejected the login, the tunnel stalled at `assign_ip`,
the connection was cancelled, the relay has no config. Each deserves a
different, *actionable* message.

This app models that as a closed set:

```dart
enum VpnFailureCode {
  network('No connection. Showing saved servers.'),
  permissionDenied('VPN permission denied. Allow the VPN request and try again.'),
  authRejected('This relay rejected the login. Try another server.'),
  timeout('This relay is too slow. Try another server.'),
  // … 11 more
}

class VpnException implements Exception {
  const VpnException(this.code, {this.cause, this.detail});
  final VpnFailureCode code;
  final Object? cause;
  final String? detail;
}
```

**Every failure site is typed.** `throw VpnException(VpnFailureCode.busy)`.
Resolution is total and testable:

```dart
VpnFailureCode resolveVpnFailureCode(Object error);   // never string-matches its own codes
String vpnFailureMessage(Object error);               // what the user actually reads
```

Why this matters concretely: an earlier revision classified errors by
`error.toString().contains('SocketException')` against a `String code` field.
The app threw **12 distinct codes** and the resolver recognised **none** of them
— so every real failure rendered as *"Something went wrong."* Two of the four
defined constants were unreachable. The typed version makes that class of bug
impossible: a new code must be added to the enum, it cannot be misspelled, and
`vpn_failures_test.dart` asserts every code survives resolution.

---

## State management

`flutter_bloc` only. No `setState` outside genuinely local UI state.

**`VpnBloc`** owns 7 events and defends against the failure modes that actually
ship bugs:

- **single-flight** in-flight fetch plus a 2s refresh budget, so a rebuild
  cannot storm the network;
- auto-selection of the best relay that **preserves a manual pick** — the list
  may refresh mid-tunnel, the user's choice does not get overridden;
- a `connectedSince` timestamp and live sub-stage text (`Authenticating…`,
  `Assigning IP…`);
- a **generation guard** around the 3s tunnel poll, so a late callback from a
  cancelled attempt cannot resurrect stale state.

**`AuthBloc`** owns 10 events across three sign-in methods plus account
maintenance, with a graceful fallback: an `invalid_credentials` failure during
sign-in automatically attempts sign-up — the common case for a user who
confused the two.

Side effects are observable but cannot break the UI: `AppBlocObserver` logs
every transition, `Telemetry` records outcomes, and **neither can throw**.

---

## Design system

Zero hardcoded values outside two token files.

```dart
AppColors.primary          // 25 tokens
AppTextStyles.displayLarge // 29 tokens
```

- **Colours:** no `Color(0x…)`, no `'#RRGGBB'`, no Material `Colors.*` anywhere
  outside `app_colors.dart`. `AppTheme` maps them onto `ColorScheme`, so
  framework widgets — switch, snackbar, progress indicator — inherit the
  palette rather than restating it.
- **Type:** a 29-step scale, wired into `ThemeData.textTheme`, with
  `copyWith` reserved for genuinely dynamic values (a status colour, a
  timer-dependent label).

```sh
grep -rnP "(?<!App)Colors\.[a-zA-Z]+" lib          # empty
grep -rn "Color(0x" lib | grep -v app_colors       # empty
```

The scale also collapsed real duplication: `StatusPanel` and its connected-timer
title had drifted into two near-identical 26sp/800 styles, now one token.

---

## Resilience

The interesting engineering is in what happens when things go wrong.

**Offline-first server sourcing.** A relay list resolves through five tiers:

```
bundled snapshot → memory → sqflite cache → live VPNGate API → merged + persisted
```

The app is fully usable with no network at all. If every tier fails and no live
relay remains, it throws a *typed* `unreachable` failure — never a raw socket
error.

**Tolerant parsing.** The VPNGate CSV parser handles commas inside quoted
fields, skips header rows, and isolates parsing so one malformed row cannot take
down the fetch.

**Concurrency.** Dart has no locks, so concurrent `getServers()` calls chain on a
promise tail and see only atomic reference swaps. Memoised resources (DB handle,
engine init, in-flight fetch) all use single-flight patterns — three separate
implementations of that idea, each matching its lifetime.

**Timeouts name the stage they died at:** *"Stuck at `assign_ip` — this relay is
too slow."*

**Telemetry never throws.** Supabase down, table missing, RLS rejecting the
insert — analytics silently no-op rather than crash the app.

---

## Security

The differentiator in this repo is treating credentials as a build-system
problem rather than a `.gitignore` entry.

**Resolution order is fixed** in `lib/core/config/supabase_config.dart`:

1. `--dart-define=SUPABASE_URL=…` — compile-time, nothing on disk
2. bundled `.env` asset — **development only**; a release build resolving this
   way logs a warning
3. otherwise a `StateError` naming the key and the source checked

```sh
# development
cp .env.example .env

# release — keeps the key out of the APK and out of shell history
flutter build apk --release --dart-define-from-file=.secrets.json
```

**Three enforcement layers:**

| Layer | Mechanism |
|---|---|
| Pre-commit | `tool/scan_secrets.sh --staged`, then `flutter analyze` — hard failures |
| Scanner | `.gitleaks.toml` — default ruleset plus Supabase keys, concrete `*.supabase.co` refs, production AdMob ids, Firebase secrets, keystore passwords |
| CI `guard` job | gitleaks over full history, fallback sweep, plus structural assertions that `.env` and keystores are untracked. `quality` and `build` both `needs: guard` |

**The `build` job is the part worth reading.** After producing a release APK it
unpacks the artifact and asserts the Supabase URL is **absent** from the asset
bundle but **present** in `libapp.so`. That proves two things at once — the key
never ships in cleartext, *and* the `--dart-define` actually applied rather than
being silently dropped. Most CI configs verify only the first and ship a broken
app.

**Placeholders fail fast.** `looksLikePlaceholder` rejects `YOUR_…`, `changeme`,
`<project-ref>`, `${…}` shaped values at runtime, so a fresh clone fails with
*"SUPABASE_URL is not configured"* rather than a DNS error against a
non-existent project. It is a pure function with its own test suite.

`service_role` keys are denylisted and must never enter a client build — the
client uses the publishable key, protected by Row Level Security.

Full policy: [`SECURITY.md`](SECURITY.md).

---

## Native integration

Getting a real OpenVPN tunnel working on Android is mostly platform plumbing.
All of it is here:

- `MainActivity.kt` forwards the **system VPN-consent result** to
  `OpenVPNFlutterPlugin.connectWhileGranted(...)`. Without it `connect()` hangs
  forever — the single most common failure with this plugin.
- `AndroidManifest.xml` declares `BIND_VPN_SERVICE`, foreground-service types and
  `POST_NOTIFICATIONS`.
- `packaging.jniLibs.useLegacyPackaging = true` keeps `ics-openvpn`'s native
  libs unpacked; `gradle.properties` deliberately omits
  `android.bundle.enableUncompressedNativeLibs` (removed in AGP 9).
- `POST_NOTIFICATIONS` is requested on the first frame, because the plugin runs
  `foregroundServiceType="systemExempted"` and stalls its handshake when the
  persistent notification is suppressed. Denial is logged, never fatal.
- iOS ships the `PacketTunnelProvider.swift` template, App Group id and provider
  bundle id, plus `ios/VPNExtension/README.md` for the one Xcode step that
  cannot be scripted.

---

## Tooling

| Concern | Tool |
|---|---|
| SDK pinning | **FVM** 3.47.6 (`.fvmrc`) |
| Analysis | `flutter analyze` + `flutter_lints` 6, strict inference & raw types |
| Formatting | `dart format`, enforced in CI |
| DI | **GetIt** 9 |
| State | **flutter_bloc** 9 + `equatable` 3 |
| Routing | **go_router** 18 with auth-guard redirect |
| HTTP | **Dio** 5 + logging interceptor |
| Storage | **sqflite** (+ `sqflite_common_ffi` for desktop tests) |
| Responsive | **flutter_screenutil**, design size 375×812 |
| Backend | **supabase_flutter** 2 + Postgres migrations |
| VPN | `openvpn_flutter` 1 |
| Ads | **google_mobile_ads** 9 |
| Tests | `flutter_test` — 74 tests |
| CI | GitHub Actions, 4 gated jobs |
| Secret scanning | **gitleaks** + portable fallback sweep + pre-commit |
| Deps | Dependabot (actions + gradle) |

```sh
./tool/install_hooks.sh                       # guards + .env
./tool/scan_secrets.sh [--staged|--history]   # credential sweep
./supabase/probe.sh                           # telemetry inserts -> 201 OK
dart run tool/fetch_snapshot.dart              # refresh bundled relay snapshot
```

Engineering reference, architecture contract and known trade-offs:
[`DEVELOPER.md`](DEVELOPER.md).

---

## Numbers

| | |
|---|---|
| Dart source | 106 files · ~8 900 lines |
| Core / features | 29 / 75 files |
| Use cases | 17, one class per file |
| Routes | 10 |
| Tests | 74 |
| Design tokens | 25 colour · 29 type |
| Failure codes | 15, exhaustively typed |
| Credentials in tree | **0** |

---

## Adopting it

1. `cp .env.example .env` → fill in Supabase.
2. Rename the package: `sed -i 's|package:yoopn_templates/|package:<your_app>/|g'`
   across `*.dart`, and update `name:` in `pubspec.yaml`.
3. Change `namespace`/`applicationId` in `android/app/build.gradle.kts`, move the
   Kotlin package directory to match, update `PRODUCT_BUNDLE_IDENTIFIER` in
   `ios/Runner.xcodeproj/project.pbxproj`.
4. Align the deep-link scheme across `AndroidManifest.xml`, `Info.plist`, `.env`
   and the Supabase redirect allowlist.
5. Update the App Group / provider bundle id in `openvpn_tunnel.dart`.
6. Re-run `./tool/scan_secrets.sh --history`.

Steps 2–5 are exactly what `com.vis.yoopn` → `com.example.yoopn` did in this
repository, so the diff is the reference implementation.

---

## Licence

`openvpn_flutter`, `ics-openvpn` and `OpenVPNAdapter` are **GPL-3.0**. Anything
distributed from this template inherits those obligations — see
[`LICENSE.md`](LICENSE.md).