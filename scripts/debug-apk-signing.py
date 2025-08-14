#!/usr/bin/env python3
"""
Debug APK signing and Google Sign-In configuration.
This script analyzes an APK to understand why Google Sign-In is failing.
"""

import subprocess
import sys
import os
import zipfile
import json
import tempfile

def run_command(cmd, description=""):
    """Run a command and return output."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ Error running {description}: {result.stderr}")
            return None
        return result.stdout
    except Exception as e:
        print(f"❌ Exception running {description}: {e}")
        return None

def get_apk_signature_info(apk_path):
    """Get signature information from APK."""
    print(f"🔍 Analyzing APK signature: {apk_path}")
    
    # Check if aapt2 or aapt is available
    aapt_cmd = None
    for cmd in ["aapt2", "aapt"]:
        if run_command(f"which {cmd}", f"checking {cmd}"):
            aapt_cmd = cmd
            break
    
    if not aapt_cmd:
        print("⚠️  aapt/aapt2 not found. Install Android SDK build tools.")
        return None
    
    # Get package info
    output = run_command(f"{aapt_cmd} dump badging {apk_path}", "getting APK info")
    if output:
        for line in output.split('\n'):
            if line.startswith('package:'):
                print(f"📦 {line}")
    
    return output

def get_apk_signing_certificate(apk_path):
    """Get signing certificate info from APK."""
    print(f"🔐 Getting signing certificate from APK...")
    
    # Try using apksigner (preferred method)
    output = run_command(f"apksigner verify --print-certs {apk_path}", "apksigner verify")
    if output:
        print("✅ APK signature verification (apksigner):")
        print(output)
        return output
    
    # Fallback to keytool with jarsigner
    print("⚠️  apksigner not found, trying keytool method...")
    
    # Extract META-INF files to get certificate
    temp_dir = tempfile.mkdtemp()
    try:
        with zipfile.ZipFile(apk_path, 'r') as zip_file:
            meta_inf_files = [f for f in zip_file.namelist() if f.startswith('META-INF/') and f.endswith('.RSA')]
            if meta_inf_files:
                cert_file = meta_inf_files[0]
                zip_file.extract(cert_file, temp_dir)
                cert_path = os.path.join(temp_dir, cert_file)
                
                output = run_command(f"keytool -printcert -file {cert_path}", "keytool certificate")
                if output:
                    print("✅ Certificate info (keytool):")
                    print(output)
                    return output
    except Exception as e:
        print(f"❌ Error extracting certificate: {e}")
    finally:
        # Clean up
        import shutil
        shutil.rmtree(temp_dir, ignore_errors=True)
    
    return None

def extract_google_services_from_apk(apk_path):
    """Extract google-services.json equivalent from APK."""
    print(f"🔍 Extracting Google services configuration from APK...")
    
    temp_dir = tempfile.mkdtemp()
    try:
        with zipfile.ZipFile(apk_path, 'r') as zip_file:
            # Look for google-services related files
            relevant_files = []
            for file_name in zip_file.namelist():
                if any(keyword in file_name.lower() for keyword in ['google', 'firebase', 'oauth', 'client']):
                    relevant_files.append(file_name)
            
            if relevant_files:
                print("📋 Found Google/Firebase related files in APK:")
                for file_name in relevant_files:
                    print(f"   - {file_name}")
                    
                # Try to extract and analyze some key files
                for file_name in relevant_files:
                    if file_name.endswith('.json') or 'string' in file_name or 'values' in file_name:
                        try:
                            zip_file.extract(file_name, temp_dir)
                            extracted_path = os.path.join(temp_dir, file_name)
                            
                            with open(extracted_path, 'r') as f:
                                content = f.read()
                                print(f"\n📄 Content of {file_name}:")
                                print(content[:500] + "..." if len(content) > 500 else content)
                        except Exception as e:
                            print(f"⚠️  Could not read {file_name}: {e}")
            else:
                print("❌ No Google/Firebase related files found in APK")
                
    except Exception as e:
        print(f"❌ Error extracting from APK: {e}")
    finally:
        # Clean up
        import shutil
        shutil.rmtree(temp_dir, ignore_errors=True)

def compare_with_expected_config():
    """Compare with expected configuration."""
    print("\n🎯 Expected Configuration:")
    print("=" * 50)
    
    # Expected values
    expected_package = "com.fitnesstracker.fitness_tracker"
    expected_sha1 = "53315440bd500648d1034bdf6fa462fce03775fa"
    expected_project = "fitness-tracker-8d0ae"
    
    print(f"📦 Expected Package: {expected_package}")
    print(f"🔐 Expected SHA-1: {expected_sha1}")
    print(f"🔥 Expected Firebase Project: {expected_project}")
    print(f"🌐 Expected Web Client: 763348902456-l7kcl7qerssghmid1bmc5n53oq2v62ic.apps.googleusercontent.com")
    print(f"📱 Expected Android Client: 763348902456-b2ga4vrkv25ecap115hmr8qdh3jk1q73.apps.googleusercontent.com")

def check_local_debug_keystore():
    """Check local debug keystore for comparison."""
    print("\n🔑 Local Debug Keystore Info:")
    print("=" * 40)
    
    debug_keystore = os.path.expanduser("~/.android/debug.keystore")
    if os.path.exists(debug_keystore):
        output = run_command(f"keytool -list -v -keystore {debug_keystore} -alias androiddebugkey -storepass android -keypass android", "local debug keystore")
        if output:
            for line in output.split('\n'):
                if 'SHA1:' in line or 'Certificate fingerprints:' in line or 'Owner:' in line:
                    print(f"   {line.strip()}")
    else:
        print("❌ Local debug keystore not found")

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 debug-apk-signing.py <path-to-apk>")
        print("\nExample:")
        print("  python3 debug-apk-signing.py ~/Downloads/app-debug.apk")
        sys.exit(1)
    
    apk_path = sys.argv[1]
    
    if not os.path.exists(apk_path):
        print(f"❌ APK file not found: {apk_path}")
        sys.exit(1)
    
    print("🔍 APK Google Sign-In Debug Analysis")
    print("=" * 60)
    print(f"📱 APK Path: {apk_path}")
    print()
    
    # 1. Get APK basic info
    get_apk_signature_info(apk_path)
    print()
    
    # 2. Get signing certificate
    get_apk_signing_certificate(apk_path)
    print()
    
    # 3. Extract Google services config
    extract_google_services_from_apk(apk_path)
    print()
    
    # 4. Compare with expected
    compare_with_expected_config()
    print()
    
    # 5. Check local keystore
    check_local_debug_keystore()
    print()
    
    print("🔧 Next Steps:")
    print("1. Compare the SHA-1 from APK certificate with expected SHA-1")
    print("2. Verify the package name matches")
    print("3. Check if the APK contains the correct Google services configuration")
    print("4. If SHA-1 doesn't match, the DEBUG_KEYSTORE secret might be wrong")
    print("5. If package name is wrong, rebuild with correct configuration")

if __name__ == "__main__":
    main()