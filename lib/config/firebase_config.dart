import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    // Check environment variable set by GitHub Actions
    const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'staging');
    
    switch (environment) {
      case 'production':
        return kIsWeb ? _productionWebConfig : _productionConfig;
      case 'staging':
      case 'development':
      default:
        return kIsWeb ? _stagingWebConfig : _stagingConfig;
    }
  }
  
  // Staging Firebase configuration (Mobile)
  static const FirebaseOptions _stagingConfig = FirebaseOptions(
    apiKey: "AIzaSyDngmDDrO8GnMK898Ecy-eRiIFQc_YSs_I",
    authDomain: "samaan-ai-staging-2025.firebaseapp.com",
    projectId: "samaan-ai-staging-2025",
    storageBucket: "samaan-ai-staging-2025.firebasestorage.app",
    messagingSenderId: "362525403590",
    appId: "1:362525403590:android:3c8a94a5ceee9942e36ac7",
    measurementId: "G-MEASUREMENT_ID", // Update this with your actual measurement ID
  );
  
  // Staging Firebase configuration (Web)
  static const FirebaseOptions _stagingWebConfig = FirebaseOptions(
    apiKey: "AIzaSyDngmDDrO8GnMK898Ecy-eRiIFQc_YSs_I",
    authDomain: "samaan-ai-staging-2025.firebaseapp.com",
    projectId: "samaan-ai-staging-2025",
    storageBucket: "samaan-ai-staging-2025.firebasestorage.app",
    messagingSenderId: "362525403590",
    appId: "1:362525403590:web:3110155a85fba0a0e36ac7",
    measurementId: "G-MEASUREMENT_ID", // Update this with your actual measurement ID
  );
  
  // Production Firebase configuration (Mobile)
  static const FirebaseOptions _productionConfig = FirebaseOptions(
    apiKey: "AIzaSyCYPDJDhMuH1wEDCGJ8sjAERA445w5BFRg",
    authDomain: "samaan-ai-production-2025.firebaseapp.com",
    projectId: "samaan-ai-production-2025",
    storageBucket: "samaan-ai-production-2025.firebasestorage.app",
    messagingSenderId: "995832123315",
    appId: "1:995832123315:android:726dd726de26fb1ce585c6",
    measurementId: "G-MEASUREMENT_ID", // Update this with your actual measurement ID
  );
  
  // Production Firebase configuration (Web)
  static const FirebaseOptions _productionWebConfig = FirebaseOptions(
    apiKey: "AIzaSyCYPDJDhMuH1wEDCGJ8sjAERA445w5BFRg",
    authDomain: "samaan-ai-production-2025.firebaseapp.com",
    projectId: "samaan-ai-production-2025",
    storageBucket: "samaan-ai-production-2025.firebasestorage.app",
    messagingSenderId: "995832123315",
    appId: "1:995832123315:web:359017de78c35bd1e585c6",
    measurementId: "G-MEASUREMENT_ID", // Update this with your actual measurement ID
  );
  
  // Environment-based configuration (recommended for production)
  static FirebaseOptions get environmentConfig {
    // These values should be set as environment variables
    const String? apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const String? authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const String? projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const String? storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    const String? messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const String? appId = String.fromEnvironment('FIREBASE_APP_ID');
    const String? measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
    
    if (apiKey == null || projectId == null) {
      throw Exception('Firebase configuration missing. Please set environment variables.');
    }
    
    return FirebaseOptions(
      apiKey: apiKey,
      authDomain: authDomain ?? '$projectId.firebaseapp.com',
      projectId: projectId,
      storageBucket: storageBucket ?? '$projectId.firebasestorage.app',
      messagingSenderId: messagingSenderId ?? '',
      appId: appId ?? '',
      measurementId: measurementId,
    );
  }
}