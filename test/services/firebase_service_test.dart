import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:samaanai_fitness_tracker/services/firebase_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'dart:convert';

import 'firebase_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('FirebaseService', () {
    late MockClient mockHttpClient;
    late FirebaseService firebaseService;
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      mockHttpClient = MockClient();
      mockAuth = MockFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
      firebaseService = FirebaseService(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttpClient,
      );
    });

    group('BMR Calculation', () {
      test('returns BMR value on successful HTTP call', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"bmr": 1850.5}', 200));

        final bmr = await firebaseService.calculateBMR('some_uid');

        expect(bmr, 1850.5);
      });

      test('throws an exception on failed HTTP call', () {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Server Error', 500));

        expect(
          () => firebaseService.calculateBMR('some_uid'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
