#!/bin/bash

# Unified Samaan AI Development Script
# Usage: ./scripts/dev.sh [command]
# Commands: start, build, test, lint, help

set -e

# Configuration
STAGING_CLIENT_ID="362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com"
DEV_PORT=5000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Pre-flight checks
run_preflight_checks() {
    print_status "🔍 Pre-flight checks..."
    echo "----------------------"

    # Check Flutter
    if command_exists flutter; then
        FLUTTER_VERSION=$(flutter --version | grep "Flutter" | head -n1)
        print_success "Flutter: $FLUTTER_VERSION"
    else
        print_error "Flutter not found. Please install Flutter first."
        exit 1
    fi

    # Check Chrome
    if command_exists google-chrome || command_exists chrome || command_exists "Google Chrome"; then
        print_success "Chrome: Available"
    else
        print_warning "Chrome: May not be available (will try default browser)"
    fi

    # Check Firebase CLI
    if command_exists firebase; then
        FIREBASE_VERSION=$(firebase --version)
        print_success "Firebase CLI: $FIREBASE_VERSION"
    else
        print_warning "Firebase CLI: Not installed (optional for local development)"
    fi

    echo ""
}

# Cleanup function
cleanup_environment() {
    print_status "🧹 Cleanup..."
    echo "-------------"

    # Kill existing processes on our port
    print_status "🛑 Checking for existing processes on port $DEV_PORT..."
    if lsof -ti:$DEV_PORT >/dev/null 2>&1; then
        print_status "🔄 Killing existing processes on port $DEV_PORT..."
        lsof -ti:$DEV_PORT | xargs kill -9 2>/dev/null || true
        print_success "Port $DEV_PORT is now free"
    else
        print_success "Port $DEV_PORT is available"
    fi

    echo ""
}

# Dependencies function
setup_dependencies() {
    print_status "📦 Dependencies..."
    echo "-----------------"
    print_status "🧹 Running flutter clean..."
    flutter clean > /dev/null 2>&1

    print_status "📥 Running flutter pub get..."
    flutter pub get > /dev/null 2>&1

    print_success "Dependencies are up to date"
    echo ""
}

# Health check function
run_health_check() {
    print_status "🧪 Quick Health Check..."
    echo "------------------------"
    print_status "⚡ Running quick syntax check..."
    if flutter analyze --no-pub > /dev/null 2>&1; then
        print_success "Code analysis passed"
    else
        print_warning "Code analysis found issues (will continue anyway)"
    fi
    echo ""
}

# Start development server
start_server() {
    echo ""
    print_status "🚀 Samaan AI - Local Development Environment"
    echo "=============================================="
    echo "📱 Environment: staging"
    echo "🌐 Port: $DEV_PORT (fixed)"
    echo "🔐 OAuth: localhost:$DEV_PORT should be configured in Firebase"
    echo "🔧 Using staging Google Client ID for local development"
    echo ""

    run_preflight_checks
    cleanup_environment
    setup_dependencies
    run_health_check

    print_status "🚀 Starting Development Server..."
    echo "---------------------------------"
    print_status "▶️  Launching Flutter web app..."
    echo "🌐 URL: http://localhost:$DEV_PORT"
    echo "🔧 Environment: staging"
    echo "🔑 OAuth Client: staging configuration (via dart-define)"
    echo ""
    
    echo "💡 Available Flutter commands during development:"
    echo "   R - Hot restart"
    echo "   r - Hot reload"  
    echo "   h - List all commands"
    echo "   q - Quit"
    echo ""

    # Start Flutter
    flutter run -d chrome \
        --web-port $DEV_PORT \
        --dart-define=ENVIRONMENT=staging \
        --dart-define=USE_FIREBASE_EMULATORS=false \
        --dart-define=STAGING_CLIENT_ID=$STAGING_CLIENT_ID

    echo ""
    print_success "Development session ended"
}

# Build for testing
build_app() {
    echo ""
    print_status "🔨 Samaan AI - Development Build"
    echo "================================"
    echo ""

    run_preflight_checks

    print_status "🧹 Cleaning and preparing..."
    echo "----------------------------"
    flutter clean > /dev/null 2>&1
    flutter pub get > /dev/null 2>&1
    print_success "Project cleaned and dependencies updated"

    echo ""
    print_status "🔍 Code analysis..."
    echo "------------------"
    if flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings; then
        print_success "Code analysis passed"
    else
        print_warning "Code analysis found style issues, but no fatal errors. Continuing with build..."
    fi

    echo ""
    print_status "🔨 Building for web (staging config)..."
    echo "---------------------------------------"
    
    flutter build web --release \
        --dart-define=ENVIRONMENT=staging \
        --dart-define=STAGING_CLIENT_ID=$STAGING_CLIENT_ID
    
    echo ""
    print_success "Build completed successfully!"
    echo "📁 Output: build/web/"
    echo "🌐 You can serve this locally with: python3 -m http.server 8080 --directory build/web"
    echo ""
}

