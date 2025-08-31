import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:samaanai_fitness_tracker/services/auth_service.dart';
import 'package:samaanai_fitness_tracker/services/firebase_service.dart';
import 'package:samaanai_fitness_tracker/config/firebase_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('API Integration Tests', () {
    late FirebaseService firebaseService;
    late AuthService authService;

    setUpAll(() async {
      // Initialize Firebase for the test environment
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      authService = AuthService(auth: auth);
      firebaseService = FirebaseService(
        auth: auth,
        firestore: firestore,
        httpClient: http.Client(),
      );

      // IMPORTANT:
      // For this test to run, you MUST have a test user account in your
      // Firebase Authentication. Replace the credentials below.
      const testEmail = 'testuser@example.com';
      const testPassword = 'password123';

      try {
        // Attempt to sign in. If it fails, the user might not exist, so we create it.
        await authService.signInWithEmailAndPassword(
            email: testEmail, password: testPassword);
      } catch (e) {
        // If sign-in fails, it's likely because the user doesn't exist.
        // Let's create the user for the test run.
        await authService.registerWithEmailAndPassword(
            email: testEmail, password: testPassword);
        // And sign in again
        await authService.signInWithEmailAndPassword(
            email: testEmail, password: testPassword);
      }

      // Ensure a user is signed in before running tests
      expect(auth.currentUser, isNotNull,
          reason: "Test user could not be signed in.");
    });

    testWidgets('successfully calls the live calculateBMR cloud function',
        (WidgetTester tester) async {
      // This test doesn't need to pump a widget, as it's testing a service.
      // We just need a host app to run on the device/emulator.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final user = authService.currentUser;
      expect(user, isNotNull);

      // Act
      // Call the BMR function with the real user ID.
      // This will make a real HTTP request to your live cloud function.
      final bmrResult = await firebaseService.calculateBMR(user!.uid);

      // Assert
      // We expect a valid, positive number. The exact value doesn't matter,
      // just that the call was successful and returned a sensible result.
      expect(bmrResult, isA<double>());
      expect(bmrResult, greaterThan(0));

      print('✅ Live BMR Calculation successful. Result: $bmrResult');
    });
  });
}
