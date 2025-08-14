#!/bin/bash

# Script to create a production keystore for Android app signing
# Run this script to generate your production keystore

echo "🔐 Creating Production Keystore for Fitness Tracker"
echo "=================================================="
echo ""

# Set keystore details
KEYSTORE_NAME="fitness-tracker-production.jks"
KEY_ALIAS="fitness-tracker-key"
VALIDITY_YEARS=25

echo "This script will create a production keystore with the following details:"
echo "📁 Keystore file: $KEYSTORE_NAME"
echo "🔑 Key alias: $KEY_ALIAS"
echo "📅 Validity: $VALIDITY_YEARS years"
echo ""

read -p "Do you want to continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    exit 1
fi

echo ""
echo "🔧 Generating keystore..."
echo "You will be prompted to enter passwords and certificate details."
echo ""

# Generate the keystore
keytool -genkey -v \
    -keystore android/app/$KEYSTORE_NAME \
    -alias $KEY_ALIAS \
    -keyalg RSA \
    -keysize 2048 \
    -validity $((VALIDITY_YEARS * 365)) \
    -storetype JKS

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Production keystore created successfully!"
    echo "📁 Location: android/app/$KEYSTORE_NAME"
    echo ""
    echo "🔒 IMPORTANT SECURITY NOTES:"
    echo "1. Keep the keystore file and passwords SECURE"
    echo "2. Back up the keystore file - if you lose it, you can't update your app"
    echo "3. Never commit the keystore file to git"
    echo ""
    echo "📋 Next steps:"
    echo "1. Note down your keystore password and key password"
    echo "2. Get the SHA-1 fingerprint: keytool -list -v -keystore android/app/$KEYSTORE_NAME -alias $KEY_ALIAS"
    echo "3. Add the SHA-1 to your Firebase production project"
    echo "4. Encode keystore for GitHub secrets: base64 -i android/app/$KEYSTORE_NAME"
    echo ""
    
    # Add to .gitignore if not already there
    if ! grep -q "*.jks" .gitignore 2>/dev/null; then
        echo "*.jks" >> .gitignore
        echo "🔒 Added *.jks to .gitignore for security"
    fi
    
else
    echo "❌ Failed to create keystore"
    exit 1
fi