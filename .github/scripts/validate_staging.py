import json
import sys

with open('staging-google-services.json', 'r') as f:
    data = json.load(f)

project_id = data['project_info']['project_id']
print(f'✅ Staging Project ID: {project_id}')

if project_id != 'fitness-tracker-8d0ae':
    print(f'❌ Expected staging project: fitness-tracker-8d0ae, got: {project_id}')
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

if package_name != 'com.fitnesstracker.fitness_tracker':
    print(f'❌ Unexpected package name: {package_name}')
    sys.exit(1)

# For staging, we expect our consistent debug keystore hash: 53315440bd500648d1034bdf6fa462fce03775fa
expected_debug_hash = '53315440bd500648d1034bdf6fa462fce03775fa'
if cert_hash != expected_debug_hash:
    print(f'❌ Staging should use consistent debug keystore hash: {expected_debug_hash}')
    print(f'❌ But got: {cert_hash}')
    print('❌ Make sure GOOGLE_SERVICES_STAGING has the correct SHA-1')
    sys.exit(1)

print('✅ Staging configuration is valid!')