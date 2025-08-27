#!/bin/bash

# Get SHA-1 fingerprint from production keystore
# Usage: ./scripts/get-production-sha1.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Getting Production Keystore SHA-1 Fingerprint${NC}"
echo "=================================================="

# Check if production keystore exists
if [ ! -f "android/app/production-keystore.jks" ]; then
    echo -e "${RED}❌ ERROR: Production keystore not found at android/app/production-keystore.jks${NC}"
    echo "Available keystores:"
    ls -la android/app/*.jks 2>/dev/null || echo "No .jks files found"
    exit 1
fi

# Check if key properties file exists
if [ ! -f "android/key-production.properties" ]; then
    echo -e "${RED}❌ ERROR: Production key properties not found at android/key-production.properties${NC}"
    exit 1
fi

# Read keystore properties
echo -e "${YELLOW}📋 Reading keystore properties...${NC}"
source android/key-production.properties

# Get SHA-1 fingerprint
echo -e "${YELLOW}🔑 Extracting SHA-1 fingerprint...${NC}"
SHA1_OUTPUT=$(keytool -list -v -keystore "android/app/$storeFile" -alias "$keyAlias" -storepass "$storePassword" -keypass "$keyPassword" 2>/dev/null | grep "SHA1:")

if [ -z "$SHA1_OUTPUT" ]; then
    echo -e "${RED}❌ ERROR: Could not extract SHA-1 fingerprint${NC}"
    echo "Please check keystore credentials in android/key-production.properties"
    exit 1
fi

# Extract and clean SHA-1
SHA1_RAW=$(echo "$SHA1_OUTPUT" | sed 's/.*SHA1: //' | tr -d ' ')
SHA1_CLEAN=$(echo "$SHA1_RAW" | tr -d ':' | tr '[:upper:]' '[:lower:]')

echo -e "${GREEN}✅ SUCCESS: Production keystore SHA-1 extracted${NC}"
echo ""
echo -e "${BLUE}📋 KEYSTORE INFORMATION:${NC}"
echo "  Keystore: android/app/$storeFile"
echo "  Alias: $keyAlias"
echo "  SHA-1 (formatted): $SHA1_RAW"
echo "  SHA-1 (clean): $SHA1_CLEAN"
echo ""

# Check for staging conflict
STAGING_SHA1="53315440bd500648d1034bdf6fa462fce03775fa"
if [ "$SHA1_CLEAN" = "$STAGING_SHA1" ]; then
    echo -e "${RED}⚠️  WARNING: SHA-1 CONFLICT DETECTED!${NC}"
    echo "  Production SHA-1 matches staging SHA-1: $STAGING_SHA1"
    echo "  This will cause Firebase authentication conflicts."
    echo ""
    echo -e "${YELLOW}🔧 SOLUTION:${NC}"
    echo "  1. Generate a new production keystore with different credentials"
    echo "  2. OR use a different existing keystore for production"
    echo ""
else
    echo -e "${GREEN}✅ NO CONFLICT: Production SHA-1 is different from staging${NC}"
    echo ""
fi

echo -e "${BLUE}🔧 NEXT STEPS:${NC}"
echo "1. Copy this SHA-1 fingerprint: ${YELLOW}$SHA1_CLEAN${NC}"
echo "2. Go to Firebase Console: https://console.firebase.google.com"
echo "3. Select project: ${YELLOW}samaan-ai-production-2025${NC}"
echo "4. Go to: Authentication > Sign-in method > Google > Web SDK configuration"
echo "5. Update the SHA-1 fingerprint for package: ${YELLOW}com.samaanai.productivityhealth.prod${NC}"
echo ""
echo -e "${YELLOW}📋 Copy this for Firebase:${NC}"
echo "Package name: com.samaanai.productivityhealth.prod"
echo "SHA-1: $SHA1_CLEAN"