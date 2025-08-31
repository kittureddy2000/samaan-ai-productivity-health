# Samaan AI Flutter Project: Architectural & Development Guidelines

This document defines strict architectural and development rules for this repository. It ensures consistency, quality, and maintainability as the platform grows. All contributors and AI assistants must adhere to these rules.

## 1. Project Vision: Multi‑Application Portal

- **Portal model**: A central dashboard routes users into distinct, modular applications (e.g., Fitness Tracker, Task Manager).
- **Modularity**: Each sub‑application is a self‑contained module under `lib/features/<app_name>/` containing its screens, feature‑specific business logic, and widgets.
- **Navigation**: Enter sub‑apps from the dashboard with `Navigator.push`, return with `Navigator.pop`. Keep navigation simple and predictable.
- **Shared services**: Core services like `AuthService` and `FirebaseService` are provided at the root (in `main.dart`) and reused across sub‑apps. Sub‑apps must not create their own Firebase/Auth instances.

## 2. Environment & Configuration Rules

### Web Configuration (Google Client ID)

- **Local development (`scripts/dev.sh`)**:
  - The client ID is provided exclusively via `--dart-define=STAGING_CLIENT_ID=...` within the script.
  - Do not modify `web/index.html` for local development.
- **CI/CD (GitHub Actions)**:
  - Inject the client ID by replacing `{{GOOGLE_CLIENT_ID}}` in the `<meta name="google-signin-client_id" ...>` tag in `web/index.html` using `sed`.
  - Do not pass a client ID via `--dart-define` to `flutter build web` in CI.

### Android Configuration

- **Local development**: `android/app/google-services.json` must be the staging version.
- **CI/CD**: The correct `google-services.json` (staging or production) is decoded from GitHub Secrets and overwrites the local file during the build.

### iOS Configuration

- Manage `ios/Runner/GoogleService-Info.plist` per environment. In CI, prefer decoding from secrets and overwriting the local file for the target environment.

## 3. UI/UX & Theming Principles

- **Single Source of Truth**: All styling (colors, typography, component themes) is defined in `lib/theme/app_theme.dart` (Material 3).
- **No hardcoded styles**: Do not use raw `Color` values or inline `TextStyle` in widgets. Use `Theme.of(context).colorScheme.*` and `Theme.of(context).textTheme.*`.
- **Responsiveness**: Target Android and Web. Ensure layouts adapt to a wide range of screen sizes. Use `LayoutBuilder`, `Wrap`, `GridView`, and responsive patterns.

## 4. State Management & Architecture

- **State management**: Use `provider` with `ChangeNotifier` for state and DI.
- **Service layer**: All external interactions (Firebase, HTTP, platform) live in `lib/services/`. Widgets and screens must not call Firebase APIs directly.
- **Decoupling**: Keep business logic out of widgets. Use services and/or dedicated view models (`ChangeNotifier`) that notify the UI.

## 5. Code Quality & Style

- **Formatting**: Run `dart format` before committing.
- **Linting**: `flutter analyze` must pass with zero issues, per `analysis_options.yaml`.
- **Naming**: Follow Dart conventions (e.g., `UpperCamelCase` for classes, `lowerCamelCase` for members).

## 6. Testing Strategy

- **Unit tests (`test/`)**: Test services, models, and business logic in isolation. Use mocking (`mockito`) for external dependencies (e.g., Firebase, `http.Client`).
- **Integration tests (`integration_test/`)**: Cover critical end‑to‑end flows on device/emulator, including live interaction with Firebase (where appropriate).

## 7. Logging & Error Handling

- **Logging**: Use `lib/utils/logger.dart`. No `print`. Never log secrets or PII.
- **Error handling**: Convert infrastructure errors into domain‑level failures in services. Present user‑friendly messages; never show raw exception text in the UI.
- **Global handlers**: Centralize uncaught error handling and reporting.

## 8. Performance

- Use `const` constructors and widgets where possible.
- Minimize rebuilds via `Selector`, `listen: false`, and good widget composition.
- Avoid heavy work in `build()`. Debounce rapid actions. Use proper image caching/sizing.

## 9. Accessibility & i18n

- Respect text scaling, contrast, and focus order. Add `Semantics` labels where needed.
- Prepare for localization. Avoid hardcoded user‑facing strings in code.
- Ensure RTL compatibility where applicable.

## 10. Security & Secrets

- Do not commit secrets, tokens, or client IDs in source. Use GitHub Secrets and scripts in `scripts/` to provision them.
- Validate Firebase configuration using `scripts/validate_google_services.py` and related scripts before releasing.
- Keep Android/iOS permissions minimal and justified.

## 11. Git, CI/CD, and Reviews

- **Commits**: Use Conventional Commits (`feat:`, `fix:`, `chore:`, etc.).
- **Branches**: `feat/*`, `fix/*`, `chore/*`.
- **PR checklist**: format + analyze pass; tests added/updated; screenshots for UI changes (web + mobile); responsive check.
- **CI**: Run format check, analyze, unit tests, integration smoke tests, and platform builds as applicable. Release builds run from tagged commits with environment‑specific config injected in CI.

## 12. Assets

- Register all assets in `pubspec.yaml`. Provide appropriate resolution variants for images/icons.
- Avoid network images without a caching strategy.

## 13. Shared Services & Initialization

- Initialize Firebase via `lib/firebase_options.dart`/`lib/config/firebase_config.dart` in `main.dart`.
- Provide shared `AuthService` and `FirebaseService` at the root and access via `provider`.

## 14. Contribution Checklist (pre‑merge)

1. `dart format .`
2. `flutter analyze` shows zero issues.
3. Unit tests added/updated; integration tests for critical paths.
4. Verified responsive behavior (web + mobile form factor).
5. No hardcoded styles; uses `app_theme.dart`.
6. No secrets committed; environment handled via scripts/CI.

