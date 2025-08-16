import json
import sys

with open('prod-google-services.json', 'r') as f:
    data = json.load(f)

project_id = data['project_info']['project_id']
print(f'✅ Production Project ID: {project_id}')

if project_id != 'samaan-ai-production-2025':
    print(f'❌ Expected production project: samaan-ai-production-2025, got: {project_id}')
    sys.exit(1)

# Check Android client
client = data['client'][0]
oauth_clients = client['oauth_client']
android_client = next((c for c in oauth_clients if c['client_type'] == 1), None)

if not android_client:
    print('❌ No Android OAuth client found in production config')
    sys.exit(1)

package_name = android_client['android_info']['package_name']
cert_hash = android_client['android_info']['certificate_hash']

print(f'✅ Package Name: {package_name}')
print(f'✅ Certificate Hash: {cert_hash}')

if package_name != 'com.samaanai.productivityhealth.prod':
    print(f'❌ Unexpected package name: {package_name}')
    sys.exit(1)

print('✅ Production configuration structure is valid!')