#!/usr/bin/env python3
"""
Debug production OAuth configuration issues.
"""

import json
import base64
import os
import sys

def check_production_secrets():
    """Check if production secrets are configured correctly."""
    print("🔍 Production OAuth Configuration Debugger")
    print("=" * 60)
    
    # Check if this is a GitHub Actions environment
    if os.getenv('GITHUB_ACTIONS'):
        print("✅ Running in GitHub Actions environment")
        
        # Check secrets (they won't show actual values in logs)
        secrets_to_check = [
            'GOOGLE_CLIENT_ID_PRODUCTION',
            'GOOGLE_SERVICES_PROD',
            'FIREBASE_TOKEN'
        ]
        
        for secret in secrets_to_check:
            value = os.getenv(secret, '')
            if value:
                print(f"✅ {secret}: Present (length: {len(value)})")
            else:
                print(f"❌ {secret}: Missing or empty")
                
        # Try to decode and check GOOGLE_SERVICES_PROD
        google_services = os.getenv('GOOGLE_SERVICES_PROD', '')
        if google_services:
            try:
                decoded = base64.b64decode(google_services).decode('utf-8')
                config = json.loads(decoded)
                
                project_id = config.get('project_info', {}).get('project_id', 'Unknown')
                project_number = config.get('project_info', {}).get('project_number', 'Unknown')
                
                print(f"🔥 GOOGLE_SERVICES_PROD Project ID: {project_id}")
                print(f"🔢 Project Number: {project_number}")
                
                # Check if it's the correct production project
                if project_id == 'fitness-tracker-p2025':
                    print("✅ Using PRODUCTION project (fitness-tracker-p2025)")
                elif project_id == 'fitness-tracker-8d0ae':
                    print("❌ ERROR: Using STAGING project (fitness-tracker-8d0ae) in production!")
                else:
                    print(f"⚠️  WARNING: Unknown project ID: {project_id}")
                    
                # Check Android app configuration
                android_info = config.get('client', [{}])[0].get('android_info', {})
                package_name = android_info.get('package_name', 'Unknown')
                cert_hash = android_info.get('certificate_hash', 'Unknown')
                
                print(f"📦 Package Name: {package_name}")
                print(f"🔐 SHA-1 Hash: {cert_hash}")
                
                # Check if SHA-1 matches production keystore
                expected_production_sha1 = "f5:99:a8:35:df:89:c5:02:48:b4:d7:bf:60:7d:d9:62:12:f1:58:3d"
                if cert_hash.lower().replace(':', '') == expected_production_sha1.lower().replace(':', ''):
                    print("✅ SHA-1 matches production keystore")
                else:
                    print(f"❌ SHA-1 mismatch! Expected: {expected_production_sha1}")
                    
                # Check OAuth client IDs
                oauth_clients = config.get('client', [{}])[0].get('oauth_client', [])
                web_client_id = None
                
                for client in oauth_clients:
                    client_type = client.get('client_type', 0)
                    client_id = client.get('client_id', '')
                    
                    if client_type == 3:  # Web client
                        web_client_id = client_id
                        print(f"🌐 Web OAuth Client ID: {client_id}")
                        break
                        
                if not web_client_id:
                    print("❌ No Web OAuth client found in google-services.json")
                    
                # Compare with GOOGLE_CLIENT_ID_PRODUCTION
                production_client_id = os.getenv('GOOGLE_CLIENT_ID_PRODUCTION', '')
                if production_client_id:
                    if production_client_id == web_client_id:
                        print("✅ GOOGLE_CLIENT_ID_PRODUCTION matches google-services.json")
                    else:
                        print("❌ GOOGLE_CLIENT_ID_PRODUCTION mismatch!")
                        print(f"   Secret: {production_client_id}")
                        print(f"   JSON:   {web_client_id}")
                        
            except Exception as e:
                print(f"❌ Error decoding GOOGLE_SERVICES_PROD: {e}")
        
    else:
        print("ℹ️  Not running in GitHub Actions - cannot check secrets")
        
    print("\n🔧 Troubleshooting Steps:")
    print("1. Verify Firebase Console → Authentication → Google is enabled")
    print("2. Check that GOOGLE_CLIENT_ID_PRODUCTION matches Firebase Web client ID")
    print("3. Ensure GOOGLE_SERVICES_PROD is from the PRODUCTION project")
    print("4. Verify production project has Android app with correct SHA-1")

if __name__ == "__main__":
    check_production_secrets()