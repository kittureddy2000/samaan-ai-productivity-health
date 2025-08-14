#!/bin/bash

echo "🚀 Starting Local Firebase + Flutter Testing Environment"
echo "================================================="

# Check if Firebase emulators are running
if ! curl -s http://localhost:4000/ > /dev/null; then
    echo "❌ Firebase emulators not running!"
    echo "👉 Please run: firebase emulators:start --only functions,firestore,auth"
    exit 1
fi

echo "✅ Firebase emulators detected"

# Build Flutter web with emulator configuration
echo "🔨 Building Flutter web for local testing..."
flutter build web --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=ENVIRONMENT=development

# Start a local web server
echo "🌐 Starting local web server..."
echo "📱 Your app will be available at: http://localhost:3000"
echo "🔧 Firebase Emulator UI: http://localhost:4000"
echo "📊 Functions: http://localhost:5001"
echo "🗄️  Firestore: http://localhost:8080"
echo "🔐 Auth: http://localhost:9099"
echo ""
echo "Press Ctrl+C to stop the server"

cd build/web && python3 -m http.server 3000