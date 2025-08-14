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
    apiKey: "AIzaSyAhBC9FUOX02Kj3HBIAmwFOmi9cNFqRR5A",
    authDomain: "fitness-tracker-8d0ae.firebaseapp.com",
    projectId: "fitness-tracker-8d0ae",
    storageBucket: "fitness-tracker-8d0ae.firebasestorage.app",
    messagingSenderId: "763348902456",
    appId: "1:763348902456:android:536b977f3ec075131ebccd",
    measurementId: "G-Q8J9DC0FNY",
  );
  
  // Staging Firebase configuration (Web)
  static const FirebaseOptions _stagingWebConfig = FirebaseOptions(
    apiKey: "AIzaSyAhBC9FUOX02Kj3HBIAmwFOmi9cNFqRR5A",
    authDomain: "fitness-tracker-8d0ae.firebaseapp.com",
    projectId: "fitness-tracker-8d0ae",
    storageBucket: "fitness-tracker-8d0ae.firebasestorage.app",
    messagingSenderId: "763348902456",
    appId: "1:763348902456:web:b5b5bb8a0c5c8a8b1ebccd",
    measurementId: "G-Q8J9DC0FNY",
  );
  
  // Production Firebase configuration (Mobile)
  static const FirebaseOptions _productionConfig = FirebaseOptions(
    apiKey: "AIzaSyAhKu4npHEKmTM5FZTy-jNdcY0kH3W2z6s",
    authDomain: "fitness-tracker-p2025.firebaseapp.com",
    projectId: "fitness-tracker-p2025",
    storageBucket: "fitness-tracker-p2025.firebasestorage.app",
    messagingSenderId: "934862983900",
    appId: "1:934862983900:android:9eb21955cbc6a477c1da19",
    measurementId: "G-MEASUREMENT_ID", // Update this with your actual measurement ID
  );
  
  // Production Firebase configuration (Web)
  static const FirebaseOptions _productionWebConfig = FirebaseOptions(
    apiKey: "AIzaSyAhKu4npHEKmTM5FZTy-jNdcY0kH3W2z6s",
    authDomain: "fitness-tracker-p2025.firebaseapp.com",
    projectId: "fitness-tracker-p2025",
    storageBucket: "fitness-tracker-p2025.firebasestorage.app",
    messagingSenderId: "934862983900",
    appId: "1:934862983900:web:c1b5bb8a0c5c8a8bc1da19",
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