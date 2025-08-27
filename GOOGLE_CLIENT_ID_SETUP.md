# Google Client ID Dynamic Configuration

## ✅ System Overview

The Google Client ID is now properly configured to work dynamically across all environments:

- **Development (Local)**: Uses staging client ID, replaced by `dev.sh` script
- **Staging**: Uses staging client ID, replaced by GitHub Actions
- **Production**: Uses production client ID, replaced by GitHub Actions

## 🔧 How It Works

### 1. Template System
- `web/index.html` contains placeholder: `{{GOOGLE_CLIENT_ID}}`
- Scripts replace this placeholder with the appropriate client ID per environment
- After builds/dev sessions, placeholder is restored automatically

### 2. Environment-Specific Client IDs

**Staging Client ID:**
```
362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com
```

**Production Client ID:**
- Set in GitHub Secrets: `GOOGLE_CLIENT_ID_PRODUCTION`
- Used by production deployment workflow

### 3. Development Workflow (`./scripts/dev.sh`)

**When you run `./scripts/dev.sh`:**
1. 📝 Replaces `{{GOOGLE_CLIENT_ID}}` with staging client ID
2. 🚀 Starts Flutter development server
3. 🔧 On exit, restores `{{GOOGLE_CLIENT_ID}}` placeholder automatically

**When you run `./scripts/dev.sh build`:**
1. 📝 Replaces `{{GOOGLE_CLIENT_ID}}` with staging client ID  
2. 🔨 Builds Flutter web app
3. 🔧 Restores `{{GOOGLE_CLIENT_ID}}` placeholder after build

### 4. GitHub Actions Deployment

**Staging Deployment (`.github/workflows/preproduction.yml`):**
- Replaces `{{GOOGLE_CLIENT_ID}}` with `secrets.GOOGLE_CLIENT_ID_STAGING`
- Deploys to staging environment

**Production Deployment (`.github/workflows/release.yml`):**  
- Replaces `{{GOOGLE_CLIENT_ID}}` with `secrets.GOOGLE_CLIENT_ID_PRODUCTION`
- Deploys to production environment

## 🎯 Key Benefits

1. **Single Source Template**: `web/index.html` stays clean with placeholders
2. **Environment Isolation**: Each environment uses its own Google Client ID
3. **Automatic Management**: Scripts handle replacement and restoration
4. **Developer Friendly**: No manual configuration needed
5. **Git Safe**: Placeholders prevent accidental client ID commits

## 📋 Required GitHub Secrets

Make sure these secrets are configured in GitHub repository settings:

**Staging:**
- `GOOGLE_CLIENT_ID_STAGING`: `362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com`

**Production:**
- `GOOGLE_CLIENT_ID_PRODUCTION`: Production Google Client ID

## 🧪 Testing

1. **Local Development:**
   ```bash
   ./scripts/dev.sh
   # Check that localhost:5000 loads with Google Sign-In working
   ```

2. **Verify Template Restoration:**
   ```bash
   # After dev session ends, check that placeholder is restored:
   grep "{{GOOGLE_CLIENT_ID}}" web/index.html
   # Should return the line with placeholder
   ```

3. **Build Testing:**
   ```bash
   ./scripts/dev.sh build
   # Verify build succeeds and placeholder is restored after
   ```

## 🚀 Current Status

✅ **Development**: Configured with staging client ID injection  
✅ **Staging**: GitHub Actions configured with proper secrets  
✅ **Production**: GitHub Actions configured with production secrets  
✅ **Template System**: Automatic placeholder management working  
✅ **Restoration**: Automatic cleanup after dev/build sessions  

## 🔍 Debug/Verification

To verify the system is working:

```bash
# 1. Check current web/index.html has placeholder
grep "GOOGLE_CLIENT_ID" web/index.html

# 2. Run development server 
./scripts/dev.sh

# 3. During development, the meta tag should show real client ID
# 4. After quitting, placeholder should be restored automatically
```

The system is now fully automated and environment-aware! 🎉