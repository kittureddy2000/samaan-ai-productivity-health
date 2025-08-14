#!/usr/bin/env python3
"""
Generate base64-encoded secrets for GitHub Actions from local configurations.
This script helps ensure your GitHub secrets match your local setup.
"""

import json
import base64
import subprocess
import os
import sys

def encode_file_to_base64(file_path):
    """Encode a file to base64."""
    try:
        with open(file_path, 'rb') as f:
            content = f.read()
        return base64.b64encode(content).decode('utf-8')
    except Exception as e:
        print(f"❌ Error encoding {file_path}: {e}")
        return None

def get_debug_keystore_sha1():
    """Get SHA-1 fingerprint from debug keystore."""
    try:
        debug_keystore = os.path.expanduser('~/.android/debug.keystore')
        result = subprocess.run([
            'keytool', '-list', '-v', 
            '-keystore', debug_keystore,
            '-alias', 'androiddebugkey',
            '-storepass', 'android',
            '-keypass', 'android'
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            return None
            
        for line in result.stdout.split('\n'):
            if 'SHA1:' in line:
                sha1 = line.split('SHA1:')[1].strip()
                return sha1.replace(':', '').lower()
        return None
    except Exception as e:
        print(f"❌ Error getting debug keystore SHA-1: {e}")
        return None

def create_staging_google_services():
    """Create staging google-services.json with correct debug SHA-1."""
    debug_sha1 = get_debug_keystore_sha1()
    if not debug_sha1:
        print("❌ Could not get debug keystore SHA-1")
        return None
    
    print(f"✅ Debug keystore SHA-1: {debug_sha1}")
    
    # Staging configuration template
    staging_config = {
        "project_info": {
            "project_number": "763348902456",
            "project_id": "fitness-tracker-8d0ae",
            "storage_bucket": "fitness-tracker-8d0ae.firebasestorage.app"
        },
        "client": [
            {
                "client_info": {
                    "mobilesdk_app_id": "1:763348902456:android:536b977f3ec075131ebccd",
                    "android_client_info": {
                        "package_name": "com.fitnesstracker.fitness_tracker"
                    }
                },
                "oauth_client": [
                    {
                        "client_id": "763348902456-b2ga4vrkv25ecap115hmr8qdh3jk1q73.apps.googleusercontent.com",
                        "client_type": 1,
                        "android_info": {
                            "package_name": "com.fitnesstracker.fitness_tracker",
                            "certificate_hash": debug_sha1
                        }
                    },
                    {
                        "client_id": "763348902456-l7kcl7qerssghmid1bmc5n53oq2v62ic.apps.googleusercontent.com",
                        "client_type": 3
                    }
                ],
                "api_key": [
                    {
                        "current_key": "AIzaSyAhBC9FUOX02Kj3HBIAmwFOmi9cNFqRR5A"
                    }
                ],
                "services": {
                    "appinvite_service": {
                        "other_platform_oauth_client": [
                            {
                                "client_id": "763348902456-l7kcl7qerssghmid1bmc5n53oq2v62ic.apps.googleusercontent.com",
                                "client_type": 3
                            },
                            {
                                "client_id": "763348902456-0i87a8u03t7hem08ih5t387sg8qng1fu.apps.googleusercontent.com",
                                "client_type": 2,
                                "ios_info": {
                                    "bundle_id": "com.fitnesstracker.fitnessTracker"
                                }
                            }
                        ]
                    }
                }
            }
        ],
        "configuration_version": "1"
    }
    
    return json.dumps(staging_config, indent=2)

def main():
    print("🔧 Generating GitHub Secrets for Fitness Tracker")
    print("=" * 50)
    
    # Generate staging google-services.json
    print("\n📱 ANDROID CONFIGURATIONS")
    print("-" * 30)
    
    staging_json = create_staging_google_services()
    if staging_json:
        staging_b64 = base64.b64encode(staging_json.encode()).decode()
        print("✅ Generated staging google-services.json")
        print(f"📋 GOOGLE_SERVICES_STAGING secret:")
        print(staging_b64)
        print()
    else:
        print("❌ Failed to generate staging configuration")
        sys.exit(1)
    
    # Check if current google-services.json exists for production reference
    if os.path.exists('android/app/google-services.json'):
        current_b64 = encode_file_to_base64('android/app/google-services.json')
        if current_b64:
            print("📋 Current google-services.json (as reference):")
            print(current_b64)
            print()
    
    # Web client IDs
    print("🌐 WEB CLIENT IDS")
    print("-" * 20)
    print("📋 GOOGLE_CLIENT_ID_STAGING:")
    print("763348902456-l7kcl7qerssghmid1bmc5n53oq2v62ic.apps.googleusercontent.com")
    print()
    print("📋 GOOGLE_CLIENT_ID_PRODUCTION:")
    print("934862983900-e42cifg34olqbd4u9cqtkvmcfips46fg.apps.googleusercontent.com")
    print()
    
    # Instructions
    print("📝 INSTRUCTIONS")
    print("-" * 15)
    print("1. Copy the base64 values above")
    print("2. Go to your GitHub repository → Settings → Secrets and variables → Actions")
    print("3. Update/create these secrets:")
    print("   - GOOGLE_SERVICES_STAGING (use the generated value above)")
    print("   - GOOGLE_CLIENT_ID_STAGING (use staging web client ID)")
    print("   - GOOGLE_CLIENT_ID_PRODUCTION (use production web client ID)")
    print("   - GOOGLE_SERVICES_PROD (for production - you'll need to generate this separately)")
    print()
    print("4. For production, you'll also need:")
    print("   - ANDROID_RELEASE_KEYSTORE (your production keystore as base64)")
    print("   - ANDROID_RELEASE_KEYSTORE_PASSWORD")
    print("   - ANDROID_RELEASE_KEY_PASSWORD")
    print("   - ANDROID_RELEASE_KEY_ALIAS")
    print("   - FIREBASE_TOKEN (Firebase CI token)")
    print()
    print("✅ Done! Your staging builds should now work correctly.")

if __name__ == "__main__":
    main()