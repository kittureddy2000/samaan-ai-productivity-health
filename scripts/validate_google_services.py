#!/usr/bin/env python3
"""
Validate google-services.json configuration against debug keystore.
This script helps identify configuration mismatches that cause ApiException: 10.
"""

import json
import subprocess
import sys
import os

def get_debug_keystore_sha1():
    """Get SHA-1 fingerprint from debug keystore."""
    try:
        # Path to debug keystore
        debug_keystore = os.path.expanduser('~/.android/debug.keystore')
        
        # Run keytool to get certificate info
        result = subprocess.run([
            'keytool', '-list', '-v', 
            '-keystore', debug_keystore,
            '-alias', 'androiddebugkey',
            '-storepass', 'android',
            '-keypass', 'android'
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            return None
            
        # Parse SHA1 from output
        for line in result.stdout.split('\n'):
            if 'SHA1:' in line:
                sha1 = line.split('SHA1:')[1].strip()
                return sha1.replace(':', '').lower()
        return None
    except Exception as e:
        print(f"Error getting debug keystore SHA-1: {e}")
        return None

def validate_google_services(file_path):
    """Validate google-services.json configuration."""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        project_id = data['project_info']['project_id']
        project_number = data['project_info']['project_number']
        
        print(f"✓ Project ID: {project_id}")
        print(f"✓ Project Number: {project_number}")
        
        # Check client configuration
        client = data['client'][0]
        app_id = client['client_info']['mobilesdk_app_id']
        package_name = client['client_info']['android_client_info']['package_name']
        
        print(f"✓ App ID: {app_id}")
        print(f"✓ Package Name: {package_name}")
        
        # Check OAuth clients
        oauth_clients = client['oauth_client']
        android_clients = [c for c in oauth_clients if c['client_type'] == 1]
        
        if not android_clients:
            print("✗ No Android OAuth client found!")
            return False
            
        android_client = android_clients[0]
        client_id = android_client['client_id']
        configured_package = android_client['android_info']['package_name']
        configured_sha1 = android_client['android_info']['certificate_hash']
        
        print(f"✓ Android OAuth Client ID: {client_id}")
        print(f"✓ Configured Package: {configured_package}")
        print(f"✓ Configured SHA-1: {configured_sha1}")
        
        # Get actual debug keystore SHA-1
        actual_sha1 = get_debug_keystore_sha1()
        if actual_sha1:
            print(f"✓ Debug Keystore SHA-1: {actual_sha1}")
            
            if actual_sha1 == configured_sha1:
                print("✅ SHA-1 fingerprints match!")
                return True
            else:
                print("❌ SHA-1 fingerprints DO NOT match!")
                print(f"Expected: {configured_sha1}")
                print(f"Actual:   {actual_sha1}")
                return False
        else:
            print("⚠️  Could not retrieve debug keystore SHA-1")
            return None
            
    except Exception as e:
        print(f"✗ Error validating google-services.json: {e}")
        return False

if __name__ == "__main__":
    file_path = sys.argv[1] if len(sys.argv) > 1 else "android/app/google-services.json"
    
    print(f"Validating {file_path}...")
    print("=" * 50)
    
    result = validate_google_services(file_path)
    
    if result is True:
        print("\n✅ Configuration is valid!")
        sys.exit(0)
    elif result is False:
        print("\n❌ Configuration has issues!")
        sys.exit(1)
    else:
        print("\n⚠️  Could not fully validate configuration")
        sys.exit(2)