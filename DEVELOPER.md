# Developer Guide

## Quick Start

### Local Development
```bash
# Clone and setup
git clone <repository>
cd Samaanai_fitness_tracker
flutter pub get

# Run with emulators
firebase emulators:start --only functions,firestore,auth
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

### Test Data Setup
```bash
# Set up test users and data in emulators
node scripts/setup-test-data.js

# Test users: john@test.com / jane@test.com (password: test123)
```

## Architecture

### Tech Stack
- **Frontend**: Flutter 3.32.6 (Web & Android)
- **Backend**: Firebase (Firestore, Auth, Functions)
- **State Management**: Provider pattern
- **Charts**: FL Chart
- **CI/CD**: GitHub Actions

### Project Structure
```
lib/
├── config/          # Firebase configuration
├── models/          # Data models (DailyEntry, CalorieReport, etc.)
├── screens/         # UI screens (Dashboard, Reports, Daily Log)
├── services/        # Firebase and authentication services
└── widgets/         # Reusable UI components

functions/           # Firebase Cloud Functions
scripts/             # Development and test scripts
```

## Development Workflow

### Branch Strategy
```
feature/new-feature  →  Pull Request to main
main                 →  Staging deployment (automatic)
v1.0.0 (tag)        →  Production deployment (automatic)
```

### CI/CD Pipeline
- **Pull Requests**: Run tests and validation
- **Main branch**: Deploy to staging environment
- **Version tags**: Deploy to production and create GitHub release

## Firebase Projects

### Staging (`fitness-tracker-8d0ae`)
- **Web**: https://fitness-tracker-8d0ae.web.app
- **Purpose**: Development and testing
- **Keystore**: Debug (automatic)

### Production (`fitness-tracker-p2025`)
- **Web**: https://fitness-tracker-p2025.web.app
- **Purpose**: Live application
- **Keystore**: Release (signed)

## GitHub Secrets

Required secrets for CI/CD workflows:

### Firebase & Authentication
| Secret | Description |
|--------|-------------|
| `FIREBASE_TOKEN` | Firebase CI token (`firebase login:ci`) |
| `GOOGLE_SERVICES_STAGING` | Base64-encoded staging google-services.json |
| `GOOGLE_SERVICES_PROD` | Base64-encoded production google-services.json |
| `GOOGLE_CLIENT_ID_STAGING` | Staging web OAuth client ID |
| `GOOGLE_CLIENT_ID_PRODUCTION` | Production web OAuth client ID |

### Android Release Signing
| Secret | Description |
|--------|-------------|
| `ANDROID_RELEASE_KEYSTORE` | Base64-encoded production keystore |
| `ANDROID_RELEASE_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_RELEASE_KEY_PASSWORD` | Key password |
| `ANDROID_RELEASE_KEY_ALIAS` | Key alias |

## Common Commands

### Development
```bash
# Run app with emulators
flutter run --dart-define=USE_FIREBASE_EMULATORS=true

# Build for web
flutter build web

# Run tests
flutter test

# Code analysis
flutter analyze
```

### Firebase Functions
```bash
# Local development
cd functions
npm install
firebase emulators:start --only functions,firestore,auth

# Deploy to staging
firebase use staging
firebase deploy --only functions

# Deploy to production
firebase use production
firebase deploy --only functions
```

### Release
```bash
# Create production release
git tag v1.0.0
git push origin v1.0.0

# Manual workflow trigger
gh workflow run release.yml
```

## Troubleshooting

### Google Sign-In Issues
- Verify SHA-1 fingerprints match between keystore and Firebase
- Check OAuth client IDs in GitHub secrets
- Ensure google-services.json is correctly configured

### Emulator Issues
- Functions use HTTP endpoints locally (no auth required)
- Firestore emulator runs on localhost:8080
- Functions emulator runs on localhost:5001

### Build Issues
- Run `flutter clean` for cache issues
- Check Android SDK licenses: `flutter doctor --android-licenses`
- Verify Java/Gradle compatibility

## Key Features

### Core Functionality
- Firebase Authentication (Google + Email/Password)
- Daily food and exercise logging
- BMR calculation and calorie tracking
- Weight loss goals and progress monitoring
- Comprehensive reports and analytics
- Cross-platform (Web + Android)

### Cloud Functions
- `calculateBMR`: BMR calculation based on user profile
- `generateCalorieReport`: Weekly/monthly/yearly reports
- `updateUserStats`: Background user statistics updates

## Local Testing

Access your local development environment:
- **App**: http://localhost:3000
- **Emulator UI**: http://localhost:4000
- **Firestore**: http://localhost:8080
- **Functions**: http://localhost:5001

The emulator UI allows you to:
- Browse Firestore collections and documents
- Monitor function calls and logs
- Manage authentication users
- View and edit test data