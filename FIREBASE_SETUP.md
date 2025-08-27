# Firebase Authentication Setup Guide

## Current Issues

### 1. "Operation not allowed" Error
This error occurs when authentication methods are not enabled in Firebase Console.

**To Fix:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `samaan-ai-staging-2025`
3. Navigate to **Authentication** > **Sign-in method**
4. Enable the following providers:
   - ✅ **Email/Password**: Click "Enable" toggle
   - ✅ **Google**: Click "Enable" and configure:
     - Add your app's domains to authorized domains
     - For development: Add `localhost` and `127.0.0.1`
     - For staging: Add `samaan-ai-staging-2025.web.app`

### 2. Google Sign-In Web Configuration

**Required Steps:**
1. In Firebase Console > Authentication > Sign-in method > Google:
   - Enable the Google provider
   - Set Web SDK configuration
   - Add authorized JavaScript origins:
     - `http://localhost:5000` (for development)
     - `https://samaan-ai-staging-2025.web.app` (for staging)

2. Verify OAuth consent screen in [Google Cloud Console](https://console.cloud.google.com):
   - Go to APIs & Services > OAuth consent screen
   - Add authorized domains:
     - `localhost` (for development)
     - `samaan-ai-staging-2025.web.app` (for staging)

### 3. Current Configuration

The app is configured to use:
- **Project**: `samaan-ai-staging-2025`
- **Google Client ID**: `362525403590-rjc786764k0e5akfvpjujfe40ld8gccf.apps.googleusercontent.com`
- **Development Port**: `http://localhost:5000`

## Debug Information

When you run the app, check the browser console for Firebase configuration debug information. It will show:
- Current Firebase project settings
- Environment variables
- Platform detection
- Setup instructions

## Testing Steps

1. **Start the development server:**
   ```bash
   ./scripts/dev.sh
   ```

2. **Check console output** for Firebase configuration debug info

3. **Try email authentication first** - this helps identify if it's a general auth issue or specifically Google Sign-In

4. **Test Google Sign-In** after confirming email auth works

## Common Issues

- **Cross-Origin errors**: Make sure localhost:5000 is added to authorized origins
- **Client ID mismatch**: Verify the Google Client ID in web/index.html matches the one from Google Cloud Console
- **Provider not enabled**: Most common cause of "operation not allowed" error