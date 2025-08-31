# Claude Development Guide

> For authoritative architectural and development policy, see `PROJECT_RULES.md`. If guidance here conflicts, follow `PROJECT_RULES.md`.

This file contains instructions for Claude to help with development tasks.

## Local Development Setup

### 🚀 Unified Development Script

```bash
# All-in-one development script with multiple modes
./scripts/dev.sh [command]

# Available commands:
./scripts/dev.sh start    # Start development server (default)
./scripts/dev.sh build    # Build for testing  
./scripts/dev.sh test     # Run comprehensive tests
./scripts/dev.sh lint     # Fix formatting and linting
./scripts/dev.sh help     # Show help and usage

# Quick start (same as 'start'):
./scripts/dev.sh
```

### 🔧 Manual Commands (if scripts fail)

#### Start Development Server
```bash
flutter run -d chrome \
  --web-port 5000 \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=USE_FIREBASE_EMULATORS=false \
  --dart-define=STAGING_CLIENT_ID=$STAGING_CLIENT_ID
```

#### Run Tests
```bash
flutter test                    # Unit tests
flutter analyze                 # Static analysis
dart format .                   # Code formatting
```

#### Build for Testing
```bash
# In CI, do not pass client id via --dart-define. Inject into web/index.html via sed.
flutter build web --release \
  --dart-define=ENVIRONMENT=staging
```

## 🔐 OAuth Configuration

The staging Firebase project should have these OAuth origins configured:
- `http://localhost:5000` (primary development port)

**Google Client IDs:**
- **Staging**: Provided via `--dart-define=STAGING_CLIENT_ID` in local dev scripts
- **Production**: Injected via CI by replacing `{{GOOGLE_CLIENT_ID}}` in `web/index.html`

## 🌐 Environments

- **Local Development**: http://localhost:5000
- **Staging**: https://samaan-ai-staging-2025.web.app
- **Production**: https://samaan-ai-production-2025.web.app

## 🔐 CI/CD Secrets Quick Reference

Use GitHub Actions secrets only; never hardcode. Staging and production each have complete secret sets consumed by CI:

- Android signing (release): `ANDROID_RELEASE_KEYSTORE` (base64), `ANDROID_RELEASE_KEYSTORE_PASSWORD`, `ANDROID_RELEASE_KEY_ALIAS`, `ANDROID_RELEASE_KEY_PASSWORD`
- Debug signing (optional): `DEBUG_KEYSTORE` (base64) for consistent debug APKs
- Firebase service files (Android): `GOOGLE_SERVICES_STAGING`, `GOOGLE_SERVICES_PROD` → decode to `android/app/google-services.json`
- Google OAuth (Web): `GOOGLE_CLIENT_ID_STAGING` (local via `--dart-define`), `GOOGLE_CLIENT_ID_PRODUCTION` (CI injects into `web/index.html` placeholder)
- Firebase config (per env):
  - Staging: `FIREBASE_API_KEY_STAGING`, `FIREBASE_PROJECT_ID_STAGING`, `FIREBASE_APP_ID_STAGING`, `FIREBASE_APP_ID_ANDROID_STAGING`, `FIREBASE_AUTH_DOMAIN_STAGING`, `FIREBASE_STORAGE_BUCKET_STAGING`, `FIREBASE_MESSAGING_SENDER_ID_STAGING`, `FIREBASE_MEASUREMENT_ID_STAGING`
  - Production: `FIREBASE_API_KEY_PRODUCTION`, `FIREBASE_PROJECT_ID_PRODUCTION`, `FIREBASE_APP_ID_WEB_PRODUCTION`, `FIREBASE_APP_ID_ANDROID_PRODUCTION`, `FIREBASE_AUTH_DOMAIN_PRODUCTION`, `FIREBASE_STORAGE_BUCKET_PRODUCTION`, `FIREBASE_MESSAGING_SENDER_ID_PRODUCTION`, `FIREBASE_MEASUREMENT_ID_PRODUCTION`
- Deployment auth: `FIREBASE_TOKEN`, `GOOGLE_APPLICATION_CREDENTIALS_JSON` (if required)

CI writes these into build artifacts and codegen where needed; see `PROJECT_RULES.md` §16 for file mappings.

## 📝 Development Workflow

1. **Start Development**: `./scripts/dev.sh` or `./scripts/dev.sh start`
2. **Make Changes**: Edit code with hot reload
3. **Test Changes**: `./scripts/dev.sh test` 
4. **Fix Issues**: `./scripts/dev.sh lint`
5. **Build Test**: `./scripts/dev.sh build`
6. **Commit & Deploy**: Use GitHub Actions

## ⚠️ Important Notes

- Always use staging environment for local development
- Never modify production Firebase configurations
- The dev-server.sh script handles OAuth configuration automatically
- Hot reload is available during development
- Scripts include pre-flight checks and cleanup
- Source templates (web/index.html) use placeholders for deployment safety

## 🎯 Recent Improvements

- ✅ Fixed BMR calculation errors in production
- ✅ Implemented comprehensive Google profile picture support
- ✅ Enhanced dashboard UI with Material 3 design
- ✅ Created safe local development environment with proper OAuth configuration
- ✅ Added comprehensive development scripts with quality checks
- ✅ Preserved production deployment safety with template placeholders