# Run tests
run_tests() {
    echo ""
    print_status "🧪 Samaan AI - Development Testing Suite"
    echo "========================================"
    echo ""

    run_preflight_checks

    print_status "🧹 Preparing test environment..."
    echo "--------------------------------"
    flutter clean > /dev/null 2>&1
    flutter pub get > /dev/null 2>&1
    print_success "Environment prepared"

    # Static analysis
    echo ""
    print_status "🔍 Static Analysis..."
    echo "--------------------"
    print_status "Running flutter analyze..."
    if flutter analyze --no-pub; then
        print_success "Static analysis passed"
    else
        print_error "Static analysis found issues"
        ANALYSIS_FAILED=true
    fi

    # Code formatting check
    echo ""
    print_status "📐 Code Formatting..."
    echo "--------------------"
    print_status "Checking code formatting..."
    if dart format --set-exit-if-changed . > /dev/null 2>&1; then
        print_success "Code formatting is correct"
    else
        print_warning "Code formatting issues found. Run: ./scripts/dev.sh lint"
        FORMAT_ISSUES=true
    fi

    # Unit tests
    echo ""
    print_status "🧪 Unit Tests..."
    echo "---------------"
    print_status "Running unit tests..."
    if flutter test; then
        print_success "All unit tests passed"
    else
        print_error "Unit tests failed"
        TESTS_FAILED=true
    fi

    # Build test
    echo ""
    print_status "🔨 Build Test..."
    echo "---------------"
    print_status "Testing build process..."
    if flutter build web --release \
        --dart-define=ENVIRONMENT=staging \
        --dart-define=STAGING_CLIENT_ID=$STAGING_CLIENT_ID > /dev/null 2>&1; then
        print_success "Build test passed"
    else
        print_error "Build test failed"
        BUILD_FAILED=true
    fi

    # Summary
    echo ""
    print_status "📊 Test Summary"
    echo "==============="

    if [[ -z $ANALYSIS_FAILED && -z $TESTS_FAILED && -z $BUILD_FAILED ]]; then
        print_success "All tests passed! Your code is ready for deployment."
        exit 0
    else
        print_error "Some issues were found:"
        [[ -n $ANALYSIS_FAILED ]] && echo "   - Static analysis issues"
        [[ -n $FORMAT_ISSUES ]] && echo "   - Code formatting issues"  
        [[ -n $TESTS_FAILED ]] && echo "   - Unit test failures"
        [[ -n $BUILD_FAILED ]] && echo "   - Build issues"
        echo ""
        echo "🔧 Please fix the issues above before deploying."
        exit 1
    fi
}

# Lint and format code
lint_code() {
    echo ""
    print_status "🧹 Samaan AI - Code Linting & Formatting"
    echo "========================================"
    echo ""

    run_preflight_checks

    print_status "📐 Code Formatting..."
    echo "--------------------"
    print_status "Formatting Dart code..."
    dart format .
    print_success "Code formatting completed"

    echo ""
    print_status "🔧 Code Fixes..."
    echo "---------------"
    print_status "Applying automatic fixes..."
    dart fix --apply . 2>/dev/null || true
    print_success "Automatic fixes applied"

    echo ""
    print_status "🔍 Final Analysis..."
    echo "-------------------"
    print_status "Checking for remaining issues..."
    if flutter analyze --no-pub; then
        print_success "No issues found!"
    else
        print_warning "Some issues remain. Please review manually."
    fi

    echo ""
    print_success "Linting and formatting completed!"
    echo "💡 Your code is now properly formatted and organized."
    echo ""
}

# Show help
show_help() {
    echo ""
    print_status "🚀 Samaan AI Development Script"
    echo "==============================="
    echo ""
    echo "Usage: ./scripts/dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start    Start development server with hot reload (default)"
    echo "  build    Build app for local testing"
    echo "  test     Run comprehensive tests and quality checks"  
    echo "  lint     Fix code formatting and style issues"
    echo "  help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/dev.sh              # Start development server"
    echo "  ./scripts/dev.sh start        # Same as above"
    echo "  ./scripts/dev.sh build        # Build for testing"
    echo "  ./scripts/dev.sh test         # Run all tests"
    echo "  ./scripts/dev.sh lint         # Fix formatting"
    echo ""
    echo "📝 Recommended workflow:"
    echo "  1. ./scripts/dev.sh start     # Start development"
    echo "  2. Make your changes"
    echo "  3. ./scripts/dev.sh test      # Test changes" 
    echo "  4. ./scripts/dev.sh lint      # Fix formatting"
    echo "  5. ./scripts/dev.sh build     # Final build test"
    echo "  6. Commit and push"
    echo ""
}

# Main script logic
case "${1:-start}" in
    "start")
        start_server
        ;;
    "build")
        build_app
        ;;
    "test")
        run_tests
        ;;
    "lint") 
        lint_code
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac