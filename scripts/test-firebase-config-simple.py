#!/usr/bin/env python3

import json
import re
import sys
import os

def update_firebase_config_only(android_api_key, android_app_id, storage_bucket):
    """Update firebase_options.dart with provided values (for CI use)"""
    print("🔧 Updating Firebase Android configuration...")
    
    try:
        with open('lib/firebase_options.dart', 'r') as f:
            content = f.read()
        
        # Extract the Android block and replace the values
        android_pattern = r'(static const FirebaseOptions android = FirebaseOptions\(\s*)(.*?)(\s*\);)'
        match = re.search(android_pattern, content, re.DOTALL)
        
        if match:
            android_block_content = match.group(2)
            
            # Replace values
            android_block_content = re.sub(r"apiKey: '[^']*'", f"apiKey: '{android_api_key}'", android_block_content)
            android_block_content = re.sub(r"appId: '[^']*'", f"appId: '{android_app_id}'", android_block_content)
            android_block_content = re.sub(r"storageBucket: '[^']*'", f"storageBucket: '{storage_bucket}'", android_block_content)
            
            # Reconstruct the Android block
            new_android_block = match.group(1) + android_block_content + match.group(3)
            
            # Replace the entire Android block in the content
            content = re.sub(android_pattern, new_android_block, content, flags=re.DOTALL)
            
            # Write back to file
            with open('lib/firebase_options.dart', 'w') as f:
                f.write(content)
            
            print("✅ Successfully updated Android Firebase configuration")
            return True
        else:
            print("❌ Could not find Android FirebaseOptions block")
            return False
            
    except Exception as e:
        print(f"❌ Failed to update firebase_options.dart: {e}")
        return False

def main():
    print("🧪 Testing Firebase Configuration Process...")
    
    # Extract values from google-services.json
    print("📱 Testing Android config extraction from google-services.json...")
    
    try:
        with open('android/app/google-services.json', 'r') as f:
            google_services = json.load(f)
        
        android_app_id = google_services['client'][0]['client_info']['mobilesdk_app_id']
        android_api_key = google_services['client'][0]['api_key'][0]['current_key']
        storage_bucket = google_services['project_info']['storage_bucket']
        project_id = google_services['project_info']['project_id']
        
        print(f"Extracted values:")
        print(f"  APP_ID: {android_app_id}")
        print(f"  API_KEY: {android_api_key[:10]}********")
        print(f"  STORAGE_BUCKET: {storage_bucket}")
        print(f"  PROJECT_ID: {project_id}")
        
    except Exception as e:
        print(f"❌ Failed to read google-services.json: {e}")
        return False
    
    # Backup original file
    print("📋 Backing up firebase_options.dart...")
    os.system('cp lib/firebase_options.dart lib/firebase_options.dart.test-backup')
    
    # Test updating firebase_options.dart
    print("🔧 Testing Firebase options update...")
    
    try:
        with open('lib/firebase_options.dart', 'r') as f:
            content = f.read()
        
        # Extract the Android block and replace the values
        android_pattern = r'(static const FirebaseOptions android = FirebaseOptions\(\s*)(.*?)(\s*\);)'
        match = re.search(android_pattern, content, re.DOTALL)
        
        if match:
            android_block_content = match.group(2)
            
            # Replace values
            android_block_content = re.sub(r"apiKey: '[^']*'", f"apiKey: '{android_api_key}'", android_block_content)
            android_block_content = re.sub(r"appId: '[^']*'", f"appId: '{android_app_id}'", android_block_content)
            android_block_content = re.sub(r"storageBucket: '[^']*'", f"storageBucket: '{storage_bucket}'", android_block_content)
            
            # Reconstruct the Android block
            new_android_block = match.group(1) + android_block_content + match.group(3)
            
            # Replace the entire Android block in the content
            content = re.sub(android_pattern, new_android_block, content, flags=re.DOTALL)
            
            # Write back to file
            with open('lib/firebase_options.dart', 'w') as f:
                f.write(content)
            
            print("✅ Successfully updated Android Firebase configuration")
        else:
            print("❌ Could not find Android FirebaseOptions block")
            return False
            
    except Exception as e:
        print(f"❌ Failed to update firebase_options.dart: {e}")
        return False
    
    # Validate configuration
    print("🔍 Testing validation...")
    
    try:
        # Re-read the updated file and extract values
        with open('lib/firebase_options.dart', 'r') as f:
            updated_content = f.read()
        
        # Extract Android block
        android_match = re.search(r'static const FirebaseOptions android = FirebaseOptions\((.*?)\);', updated_content, re.DOTALL)
        if android_match:
            android_block = android_match.group(1)
            
            # Extract individual values
            dart_api_key_match = re.search(r"apiKey: '([^']*)'", android_block)
            dart_app_id_match = re.search(r"appId: '([^']*)'", android_block)
            dart_project_id_match = re.search(r"projectId: '([^']*)'", android_block)
            dart_storage_bucket_match = re.search(r"storageBucket: '([^']*)'", android_block)
            
            dart_api_key = dart_api_key_match.group(1) if dart_api_key_match else None
            dart_app_id = dart_app_id_match.group(1) if dart_app_id_match else None
            dart_project_id = dart_project_id_match.group(1) if dart_project_id_match else None
            dart_storage_bucket = dart_storage_bucket_match.group(1) if dart_storage_bucket_match else None
            
            print(f"🔍 Validation Results:")
            print(f"APP_ID:        JSON={android_app_id} | DART={dart_app_id}")
            print(f"API_KEY:       JSON={android_api_key[:10]}*** | DART={dart_api_key[:10] if dart_api_key else 'None'}***")
            print(f"PROJECT_ID:    JSON={project_id} | DART={dart_project_id}")
            print(f"STORAGE_BUCKET: JSON={storage_bucket} | DART={dart_storage_bucket}")
            
            # Validation checks
            validation_failed = False
            
            if android_app_id != dart_app_id:
                print("❌ APP_ID mismatch!")
                validation_failed = True
            
            if android_api_key != dart_api_key:
                print("❌ API_KEY mismatch!")
                validation_failed = True
            
            if project_id != dart_project_id:
                print("❌ PROJECT_ID mismatch!")
                validation_failed = True
                
            if storage_bucket != dart_storage_bucket:
                print("❌ STORAGE_BUCKET mismatch!")
                validation_failed = True
            
            if validation_failed:
                print("❌ FATAL: Firebase configuration validation failed!")
                return False
            else:
                print("✅ All Firebase Android configuration values match google-services.json")
                
        else:
            print("❌ Could not extract Android block from updated file")
            return False
            
    except Exception as e:
        print(f"❌ Validation failed: {e}")
        return False
    finally:
        # Restore original file
        print("🔄 Restoring original firebase_options.dart...")
        os.system('mv lib/firebase_options.dart.test-backup lib/firebase_options.dart')
    
    print("🎉 All tests passed! CI changes should work correctly.")
    return True

if __name__ == "__main__":
    # Check for --update-only flag (for CI use)
    if len(sys.argv) >= 5 and sys.argv[1] == "--update-only":
        android_api_key = sys.argv[2]
        android_app_id = sys.argv[3] 
        storage_bucket = sys.argv[4]
        success = update_firebase_config_only(android_api_key, android_app_id, storage_bucket)
        sys.exit(0 if success else 1)
    else:
        success = main()
        sys.exit(0 if success else 1)