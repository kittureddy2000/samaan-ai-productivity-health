#!/usr/bin/env python3
"""
Firebase configuration validation script for CI/CD
Compares android/app/google-services.json with lib/firebase_options.dart
"""

import json
import re
import sys

def main():
    print('🔍 Validating Firebase Android configuration consistency...')

    # Extract values from google-services.json
    try:
        with open('android/app/google-services.json', 'r') as f:
            google_services = json.load(f)

        json_app_id = google_services['client'][0]['client_info']['mobilesdk_app_id']
        json_api_key = google_services['client'][0]['api_key'][0]['current_key']
        json_project_id = google_services['project_info']['project_id']
        json_storage_bucket = google_services['project_info']['storage_bucket']
    except Exception as e:
        print(f'❌ Failed to read google-services.json: {e}')
        sys.exit(1)

    # Extract values from firebase_options.dart
    try:
        with open('lib/firebase_options.dart', 'r') as f:
            content = f.read()

        android_block = re.search(r'static const FirebaseOptions android = FirebaseOptions\((.*?)\);', content, re.DOTALL)
        if not android_block:
            print('❌ Could not find Android FirebaseOptions block')
            sys.exit(1)

        block_content = android_block.group(1)

        # Extract individual values with more robust regex
        dart_api_key_match = re.search(r"apiKey:\s*'([^']*)'", block_content)
        dart_app_id_match = re.search(r"appId:\s*'([^']*)'", block_content)
        dart_project_id_match = re.search(r"projectId:\s*'([^']*)'", block_content)
        dart_storage_bucket_match = re.search(r"storageBucket:\s*'([^']*)'", block_content)

        dart_api_key = dart_api_key_match.group(1) if dart_api_key_match else ''
        dart_app_id = dart_app_id_match.group(1) if dart_app_id_match else ''
        dart_project_id = dart_project_id_match.group(1) if dart_project_id_match else ''
        dart_storage_bucket = dart_storage_bucket_match.group(1) if dart_storage_bucket_match else ''
    except Exception as e:
        print(f'❌ Failed to read firebase_options.dart: {e}')
        sys.exit(1)

    # Display comparison results
    print(f'🔍 Comparison Results:')
    print(f'APP_ID:        JSON={json_app_id} | DART={dart_app_id}')
    print(f'API_KEY:       JSON={json_api_key[:10]}*** | DART={dart_api_key[:10]}***')
    print(f'PROJECT_ID:    JSON={json_project_id} | DART={dart_project_id}')
    print(f'STORAGE_BUCKET: JSON={json_storage_bucket} | DART={dart_storage_bucket}')

    # Validation checks
    validation_failed = False

    if json_app_id != dart_app_id:
        print('❌ APP_ID mismatch!')
        validation_failed = True

    if json_api_key != dart_api_key:
        print('❌ API_KEY mismatch!')
        validation_failed = True

    if json_project_id != dart_project_id:
        print('❌ PROJECT_ID mismatch!')
        validation_failed = True

    if json_storage_bucket != dart_storage_bucket:
        print('❌ STORAGE_BUCKET mismatch!')
        validation_failed = True

    if validation_failed:
        print('❌ FATAL: Firebase configuration validation failed!')
        print('This will likely cause Android app initialization to fail.')
        sys.exit(1)

    print('✅ All Firebase Android configuration values match google-services.json')
    return True

if __name__ == "__main__":
    main()