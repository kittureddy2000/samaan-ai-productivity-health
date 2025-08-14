import 'package:cloud_firestore/cloud_firestore.dart';

class WeightLossGoal {
  final String uid;
  final double weightLossPerWeek; // in lbs per week
  final double targetWeight; // in lbs
  final double currentWeight; // in lbs
  final DateTime startDate;
  final DateTime? targetDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeightLossGoal({
    required this.uid,
    required this.weightLossPerWeek,
    required this.targetWeight,
    required this.currentWeight,
    required this.startDate,
    this.targetDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate daily calorie deficit needed
  double get dailyCalorieDeficit => weightLossPerWeek * 3500 / 7;

  // Calculate target daily calories (BMR - deficit)
  double targetDailyCalories(double bmr) => bmr - dailyCalorieDeficit;

  // Calculate estimated completion date
  DateTime get estimatedCompletionDate {
    if (targetDate != null) return targetDate!;
    
    final totalWeightToLose = currentWeight - targetWeight;
    final weeksNeeded = totalWeightToLose / weightLossPerWeek;
    return startDate.add(Duration(days: (weeksNeeded * 7).ceil()));
  }

  // Calculate progress percentage
  double getProgressPercentage(double latestWeight) {
    final totalWeightToLose = currentWeight - targetWeight;
    final weightLostSoFar = currentWeight - latestWeight;
    return (weightLostSoFar / totalWeightToLose * 100).clamp(0, 100);
  }

  // Check if goal is on track
  bool isOnTrack(double latestWeight, DateTime currentDate) {
    final daysSinceStart = currentDate.difference(startDate).inDays;
    final expectedWeightLoss = (daysSinceStart / 7) * weightLossPerWeek;
    final actualWeightLoss = currentWeight - latestWeight;
    
    // Allow 10% tolerance
    return actualWeightLoss >= (expectedWeightLoss * 0.9);
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'weightLossPerWeek': weightLossPerWeek,
      'targetWeight': targetWeight,
      'currentWeight': currentWeight,
      'startDate': Timestamp.fromDate(startDate),
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory WeightLossGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return WeightLossGoal(
      uid: data['uid'] as String? ?? '',
      weightLossPerWeek: _safeToDouble(data['weightLossPerWeek']) ?? 1.0,
      targetWeight: _safeToDouble(data['targetWeight']) ?? 150.0,
      currentWeight: _safeToDouble(data['currentWeight']) ?? 170.0,
      startDate: _safeTimestampToDate(data['startDate']),
      targetDate: data['targetDate'] != null ? _safeTimestampToDate(data['targetDate']) : null,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _safeTimestampToDate(data['createdAt']),
      updatedAt: _safeTimestampToDate(data['updatedAt']),
    );
  }

  static DateTime _safeTimestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
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

  // Create a copy with updated fields
  WeightLossGoal copyWith({
    String? uid,
    double? weightLossPerWeek,
    double? targetWeight,
    double? currentWeight,
    DateTime? startDate,
    DateTime? targetDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightLossGoal(
      uid: uid ?? this.uid,
      weightLossPerWeek: weightLossPerWeek ?? this.weightLossPerWeek,
      targetWeight: targetWeight ?? this.targetWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}