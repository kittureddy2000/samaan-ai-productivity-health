import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseDebug {
  static void logCurrentConfiguration() {
    if (!kDebugMode) return;
    
    final app = Firebase.app();
    final options = app.options;
    
    print('🔧 Firebase Configuration Debug:');
    print('  Project ID: ${options.projectId}');
    print('  API Key: ${options.apiKey.substring(0, 10)}...');
    print('  Auth Domain: ${options.authDomain}');
    print('  App ID: ${options.appId}');
    
    // Check environment variables
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'not set');
    const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: 'not set');
    
    print('🌍 Environment Variables:');
    print('  ENVIRONMENT: $environment');
    print('  GOOGLE_CLIENT_ID: ${googleClientId == "not set" ? "not set" : "${googleClientId.substring(0, 10)}..."}');
    
    if (kIsWeb) {
      print('🌐 Web Platform Detected');
      print('  Check that web/index.html has proper meta tags');
    } else {
      print('📱 Mobile Platform Detected');
    }
  }
  
  static void logAuthMethods() {
    if (!kDebugMode) return;
    
    print('🔐 To fix "operation-not-allowed" error:');
    print('  1. Go to Firebase Console: https://console.firebase.google.com');
    print('  2. Select project: samaan-ai-staging-2025');
    print('  3. Go to Authentication > Sign-in method');
    print('  4. Enable "Email/Password" provider');
    print('  5. Enable "Google" provider and add your domain');
    print('  6. For Google web: Add http://localhost:5000 to authorized origins');
  }
}