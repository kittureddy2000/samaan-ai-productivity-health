#!/usr/bin/env python3
"""
Generate base64-encoded secrets for GitHub Actions for Samaan AI projects.
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
    
    # Samaan AI Staging configuration
    staging_config = {
        "project_info": {
            "project_number": "362525403590",
            "project_id": "samaan-ai-staging-2025",
            "storage_bucket": "samaan-ai-staging-2025.firebasestorage.app"
        },
        "client": [
            {
                "client_info": {
                    "mobilesdk_app_id": "1:362525403590:android:3c8a94a5ceee9942e36ac7",
                    "android_client_info": {
                        "package_name": "com.samaanai.productivityhealth"
                    }
                },
                "oauth_client": [
                    {
                        "client_id": "362525403590-androidclientid.apps.googleusercontent.com",
                        "client_type": 1,
                        "android_info": {
                            "package_name": "com.samaanai.productivityhealth",
                            "certificate_hash": debug_sha1
                        }
                    },
                    {
                        "client_id": "362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com",
                        "client_type": 3
                    }
                ],
                "api_key": [
                    {
                        "current_key": "AIzaSyDngmDDrO8GnMK898Ecy-eRiIFQc_YSs_I"
                    }
                ],
                "services": {
                    "appinvite_service": {
                        "other_platform_oauth_client": [
                            {
                                "client_id": "362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com",
                                "client_type": 3
                            },
                            {
                                "client_id": "362525403590-ehftple3t3mf70uu9gbsusn3j59b4aro.apps.googleusercontent.com",
                                "client_type": 2,
                                "ios_info": {
                                    "bundle_id": "com.samaanai.productivityhealth"
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

def create_production_google_services():
    """Create production google-services.json with production SHA-1."""
    # This would need to be updated with the actual production keystore SHA-1
    production_sha1 = "PRODUCTION_SHA1_PLACEHOLDER"
    
    # Samaan AI Production configuration
    production_config = {
        "project_info": {
            "project_number": "995832123315",
            "project_id": "samaan-ai-production-2025",
            "storage_bucket": "samaan-ai-production-2025.firebasestorage.app"
        },
        "client": [
            {
                "client_info": {
                    "mobilesdk_app_id": "1:995832123315:android:726dd726de26fb1ce585c6",
                    "android_client_info": {
                        "package_name": "com.samaanai.productivityhealth"
                    }
                },
                "oauth_client": [
                    {
                        "client_id": "995832123315-androidclientid.apps.googleusercontent.com",
                        "client_type": 1,
                        "android_info": {
                            "package_name": "com.samaanai.productivityhealth",
                            "certificate_hash": production_sha1
                        }
                    },
                    {
                        "client_id": "995832123315-webclientid.apps.googleusercontent.com",
                        "client_type": 3
                    }
                ],
                "api_key": [
                    {
                        "current_key": "AIzaSyC-W0WnHal4p69e0NLEMfbqX4wulxc527U"
                    }
                ],
                "services": {
                    "appinvite_service": {
                        "other_platform_oauth_client": [
                            {
                                "client_id": "995832123315-webclientid.apps.googleusercontent.com",
                                "client_type": 3
                            },
                            {
                                "client_id": "995832123315-iosclientid.apps.googleusercontent.com",
                                "client_type": 2,
                                "ios_info": {
                                    "bundle_id": "com.samaanai.productivityhealth"
                                }
                            }
                        ]
                    }
                }
            }
        ],
        "configuration_version": "1"
    }
    
    return json.dumps(production_config, indent=2)

def main():
    print("🔧 Generating GitHub Secrets for Samaan AI")
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
    
    # Web client IDs
    print("🌐 WEB CLIENT IDS")
    print("-" * 20)
    print("📋 GOOGLE_CLIENT_ID_STAGING:")
    print("362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com")
    print()
    print("📋 GOOGLE_CLIENT_ID_PRODUCTION:")
    print("995832123315-NEEDTOGETFROMGOOGLECONSOLE.apps.googleusercontent.com")
    print()
    
    # Firebase Token
    print("🔥 FIREBASE TOKEN")
    print("-" * 15)
    print("Run: firebase login:ci")
    print("Then set: FIREBASE_TOKEN secret")
    print()
    
    # Debug keystore
    debug_keystore = os.path.expanduser('~/.android/debug.keystore')
    if os.path.exists(debug_keystore):
        debug_b64 = encode_file_to_base64(debug_keystore)
        if debug_b64:
            print("🔑 DEBUG_KEYSTORE:")
            print(debug_b64)
            print()
    
    # Instructions
    print("📝 INSTRUCTIONS")
    print("-" * 15)
    print("1. Copy the base64 values above")
    print("2. Go to your GitHub repository → Settings → Secrets and variables → Actions")
    print("3. Update/create these secrets:")
    print("   - GOOGLE_SERVICES_STAGING (use the generated value above)")
    print("   - GOOGLE_CLIENT_ID_STAGING (already set)")
    print("   - GOOGLE_CLIENT_ID_PRODUCTION (need to get from Google Console)")
    print("   - FIREBASE_TOKEN (run firebase login:ci)")
    print("   - DEBUG_KEYSTORE (use the generated value above)")
    print()
    print("4. For Android OAuth to work, you need to:")
    print("   - Go to Google Cloud Console")
    print("   - Configure OAuth clients for Android apps")
    print("   - Use the SHA-1 fingerprint from your debug keystore")
    print()
    print("✅ Done! Your staging builds should now work correctly.")

if __name__ == "__main__":
    main()