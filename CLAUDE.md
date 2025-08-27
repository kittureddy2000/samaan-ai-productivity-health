# Claude Development Guide

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
  --dart-define=GOOGLE_CLIENT_ID=362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com
```

#### Run Tests
```bash
flutter test                    # Unit tests
flutter analyze                 # Static analysis
dart format .                   # Code formatting
```

#### Build for Testing
```bash
flutter build web --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=GOOGLE_CLIENT_ID=362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com
```

## 🔐 OAuth Configuration

The staging Firebase project should have these OAuth origins configured:
- `http://localhost:5000` (primary development port)

**Google Client IDs:**
- **Staging**: `362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com`
- **Production**: Set via GitHub Actions secrets

## 🌐 Environments

- **Local Development**: http://localhost:5000
- **Staging**: https://samaan-ai-staging-2025.web.app
- **Production**: https://samaan-ai-production-2025.web.app

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