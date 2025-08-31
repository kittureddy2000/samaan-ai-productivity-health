import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseDebug {
  static void logCurrentConfiguration() {
    if (!kDebugMode) return;

    final app = Firebase.app();
    final options = app.options;

    debugPrint('🔧 Firebase Configuration Debug:');
    debugPrint('  Project ID: ${options.projectId}');
    debugPrint('  API Key: ${options.apiKey.substring(0, 10)}...');
    debugPrint('  Auth Domain: ${options.authDomain}');
    debugPrint('  App ID: ${options.appId}');

    // Check environment variables
    const environment =
        String.fromEnvironment('ENVIRONMENT', defaultValue: 'not set');
    const googleClientId =
        String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: 'not set');

    debugPrint('🌍 Environment Variables:');
    debugPrint('  ENVIRONMENT: $environment');
    debugPrint(
        '  GOOGLE_CLIENT_ID: ${googleClientId == "not set" ? "not set" : "${googleClientId.substring(0, 10)}..."}');

    if (kIsWeb) {
      debugPrint('🌐 Web Platform Detected');
      debugPrint('  Check that web/index.html has proper meta tags');
    } else {
      debugPrint('📱 Mobile Platform Detected');
    }
  }

  static void logAuthMethods() {
    if (!kDebugMode) return;

    debugPrint('🔐 To fix "operation-not-allowed" error:');
    debugPrint(
        '  1. Go to Firebase Console: https://console.firebase.google.com');
    debugPrint('  2. Select project: samaan-ai-staging-2025');
    debugPrint('  3. Go to Authentication > Sign-in method');
    debugPrint('  4. Enable "Email/Password" provider');
    debugPrint('  5. Enable "Google" provider and add your domain');
    debugPrint(
        '  6. For Google web: Add http://localhost:5000 to authorized origins');
  }
}