---

Authoritative. If another document or script conflicts with these rules, this document prevails.

## 15. AI Assistant Operating Rules (Cursor)

- **Follow this document first**: If any guidance conflicts, this file wins.
- **Respect architecture**: Use feature modules under `lib/features/`, shared services in `lib/services/`, theming in `lib/theme/app_theme.dart`, and `provider` for state.
- **Environment handling**:
  - Do not edit `web/index.html` for local dev. Use `scripts/dev.sh` with `--dart-define=STAGING_CLIENT_ID`.
  - In CI, inject Google Client ID by replacing `{{GOOGLE_CLIENT_ID}}` in `web/index.html` (no `--dart-define`).
  - Keep `android/app/google-services.json` as staging in the repo; CI overwrites for target envs.
- **Edits**: Make minimal, focused edits. Do not reformat unrelated code.
- **UI**: No hardcoded colors or styles; use the theme. Ensure responsive layouts for web and mobile.
- **Services only**: Widgets never call Firebase directly. All external calls go through `lib/services/`.
- **Quality gate**: After edits, run `dart format .` and ensure `flutter analyze` is clean for touched files. Add/update tests for new service logic.
- **Ask only when blocked**: Proceed with reasonable defaults; ask clarifying questions only when a decision is destructive or ambiguous.

## 16. CI/CD and Secrets (Staging & Production)

- **Source of truth**: All environment secrets live in GitHub Actions Secrets. The build and deploy workflows must read from these secrets and write the correct files at build time. Do not hardcode any secrets in the repo.

- **Environment selection**: Branch/tag determines target (e.g., `staging/*` → staging, `main`/`release/*` → production). Workflows decode the matching secret set.

- **Secrets inventory and usage**:
  - Android signing (production release builds):
    - `ANDROID_RELEASE_KEYSTORE` (base64): decode to `android/app/release.keystore` (or equivalent path)
    - `ANDROID_RELEASE_KEYSTORE_PASSWORD`: keystore password
    - `ANDROID_RELEASE_KEY_ALIAS`: key alias
    - `ANDROID_RELEASE_KEY_PASSWORD`: key password
    - Gradle reads these via env/gradle.properties for `signingConfigs` during release builds.
  - Debug signing (CI preview/debug builds):
    - `DEBUG_KEYSTORE` (base64): optional; used to sign debug APKs consistently in CI when required.
  - Firebase service files (Android):
    - `GOOGLE_SERVICES_STAGING` (base64 `google-services.json`): decode to `android/app/google-services.json` for staging builds
    - `GOOGLE_SERVICES_PROD` (base64 `google-services.json`): decode to same path for production builds
  - Google OAuth (Web):
    - `GOOGLE_CLIENT_ID_STAGING`: injected locally via `--dart-define=STAGING_CLIENT_ID=...`
    - `GOOGLE_CLIENT_ID_PRODUCTION`: injected in CI by replacing `{{GOOGLE_CLIENT_ID}}` in `web/index.html` (no dart-define in CI)
  - Firebase config (web/android generation as needed):
    - `FIREBASE_API_KEY_STAGING`, `FIREBASE_PROJECT_ID_STAGING`, `FIREBASE_APP_ID_STAGING`, `FIREBASE_APP_ID_ANDROID_STAGING`, `FIREBASE_AUTH_DOMAIN_STAGING`, `FIREBASE_STORAGE_BUCKET_STAGING`, `FIREBASE_MESSAGING_SENDER_ID_STAGING`, `FIREBASE_MEASUREMENT_ID_STAGING`
    - `FIREBASE_API_KEY_PRODUCTION`, `FIREBASE_PROJECT_ID_PRODUCTION`, `FIREBASE_APP_ID_WEB_PRODUCTION`, `FIREBASE_APP_ID_ANDROID_PRODUCTION`, `FIREBASE_AUTH_DOMAIN_PRODUCTION`, `FIREBASE_STORAGE_BUCKET_PRODUCTION`, `FIREBASE_MESSAGING_SENDER_ID_PRODUCTION`, `FIREBASE_MEASUREMENT_ID_PRODUCTION`
    - CI uses these to generate/overwrite `lib/firebase_options.dart` for the target environment, or to pass web-only runtime config if applicable.
  - Deployment/authentication:
    - `FIREBASE_TOKEN`: Firebase CLI auth for deploys
    - `GOOGLE_APPLICATION_CREDENTIALS_JSON`: service account JSON (if required by deploy steps)

- **Files affected during CI builds**:
  - `web/index.html`: placeholder `{{GOOGLE_CLIENT_ID}}` replaced with `GOOGLE_CLIENT_ID_PRODUCTION` for production builds
  - `android/app/google-services.json`: overwritten with decoded `GOOGLE_SERVICES_STAGING` or `GOOGLE_SERVICES_PROD`
  - `lib/firebase_options.dart`: generated/overwritten from environment‑specific `FIREBASE_*` secrets for the target platform(s)
  - Android signing config (gradle): reads `ANDROID_RELEASE_*` secrets for release builds (no keystores in VCS)

- **Policy checks in CI** (see `.github/workflows/ci.yml`):
  - Enforce that `web/index.html` keeps the `{{GOOGLE_CLIENT_ID}}` placeholder (no hardcoding in CI)
  - Ensure `android/app/google-services.json` in the repo is staging (production injected only in CI)
  - Run format, analyze, unit tests, and a web build using only non‑secret defines

- **Local vs CI**:
  - Local dev uses `scripts/dev.sh` with `--dart-define=STAGING_CLIENT_ID` and the staging `google-services.json` committed in the repo.
  - CI replaces environment‑specific files and values using GitHub Secrets. Production secrets are never used locally.


