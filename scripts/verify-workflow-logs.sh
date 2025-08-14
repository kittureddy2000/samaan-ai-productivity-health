#!/bin/bash

echo "🔍 Verifying GitHub Actions Workflow Configuration"
echo "=================================================="

echo ""
echo "✅ Checking if workflows have been updated..."

# Check if preproduction.yml has the DEBUG_KEYSTORE
if grep -q "DEBUG_KEYSTORE" .github/workflows/preproduction.yml; then
    echo "✅ preproduction.yml: DEBUG_KEYSTORE found"
else
    echo "❌ preproduction.yml: DEBUG_KEYSTORE NOT found"
fi

# Check if preview.yml has the DEBUG_KEYSTORE  
if grep -q "DEBUG_KEYSTORE" .github/workflows/preview.yml; then
    echo "✅ preview.yml: DEBUG_KEYSTORE found"
else
    echo "❌ preview.yml: DEBUG_KEYSTORE NOT found"
fi

# Check if validate-configuration.yml has the DEBUG_KEYSTORE validation
if grep -q "DEBUG_KEYSTORE" .github/workflows/validate-configuration.yml; then
    echo "✅ validate-configuration.yml: DEBUG_KEYSTORE validation found"
else
    echo "❌ validate-configuration.yml: DEBUG_KEYSTORE validation NOT found"
fi

echo ""
echo "📋 Required GitHub Secrets:"
echo "1. FIREBASE_TOKEN"
echo "2. GOOGLE_SERVICES_STAGING" 
echo "3. GOOGLE_SERVICES_PROD"
echo "4. GOOGLE_CLIENT_ID_STAGING"
echo "5. GOOGLE_CLIENT_ID_PRODUCTION"
echo "6. DEBUG_KEYSTORE ⭐ (NEW - this should fix the issue)"
echo "7. ANDROID_RELEASE_KEYSTORE"
echo "8. ANDROID_RELEASE_KEYSTORE_PASSWORD"
echo "9. ANDROID_RELEASE_KEY_PASSWORD"
echo "10. ANDROID_RELEASE_KEY_ALIAS"

echo ""
echo "🔧 To debug the APK you downloaded:"
echo "1. Download the APK from GitHub Actions artifacts"
echo "2. Run: python3 scripts/debug-apk-signing.py /path/to/downloaded/app-debug.apk"
echo "3. Check if the SHA-1 matches: 53315440bd500648d1034bdf6fa462fce03775fa"

echo ""
echo "🚨 If the issue persists, check:"
echo "1. Did you add the DEBUG_KEYSTORE secret to GitHub?"
echo "2. Was the workflow run AFTER adding the secret?"
echo "3. Does the APK SHA-1 match the expected SHA-1?"
echo "4. Is the Firebase project configuration correct?"

echo ""
echo "📱 Current local configuration:"
echo "Package: com.fitnesstracker.fitness_tracker"
echo "Firebase Project (staging): fitness-tracker-8d0ae"  
echo "Expected SHA-1: 53315440bd500648d1034bdf6fa462fce03775fa"