import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:samaanai_fitness_tracker/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    late UserProfile testProfile;
    final testDate = DateTime(1990, 5, 15);
    final testCreatedAt = DateTime(2023, 1, 1);
    final testUpdatedAt = DateTime(2023, 6, 1);

    setUp(() {
      testProfile = UserProfile(
        uid: 'test_uid',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/photo.jpg',
        dateOfBirth: testDate,
        height: 175.0,
        weight: 70.0,
        gender: 'male',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
    });

    group('Age Calculation', () {
      test('calculates age correctly', () {
        final profile = UserProfile(
          uid: 'test_uid',
          email: 'test@example.com',
          dateOfBirth: DateTime(1990, 5, 15),
          height: 175.0,
          weight: 70.0,
          gender: 'male',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Calculate expected age
        final now = DateTime.now();
        int expectedAge = now.year - 1990;
        if (now.month < 5 || (now.month == 5 && now.day < 15)) {
          expectedAge--;
        }

        expect(profile.age, equals(expectedAge));
      });

      test('handles birthday not yet occurred this year', () {
        // Create profile with birthday later this year
        final profile = UserProfile(
          uid: 'test_uid',
          email: 'test@example.com',
          dateOfBirth: DateTime(DateTime.now().year - 25, 12, 31),
          height: 175.0,
          weight: 70.0,
          gender: 'male',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(profile.age, greaterThanOrEqualTo(24));
        expect(profile.age, lessThanOrEqualTo(25));
      });
    });

    group('Firestore Conversion', () {
      test('toFirestore converts correctly', () {
        final firestoreData = testProfile.toFirestore();

        expect(firestoreData['uid'], equals('test_uid'));
        expect(firestoreData['email'], equals('test@example.com'));
        expect(firestoreData['displayName'], equals('Test User'));
        expect(
            firestoreData['photoURL'], equals('https://example.com/photo.jpg'));
        expect(firestoreData['dateOfBirth'], isA<Timestamp>());
        expect(firestoreData['height'], equals(175.0));
        expect(firestoreData['weight'], equals(70.0));
        expect(firestoreData['gender'], equals('male'));
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());
      });

      test('fromFirestore creates UserProfile correctly', () async {
        // Create a fake Firestore document
        final fakeFirestore = FakeFirebaseFirestore();
        final docRef = fakeFirestore.collection('users').doc('test_uid');

        await docRef.set({
          'uid': 'test_uid',
          'email': 'test@example.com',
          'displayName': 'Test User',
          'photoURL': 'https://example.com/photo.jpg',
          'dateOfBirth': Timestamp.fromDate(testDate),
          'height': 175.0,
          'weight': 70.0,
          'gender': 'male',
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'updatedAt': Timestamp.fromDate(testUpdatedAt),
        });

        final doc = await docRef.get();
        final profile = UserProfile.fromFirestore(doc);

        expect(profile.uid, equals('test_uid'));
        expect(profile.email, equals('test@example.com'));
        expect(profile.displayName, equals('Test User'));
        expect(profile.photoURL, equals('https://example.com/photo.jpg'));
        expect(profile.dateOfBirth.year, equals(1990));
        expect(profile.dateOfBirth.month, equals(5));
        expect(profile.dateOfBirth.day, equals(15));
        expect(profile.height, equals(175.0));
        expect(profile.weight, equals(70.0));
        expect(profile.gender, equals('male'));
      });

      test('fromFirestore handles missing optional fields', () async {
        final fakeFirestore = FakeFirebaseFirestore();
        final docRef = fakeFirestore.collection('users').doc('test_uid');

        await docRef.set({
          'uid': 'test_uid',
          'email': 'test@example.com',
          'dateOfBirth': Timestamp.fromDate(testDate),
          'height': 175.0,
          'weight': 70.0,
          'gender': 'male',
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'updatedAt': Timestamp.fromDate(testUpdatedAt),
        });

        final doc = await docRef.get();
        final profile = UserProfile.fromFirestore(doc);

        expect(profile.displayName, isNull);
        expect(profile.photoURL, isNull);
        expect(profile.uid, equals('test_uid'));
        expect(profile.email, equals('test@example.com'));
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updatedProfile = testProfile.copyWith(
          displayName: 'Updated Name',
          weight: 75.0,
        );

        expect(updatedProfile.displayName, equals('Updated Name'));
        expect(updatedProfile.weight, equals(75.0));
        expect(updatedProfile.uid, equals(testProfile.uid));
        expect(updatedProfile.email, equals(testProfile.email));
        expect(updatedProfile.height, equals(testProfile.height));
      });

      test('creates identical copy when no fields specified', () {
        final copiedProfile = testProfile.copyWith();

        expect(copiedProfile.uid, equals(testProfile.uid));
        expect(copiedProfile.email, equals(testProfile.email));
        expect(copiedProfile.displayName, equals(testProfile.displayName));
        expect(copiedProfile.photoURL, equals(testProfile.photoURL));
        expect(copiedProfile.dateOfBirth, equals(testProfile.dateOfBirth));
        expect(copiedProfile.height, equals(testProfile.height));
        expect(copiedProfile.weight, equals(testProfile.weight));
        expect(copiedProfile.gender, equals(testProfile.gender));
      });
    });
  });
}
