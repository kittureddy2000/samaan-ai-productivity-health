# Fitness Tracker

A comprehensive Flutter-based fitness tracking application with Firebase backend for tracking daily nutrition, exercise, and weight management.

## ✨ Features

- **Daily Logging**: Track food intake, exercise, weight, and water consumption
- **Smart Dashboard**: BMR calculation, calorie deficit tracking with date navigation
- **Reports & Analytics**: Visualize progress with weekly/monthly/yearly charts
- **Goal Management**: Set and monitor weight loss goals with progress tracking
- **Cross-Platform**: Web app and Android APK with offline capabilities

## 🚀 Live Application

- **Web App**: https://fitness-tracker-8d0ae.web.app/
- **Android APK**: Available via GitHub releases

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.32.6 (Web & Android)
- **Backend**: Firebase (Firestore, Auth, Cloud Functions)
- **CI/CD**: GitHub Actions with automated deployment
- **Charts**: FL Chart for data visualization

## 📁 Project Structure

```
lib/
├── config/          # Firebase configuration
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Firebase services
└── widgets/         # Reusable components

functions/           # Firebase Cloud Functions
scripts/             # Development tools
```

## 🏃‍♂️ Quick Start

```bash
# Clone and setup
git clone <repository>
cd Samaanai_fitness_tracker
flutter pub get

# Run with emulators
firebase emulators:start --only functions,firestore,auth
flutter run --dart-define=USE_FIREBASE_EMULATORS=true

# Set up test data
node scripts/setup-test-data.js
```

Test users: `john@test.com` / `jane@test.com` (password: `test123`)

## 📚 Documentation

- **[DEVELOPER.md](./DEVELOPER.md)** - Development setup, architecture, and workflows
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Production deployment and Play Store guide
- **[PROJECT_RULES.md](./PROJECT_RULES.md)** - Authoritative architecture and development rules
- **[privacy_policy.md](./privacy_policy.md)** - Application privacy policy

## 🎯 Status

✅ **Production Ready**
- All core features implemented and tested
- CI/CD pipeline configured and working
- Play Store deployment ready
- Local development environment with emulators