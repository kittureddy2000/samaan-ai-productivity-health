import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:samaanai_fitness_tracker/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AuthService', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late AuthService authService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockFirebaseAuth);
    });

    group('Email and Password Authentication', () {
      test('signInWithEmailAndPassword returns UserCredential on success',
          () async {
        const email = 'test@example.com';
        const password = 'password123';

        // Mock user
        final mockUser = MockUser(
          uid: 'test_uid',
          email: email,
          displayName: 'Test User',
        );

        // Setup the mock to return the user
        await mockFirebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final result = await authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        expect(result, isA<UserCredential>());
        expect(result?.user?.email, equals(email));
      });

      test('registerWithEmailAndPassword creates new user', () async {
        const email = 'newuser@example.com';
        const password = 'password123';

        final result = await authService.registerWithEmailAndPassword(
          email: email,
          password: password,
        );

        expect(result, isA<UserCredential>());
        expect(result?.user?.email, equals(email));
      });
    });

    group('User State', () {
      test('currentUser returns the current user', () async {
        // Initially no user
        expect(authService.currentUser, isNull);

        // Sign in a user
        await mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );
        await mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Now should have a user
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.email, equals('test@example.com'));
      });
    });
  });
}
