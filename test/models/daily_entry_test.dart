import 'package:flutter_test/flutter_test.dart';
import 'package:samaanai_fitness_tracker/models/daily_entry.dart';

void main() {
  group('DailyEntry', () {
    late DailyEntry testEntry;
    final testDate = DateTime(2023, 6, 15);
    final testCreatedAt = DateTime.now();
    final testUpdatedAt = DateTime.now();

    setUp(() {
      testEntry = DailyEntry(
        id: 'test_id',
        uid: 'test_uid',
        date: testDate,
        foodEntries: [
          FoodEntry(name: 'Apple', calories: 95.0),
          FoodEntry(name: 'Banana', calories: 105.0),
        ],
        exerciseEntries: [
          ExerciseEntry(
              name: 'Running', durationMinutes: 30, caloriesBurned: 300.0),
          ExerciseEntry(
              name: 'Walking', durationMinutes: 60, caloriesBurned: 200.0),
        ],
        weight: 70.0,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
    });

    group('Calculated Properties', () {
      test('calculates total calories consumed correctly', () {
        expect(testEntry.totalCaloriesConsumed, equals(200.0)); // 95 + 105
      });

      test('calculates total calories burned correctly', () {
        expect(testEntry.totalCaloriesBurned, equals(500.0)); // 300 + 200
      });

      test('handles empty food entries', () {
        final emptyFoodEntry = DailyEntry(
          id: 'test_id',
          uid: 'test_uid',
          date: testDate,
          foodEntries: [],
          exerciseEntries: [
            ExerciseEntry(
                name: 'Running', durationMinutes: 30, caloriesBurned: 300.0),
          ],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(emptyFoodEntry.totalCaloriesConsumed, equals(0.0));
        expect(emptyFoodEntry.totalCaloriesBurned, equals(300.0));
      });

      test('handles empty exercise entries', () {
        final emptyExerciseEntry = DailyEntry(
          id: 'test_id',
          uid: 'test_uid',
          date: testDate,
          foodEntries: [
            FoodEntry(name: 'Apple', calories: 95.0),
          ],
          exerciseEntries: [],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(emptyExerciseEntry.totalCaloriesBurned, equals(0.0));
        expect(emptyExerciseEntry.totalCaloriesConsumed, equals(95.0));
      });
    });

    group('Basic Properties', () {
      test('stores basic properties correctly', () {
        expect(testEntry.id, equals('test_id'));
        expect(testEntry.uid, equals('test_uid'));
        expect(testEntry.date, equals(testDate));
        expect(testEntry.weight, equals(70.0));
        expect(testEntry.foodEntries.length, equals(2));
        expect(testEntry.exerciseEntries.length, equals(2));
      });
    });
  });

  group('FoodEntry', () {
    test('creates food entry correctly', () {
      final foodEntry = FoodEntry(name: 'Apple', calories: 95.0);

      expect(foodEntry.name, equals('Apple'));
      expect(foodEntry.calories, equals(95.0));
    });

    test('toMap converts correctly', () {
      final foodEntry = FoodEntry(name: 'Apple', calories: 95.0);
      final map = foodEntry.toMap();

      expect(map['name'], equals('Apple'));
      expect(map['calories'], equals(95.0));
    });

    test('fromMap creates FoodEntry correctly', () {
      final map = {'name': 'Apple', 'calories': 95.0};
      final foodEntry = FoodEntry.fromMap(map);

      expect(foodEntry.name, equals('Apple'));
      expect(foodEntry.calories, equals(95.0));
    });
  });

  group('ExerciseEntry', () {
    test('creates exercise entry correctly', () {
      final exerciseEntry = ExerciseEntry(
        name: 'Running',
        durationMinutes: 30,
        caloriesBurned: 300.0,
      );

      expect(exerciseEntry.name, equals('Running'));
      expect(exerciseEntry.durationMinutes, equals(30));
      expect(exerciseEntry.caloriesBurned, equals(300.0));
    });

    test('toMap converts correctly', () {
      final exerciseEntry = ExerciseEntry(
        name: 'Running',
        durationMinutes: 30,
        caloriesBurned: 300.0,
      );
      final map = exerciseEntry.toMap();

      expect(map['name'], equals('Running'));
      expect(map['durationMinutes'], equals(30));
      expect(map['caloriesBurned'], equals(300.0));
    });

    test('fromMap creates ExerciseEntry correctly', () {
      final map = {
        'name': 'Running',
        'durationMinutes': 30,
        'caloriesBurned': 300.0,
      };
      final exerciseEntry = ExerciseEntry.fromMap(map);

      expect(exerciseEntry.name, equals('Running'));
      expect(exerciseEntry.durationMinutes, equals(30));
      expect(exerciseEntry.caloriesBurned, equals(300.0));
    });
  });
}
