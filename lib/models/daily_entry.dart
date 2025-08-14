import 'package:cloud_firestore/cloud_firestore.dart';

class FoodEntry {
  final String name;
  final double calories;
  final String? description;
  final String? mealType; // breakfast, lunch, dinner, snacks

  FoodEntry({
    required this.name,
    required this.calories,
    this.description,
    this.mealType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'description': description,
      'mealType': mealType,
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      name: map['name'] as String? ?? '',
      calories: _safeToDouble(map['calories']) ?? 0.0,
      description: map['description'] as String?,
      mealType: map['mealType'] as String?,
    );
  }

  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ExerciseEntry {
  final String name;
  final double caloriesBurned;
  final int durationMinutes;
  final String? description;

  ExerciseEntry({
    required this.name,
    required this.caloriesBurned,
    required this.durationMinutes,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'caloriesBurned': caloriesBurned,
      'durationMinutes': durationMinutes,
      'description': description,
    };
  }

  factory ExerciseEntry.fromMap(Map<String, dynamic> map) {
    return ExerciseEntry(
      name: map['name'] as String? ?? '',
      caloriesBurned: _safeToDouble(map['caloriesBurned']) ?? 0.0,
      durationMinutes: _safeToInt(map['durationMinutes']) ?? 0,
      description: map['description'] as String?,
    );
  }

  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class DailyEntry {
  final String id;
  final String uid;
  final DateTime date;
  final double? weight; // in lbs
  final double? glasses; // glasses of water
  final List<FoodEntry> foodEntries;
  final List<ExerciseEntry> exerciseEntries;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyEntry({
    required this.id,
    required this.uid,
    required this.date,
    this.weight,
    this.glasses,
    required this.foodEntries,
    required this.exerciseEntries,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate total calories consumed
  double get totalCaloriesConsumed {
    return foodEntries.fold(0.0, (sum, entry) => sum + entry.calories);
  }

  // Calculate total calories burned
  double get totalCaloriesBurned {
    return exerciseEntries.fold(0.0, (sum, entry) => sum + entry.caloriesBurned);
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    // Normalize date to midnight UTC to avoid timezone confusion
    // This ensures Daily Log date and Reports date are consistent
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    
    return {
      'uid': uid,
      'date': Timestamp.fromDate(normalizedDate),
      'weight': weight,
      'glasses': glasses,
      'foodEntries': foodEntries.map((entry) => entry.toMap()).toList(),
      'exerciseEntries': exerciseEntries.map((entry) => entry.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory DailyEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    
    return DailyEntry(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      date: _safeTimestampToDate(data['date']),
      weight: _safeToDouble(data['weight']),
      glasses: _safeToDouble(data['glasses']),
      foodEntries: _safeFoodEntries(data['foodEntries']),
      exerciseEntries: _safeExerciseEntries(data['exerciseEntries']),
      createdAt: _safeTimestampToDate(data['createdAt']),
      updatedAt: _safeTimestampToDate(data['updatedAt']),
    );
  }

  static DateTime _safeTimestampToDate(dynamic value) {
    if (value is Timestamp) {
      final utcDate = value.toDate().toUtc();
      // Keep as local date components to match UI expectations
      return DateTime(utcDate.year, utcDate.month, utcDate.day);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<FoodEntry> _safeFoodEntries(dynamic value) {
    if (value is! List) return [];
    try {
      return value
          .cast<Map<String, dynamic>>()
          .map((item) => FoodEntry.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static List<ExerciseEntry> _safeExerciseEntries(dynamic value) {
    if (value is! List) return [];
    try {
      return value
          .cast<Map<String, dynamic>>()
          .map((item) => ExerciseEntry.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Create a copy with updated fields
  DailyEntry copyWith({
    String? id,
    String? uid,
    DateTime? date,
    double? weight,
    double? glasses,
    List<FoodEntry>? foodEntries,
    List<ExerciseEntry>? exerciseEntries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      glasses: glasses ?? this.glasses,
      foodEntries: foodEntries ?? this.foodEntries,
      exerciseEntries: exerciseEntries ?? this.exerciseEntries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 