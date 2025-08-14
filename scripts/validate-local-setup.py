#!/usr/bin/env python3
"""
Local validation script to check your setup before pushing to GitHub.
This script validates your local configuration and suggests what to check in GitHub secrets.
"""

import json
import subprocess
import os
import sys
import base64

def check_file_exists(file_path, description):
    """Check if a file exists."""
    if os.path.exists(file_path):
        print(f"✅ {description}: {file_path}")
        return True
    else:
        print(f"❌ {description} NOT FOUND: {file_path}")
        return False

def validate_json_file(file_path, description):
    """Validate a JSON file."""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        print(f"✅ {description} is valid JSON")
        return data
    except Exception as e:
        print(f"❌ {description} is invalid JSON: {e}")
        return None

def get_keystore_sha1(keystore_path, alias, store_pass, key_pass):
    """Get SHA-1 fingerprint from keystore."""
    try:
        result = subprocess.run([
            'keytool', '-list', '-v',
            '-keystore', keystore_path,
            '-alias', alias,
            '-storepass', store_pass,
            '-keypass', key_pass
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            return None
            
        for line in result.stdout.split('\n'):
            if 'SHA1:' in line:
                sha1 = line.split('SHA1:')[1].strip()
                return sha1.replace(':', '').lower()
        return None
    except Exception as e:
        print(f"Error getting SHA-1: {e}")
        return None

def main():
    print("🔍 Local Configuration Validation")
    print("=" * 50)
    
    all_good = True
    
    # Check staging google-services.json
    print("\n📱 ANDROID CONFIGURATION")
    print("-" * 30)
    
    staging_json_path = "android/app/google-services.json"
    if check_file_exists(staging_json_path, "Staging google-services.json"):
        staging_data = validate_json_file(staging_json_path, "Staging google-services.json")
        
        if staging_data:
            project_id = staging_data['project_info']['project_id']
            print(f"✅ Staging Project ID: {project_id}")
            
            if project_id != "fitness-tracker-8d0ae":
                print(f"⚠️  Expected staging project: fitness-tracker-8d0ae, got: {project_id}")
                all_good = False
            
            # Check Android OAuth client
            client = staging_data['client'][0]
            oauth_clients = client['oauth_client']
            android_client = next((c for c in oauth_clients if c['client_type'] == 1), None)
            
            if android_client:
                package_name = android_client['android_info']['package_name']
                cert_hash = android_client['android_info']['certificate_hash']
                
                print(f"✅ Package Name: {package_name}")
                print(f"✅ Certificate Hash in JSON: {cert_hash}")
                
                # Check debug keystore SHA-1
                debug_keystore = os.path.expanduser('~/.android/debug.keystore')
                debug_sha1 = get_keystore_sha1(debug_keystore, 'androiddebugkey', 'android', 'android')
                
                if debug_sha1:
                    print(f"✅ Debug Keystore SHA-1: {debug_sha1}")
                    
                    if debug_sha1 == cert_hash:
                        print("✅ SHA-1 fingerprints MATCH! (staging is correct)")
                    else:
                        print("❌ SHA-1 fingerprints DO NOT MATCH!")
                        print(f"   JSON has: {cert_hash}")
                        print(f"   Debug keystore has: {debug_sha1}")
                        all_good = False
                else:
                    print("⚠️  Could not get debug keystore SHA-1")
    else:
        all_good = False
    
    # Check production keystore
    print("\n🔐 PRODUCTION KEYSTORE")
    print("-" * 25)
    
    prod_keystore_paths = [
        "android/app/fitness-tracker-production.jks",
        "android/app/production-keystore.jks"
    ]
    
    prod_keystore_found = False
    for path in prod_keystore_paths:
        if os.path.exists(path):
            print(f"✅ Production keystore found: {path}")
            prod_keystore_found = True
            
            # Try to get SHA-1 (will prompt for passwords)
            print("🔍 To get production SHA-1, run:")
            print(f"   keytool -list -v -keystore {path} -alias fitness-tracker-key")
            break
    
    if not prod_keystore_found:
        print("❌ No production keystore found")
        print("   Expected locations:")
        for path in prod_keystore_paths:
            print(f"   - {path}")
        print("🔧 Run: ./scripts/create-production-keystore.sh")
        all_good = False
    
    # Check web index.html
    print("\n🌐 WEB CONFIGURATION")
    print("-" * 20)
    
    web_index_path = "web/index.html"
    if check_file_exists(web_index_path, "Web index.html"):
        with open(web_index_path, 'r') as f:
            content = f.read()
        
        if '{{GOOGLE_CLIENT_ID}}' in content:
            print("⚠️  Web index.html still has placeholder {{GOOGLE_CLIENT_ID}}")
            print("   This is OK - GitHub Actions will replace it")
        elif 'apps.googleusercontent.com' in content:
            print("✅ Web index.html has Google Client ID configured")
        else:
            print("❌ Web index.html missing Google Client ID")
            all_good = False
    else:
        all_good = False
    
    # Generate base64 examples
    print("\n📋 GITHUB SECRETS TO CREATE")
    print("-" * 30)
    
    print("Based on your local files, create these GitHub secrets:")
    print()
    
    # Staging google-services.json
    if os.path.exists(staging_json_path):
        try:
            with open(staging_json_path, 'rb') as f:
                staging_b64 = base64.b64encode(f.read()).decode()
            print("🔐 GOOGLE_SERVICES_STAGING:")
            print(f"   {staging_b64[:50]}... (truncated)")
            print()
        except:
            pass
    
    # Web client IDs
    print("🌐 GOOGLE_CLIENT_ID_STAGING:")
    print("   763348902456-l7kcl7qerssghmid1bmc5n53oq2v62ic.apps.googleusercontent.com")
    print()
    print("🌐 GOOGLE_CLIENT_ID_PRODUCTION:")
    print("   934862983900-e42cifg34olqbd4u9cqtkvmcfips46fg.apps.googleusercontent.com")
    print()
    
    # Production keystore
    if prod_keystore_found:
        print("🔐 ANDROID_RELEASE_KEYSTORE:")
        print("   [Run: base64 -i android/app/your-keystore.jks]")
        print()
        print("🔑 ANDROID_RELEASE_KEYSTORE_PASSWORD:")
        print("   [Your keystore password]")
        print()
        print("🔑 ANDROID_RELEASE_KEY_PASSWORD:")
        print("   [Your key password]")
        print()
        print("🔑 ANDROID_RELEASE_KEY_ALIAS:")
        print("   fitness-tracker-key")
        print()
    
    print("🔥 FIREBASE_TOKEN:")
    print("   [Run: firebase login:ci]")
    print()
    
    # Summary
    print("📊 VALIDATION SUMMARY")
    print("-" * 20)
    
    if all_good:
        print("✅ Local configuration looks good!")
        print("📤 Next steps:")
        print("   1. Add all secrets to GitHub (see above)")
        print("   2. Test workflows by pushing to GitHub")
    else:
        print("❌ Issues found in local configuration")
        print("🔧 Fix the issues above before setting up GitHub secrets")
    
    return 0 if all_good else 1

if __name__ == "__main__":
    sys.exit(main())