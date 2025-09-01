import json
import sys
import os

with open('staging-google-services.json', 'r') as f:
    data = json.load(f)

project_id = data['project_info']['project_id']
print(f'✅ Staging Project ID: {project_id}')

if project_id != 'samaan-ai-staging-2025':
    print(f'❌ Expected staging project: samaan-ai-staging-2025, got: {project_id}')
    sys.exit(1)

# Check Android client
client = data['client'][0]
oauth_clients = client['oauth_client']
android_client = next((c for c in oauth_clients if c['client_type'] == 1), None)

if not android_client:
    print('❌ No Android OAuth client found in staging config')
    sys.exit(1)

package_name = android_client['android_info']['package_name']
cert_hash = android_client['android_info']['certificate_hash']

print(f'✅ Package Name: {package_name}')
print(f'✅ Certificate Hash: {cert_hash}')

if package_name != 'com.samaanai.productivityhealth':
    print(f'❌ Unexpected package name: {package_name}')
    sys.exit(1)

# Compare against EXPECTED_DEBUG_SHA1 if provided (computed from DEBUG_KEYSTORE in CI)
expected_debug_hash = os.environ.get('EXPECTED_DEBUG_SHA1')
if expected_debug_hash:
    if cert_hash.lower() != expected_debug_hash.lower():
        print(f'❌ Staging should use consistent debug keystore hash: {expected_debug_hash}')
        print(f'❌ But got: {cert_hash}')
        print('❌ Make sure GOOGLE_SERVICES_STAGING matches the DEBUG_KEYSTORE SHA-1')
        sys.exit(1)
else:
    print('⚠️  EXPECTED_DEBUG_SHA1 not set; skipping SHA-1 match enforcement')

print('✅ Staging configuration is valid!')