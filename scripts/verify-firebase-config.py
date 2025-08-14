#!/usr/bin/env python3
"""
Verify Firebase configuration matches APK configuration.
This script helps identify mismatches between APK and Firebase Console.
"""

import json
import sys

def analyze_google_services_json(file_path):
    """Analyze google-services.json configuration."""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        print(f"📋 Analyzing: {file_path}")
        print("=" * 60)
        
        # Project info
        project_info = data['project_info']
        print(f"🔥 Firebase Project ID: {project_info['project_id']}")
        print(f"🔢 Project Number: {project_info['project_number']}")
        
        # Client info
        client = data['client'][0]
        client_info = client['client_info']
        print(f"📱 App ID: {client_info['mobilesdk_app_id']}")
        print(f"📦 Package Name: {client_info['android_client_info']['package_name']}")
        
        # OAuth clients
        oauth_clients = client['oauth_client']
        android_clients = [c for c in oauth_clients if c['client_type'] == 1]
        web_clients = [c for c in oauth_clients if c['client_type'] == 3]
        
        if android_clients:
            android_client = android_clients[0]
            print(f"🤖 Android OAuth Client ID: {android_client['client_id']}")
            if 'android_info' in android_client:
                android_info = android_client['android_info']
                print(f"🔐 Registered SHA-1: {android_info['certificate_hash']}")
                print(f"📦 Registered Package: {android_info['package_name']}")
        
        if web_clients:
            web_client = web_clients[0]
            print(f"🌐 Web OAuth Client ID: {web_client['client_id']}")
        
        return data
        
    except Exception as e:
        print(f"❌ Error analyzing {file_path}: {e}")
        return None

def verify_configuration():
    """Verify the current configuration."""
    print("🔍 Firebase Configuration Verification")
    print("=" * 60)
    
    # Expected values
    expected_package = "com.fitnesstracker.fitness_tracker"
    expected_sha1 = "53315440bd500648d1034bdf6fa462fce03775fa"
    expected_project_staging = "fitness-tracker-8d0ae"
    expected_project_prod = "fitness-tracker-p2025"
    
    print("\n🎯 Expected Values:")
    print(f"📦 Package Name: {expected_package}")
    print(f"🔐 Debug SHA-1: {expected_sha1}")
    print(f"🔥 Staging Project: {expected_project_staging}")
    print(f"🔥 Production Project: {expected_project_prod}")
    
    # Analyze local google-services.json
    print("\n" + "=" * 60)
    local_file = "android/app/google-services.json"
    local_config = analyze_google_services_json(local_file)
    
    if local_config:
        project_id = local_config['project_info']['project_id']
        client = local_config['client'][0]
        package_name = client['client_info']['android_client_info']['package_name']
        
        oauth_clients = client['oauth_client']
        android_client = next((c for c in oauth_clients if c['client_type'] == 1), None)
        
        if android_client and 'android_info' in android_client:
            cert_hash = android_client['android_info']['certificate_hash']
            
            print(f"\n✅ Configuration Check:")
            print(f"   Project ID: {'✅' if project_id == expected_project_staging else '❌'} {project_id}")
            print(f"   Package Name: {'✅' if package_name == expected_package else '❌'} {package_name}")
            print(f"   SHA-1 Hash: {'✅' if cert_hash == expected_sha1 else '❌'} {cert_hash}")
            
            if project_id == expected_project_staging and package_name == expected_package and cert_hash == expected_sha1:
                print("\n🎉 Local configuration is PERFECT!")
            else:
                print("\n❌ Local configuration has issues!")
        
    print(f"\n🔧 Firebase Console Checklist:")
    print(f"1. Go to: https://console.firebase.google.com/project/{expected_project_staging}/settings/general")
    print(f"2. Under 'Your apps', find Android app with package: {expected_package}")
    print(f"3. Verify SHA-1 fingerprint is registered: {expected_sha1.upper()}")
    print(f"4. Go to: https://console.firebase.google.com/project/{expected_project_staging}/authentication/providers")
    print(f"5. Ensure Google sign-in is ENABLED")
    
    print(f"\n📱 To check APK configuration:")
    print(f"python3 scripts/debug-apk-signing.py /path/to/your/app-debug.apk")

if __name__ == "__main__":
    verify_configuration()