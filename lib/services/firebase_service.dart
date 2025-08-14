import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/daily_entry.dart';
import '../models/calorie_report.dart';
import '../models/weight_loss_goal.dart';

class FirebaseService extends ChangeNotifier {
  late final FirebaseFirestore _firestore;
  late final FirebaseFunctions _functions;

  // Collections
  static const String usersCollection = 'users';
  static const String dailyEntriesCollection = 'dailyEntries';
  static const String weightLossGoalsCollection = 'weightLossGoals';

  FirebaseService() {
    _initializeServices();
  }

  void _initializeServices() {
    _firestore = FirebaseFirestore.instance;
    _functions = FirebaseFunctions.instance;

    // Check if we should use emulators (for local development)
    const bool useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: false);

    if (useEmulators) {
      print('🧪 Using Firebase Emulators for local development');
      
      // Connect to Firestore emulator
      _firestore.useFirestoreEmulator('localhost', 8080);
      
      // Connect to Functions emulator
      _functions.useFunctionsEmulator('localhost', 5001);
      
      // Connect to Auth emulator
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    }
  }

  // Get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // User Profile Methods
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(profile.uid)
          .set(profile.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(profile.uid)
          .update(profile.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Daily Entry Methods
  Future<void> createOrUpdateDailyEntry(DailyEntry entry) async {
    try {
      final dateString = _formatDateString(entry.date);
      final docId = '${entry.uid}_$dateString';
      
      await _firestore
          .collection(dailyEntriesCollection)
          .doc(docId)
          .set(entry.copyWith(
            id: docId,
            updatedAt: DateTime.now(),
          ).toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save daily entry: $e');
    }
  }

  Future<DailyEntry?> getDailyEntry(String uid, DateTime date) async {
    try {
      final dateString = _formatDateString(date);
      final docId = '${uid}_$dateString';
      
      final doc = await _firestore
          .collection(dailyEntriesCollection)
          .doc(docId)
          .get();
      
      if (doc.exists) {
        return DailyEntry.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get daily entry: $e');
    }
  }

  Stream<DailyEntry?> getDailyEntryStream(String uid, DateTime date) {
    final dateString = _formatDateString(date);
    final docId = '${uid}_$dateString';
    
    return _firestore
        .collection(dailyEntriesCollection)
        .doc(docId)
        .snapshots()
        .map((doc) => doc.exists ? DailyEntry.fromFirestore(doc) : null);
  }

  Future<List<DailyEntry>> getDailyEntriesInRange(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _firestore
          .collection(dailyEntriesCollection)
          .where('uid', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      return query.docs.map((doc) => DailyEntry.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get daily entries: $e');
    }
  }

  // Add food entry to today's log
  Future<void> addFoodEntry(FoodEntry foodEntry) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final today = DateTime.now();
      final existingEntry = await getDailyEntry(_currentUserId!, today);
      
      if (existingEntry != null) {
        final updatedFoodEntries = [...existingEntry.foodEntries, foodEntry];
        await createOrUpdateDailyEntry(
          existingEntry.copyWith(foodEntries: updatedFoodEntries),
        );
      } else {
        final newEntry = DailyEntry(
          id: '',
          uid: _currentUserId!,
          date: today,
          foodEntries: [foodEntry],
          exerciseEntries: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createOrUpdateDailyEntry(newEntry);
      }
    } catch (e) {
      throw Exception('Failed to add food entry: $e');
    }
  }

  // Add exercise entry to today's log
  Future<void> addExerciseEntry(ExerciseEntry exerciseEntry) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final today = DateTime.now();
      final existingEntry = await getDailyEntry(_currentUserId!, today);
      
      if (existingEntry != null) {
        final updatedExerciseEntries = [...existingEntry.exerciseEntries, exerciseEntry];
        await createOrUpdateDailyEntry(
          existingEntry.copyWith(exerciseEntries: updatedExerciseEntries),
        );
      } else {
        final newEntry = DailyEntry(
          id: '',
          uid: _currentUserId!,
          date: today,
          foodEntries: [],
          exerciseEntries: [exerciseEntry],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createOrUpdateDailyEntry(newEntry);
      }
    } catch (e) {
      throw Exception('Failed to add exercise entry: $e');
    }
  }

  // Update weight for today
  Future<void> updateWeight(double weight) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final today = DateTime.now();
      final existingEntry = await getDailyEntry(_currentUserId!, today);
      
      if (existingEntry != null) {
        await createOrUpdateDailyEntry(
          existingEntry.copyWith(weight: weight),
        );
      } else {
        final newEntry = DailyEntry(
          id: '',
          uid: _currentUserId!,
          date: today,
          weight: weight,
          foodEntries: [],
          exerciseEntries: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createOrUpdateDailyEntry(newEntry);
      }
    } catch (e) {
      throw Exception('Failed to update weight: $e');
    }
  }

  // Cloud Functions
  Future<double> calculateBMR(String uid) async {
    try {
      // Check if using emulators
      const bool useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: false);

      if (useEmulators) {
        // Use HTTP endpoint for emulator to avoid auth issues
        final response = await _makeHttpRequest(
          'http://127.0.0.1:5001/fitness-tracker-p2025/us-central1/calculateBMRHttp',
          {'uid': uid},
        );
        return (response['bmr'] ?? 0).toDouble();
      } else {
        // Use callable function for production
        final callable = _functions.httpsCallable('calculateBMR');
        final result = await callable.call({'uid': uid});
        return (result.data['bmr'] ?? 0).toDouble();
      }
    } catch (e) {
      throw Exception('Failed to calculate BMR: $e');
    }
  }



  Future<CalorieReport> generateCalorieReport(String uid, String period) async {
    try {
      // Check if using emulators
      const bool useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: false);

      if (useEmulators) {
        // Use HTTP endpoint for emulator to avoid auth issues
        final response = await _generateCalorieReportHttp(uid, period);
        return CalorieReport.fromJson(response);
      } else {
        // Use callable function for production
        final callable = _functions.httpsCallable('generateCalorieReport');
        final result = await callable.call({
          'uid': uid,
          'period': period,
        });
        
        if (result.data == null) {
          throw Exception('Cloud function returned null data');
        }
        
        // Convert the data to a proper Map<String, dynamic>
        final rawData = result.data;
        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData as Map);
        
        // Ensure the data array is properly typed
        if (data['data'] != null) {
          final List<dynamic> dataList = List<dynamic>.from(data['data'] as List);
          data['data'] = dataList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
        
        return CalorieReport.fromJson(data);
      }
    } catch (e) {
      print('CalorieReport generation error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to generate calorie report: $e');
    }
  }

  // Helper method for HTTP endpoint calls (emulator only)
  Future<Map<String, dynamic>> _generateCalorieReportHttp(String uid, String period) async {
    try {
      final response = await _makeHttpRequest(
        'http://127.0.0.1:5001/fitness-tracker-p2025/us-central1/generateCalorieReportHttp',
        {'uid': uid, 'period': period},
      );
      return response;
    } catch (e) {
      throw Exception('Failed to call HTTP endpoint: $e');
    }
  }

  Future<Map<String, dynamic>> _makeHttpRequest(String url, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(url);
      if (kIsWeb) {
        // Use package:http on web (dart:io not supported)
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      } else {
        // Use dart:io HttpClient on mobile/desktop
        final request = await HttpClient().postUrl(uri);
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode(data));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          return jsonDecode(responseBody) as Map<String, dynamic>;
        }
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      throw Exception('HTTP request failed: $e');
    }
  }

  // Helper method to format date string (normalize to UTC date only)
  String _formatDateString(DateTime date) {
    // Normalize to UTC date only to prevent timezone issues
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    return '${utcDate.year}-${utcDate.month.toString().padLeft(2, '0')}-${utcDate.day.toString().padLeft(2, '0')}';
  }

  // Get today's summary
  Future<Map<String, dynamic>> getTodaySummary() async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final today = DateTime.now();
      
      // Get today's entry (might be null for new users)
      DailyEntry? todayEntry;
      try {
        todayEntry = await getDailyEntry(_currentUserId!, today);
      } catch (e) {
        // If there's a permission error, it means the document doesn't exist
        // which is fine for new users - continue with null
        print('No daily entry found for today (expected for new users): $e');
      }
      
      // Calculate BMR (this should work as long as user profile exists)
      double bmr = 0.0;
      try {
        bmr = await calculateBMR(_currentUserId!);
      } catch (e) {
        // If BMR calculation fails, use a default value
        print('BMR calculation failed, using default: $e');
        bmr = 1500.0; // Default BMR
      }
      
      final caloriesConsumed = todayEntry?.totalCaloriesConsumed ?? 0.0;
      final caloriesBurned = todayEntry?.totalCaloriesBurned ?? 0.0;
      
      // Calculate net deficit based on weight loss goal if available
      // For weight loss: negative deficit = good (eating less than target)
      // For maintenance: deficit near 0 = good
      double netDeficit;
      double? targetDailyCalories;
      
      try {
        final goal = await getActiveWeightLossGoal();
        if (goal != null) {
          // With weight loss goal: Target = BMR - required deficit + exercise
          targetDailyCalories = goal.targetDailyCalories(bmr);
          netDeficit = (targetDailyCalories + caloriesBurned) - caloriesConsumed;
        } else {
          // Without goal: Target = BMR + exercise (maintenance)
          targetDailyCalories = bmr + caloriesBurned;
          netDeficit = targetDailyCalories - caloriesConsumed;
        }
      } catch (e) {
        // Fallback: maintenance mode
        targetDailyCalories = bmr + caloriesBurned;
        netDeficit = targetDailyCalories - caloriesConsumed;
      }
      
      return {
        'bmr': bmr,
        'caloriesConsumed': caloriesConsumed,
        'caloriesBurned': caloriesBurned,
        'netDeficit': netDeficit,
        'targetDailyCalories': targetDailyCalories,
        'weight': todayEntry?.weight,
        'foodEntries': todayEntry?.foodEntries ?? [],
        'exerciseEntries': todayEntry?.exerciseEntries ?? [],
      };
    } catch (e) {
      // Return default values for new users instead of throwing
      print('Using default summary for new user: $e');
      return {
        'bmr': 1500.0,
        'caloriesConsumed': 0.0,
        'caloriesBurned': 0.0,
        'netDeficit': 0.0,
        'targetDailyCalories': 1500.0,
        'weight': null,
        'foodEntries': [],
        'exerciseEntries': [],
      };
    }
  }

  // Reset/Delete user data for testing
  Future<void> deleteAllUserData() async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      // Delete user profile
      await _firestore.collection(usersCollection).doc(_currentUserId!).delete();
      
      // Delete all daily entries for this user
      final dailyEntriesQuery = await _firestore
          .collection(dailyEntriesCollection)
          .where('uid', isEqualTo: _currentUserId!)
          .get();
      
      for (final doc in dailyEntriesQuery.docs) {
        await doc.reference.delete();
      }
      
      // Delete weight loss goals
      await _firestore.collection(weightLossGoalsCollection).doc(_currentUserId!).delete();
      
      print('All user data deleted successfully');
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  // Weight Loss Goal Methods
  Future<void> saveWeightLossGoal(WeightLossGoal goal) async {
    try {
      await _firestore
          .collection(weightLossGoalsCollection)
          .doc(goal.uid)
          .set(goal.toFirestore());
    } catch (e) {
      throw Exception('Failed to save weight loss goal: $e');
    }
  }

  Future<WeightLossGoal?> getActiveWeightLossGoal() async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final doc = await _firestore
          .collection(weightLossGoalsCollection)
          .doc(_currentUserId!)
          .get();
      
      if (doc.exists) {
        final goal = WeightLossGoal.fromFirestore(doc);
        return goal.isActive ? goal : null;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get weight loss goal: $e');
    }
  }

  Future<WeightLossGoal?> getUserWeightLossGoal(String uid) async {
    try {
      final doc = await _firestore
          .collection(weightLossGoalsCollection)
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return WeightLossGoal.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user weight loss goal: $e');
    }
  }

  // Updated getTodaySummary to include weight loss goal context
  Future<Map<String, dynamic>> getTodaySummaryWithGoal() async {
    return getSummaryForDate(DateTime.now());
  }

  // Get summary for a specific date (used by dashboard navigation)
  Future<Map<String, dynamic>> getSummaryForDate(DateTime date) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      // Get entry for specified date
      DailyEntry? dayEntry;
      try {
        dayEntry = await getDailyEntry(_currentUserId!, date);
      } catch (e) {
        print('No daily entry found for ${date.toString()}: $e');
      }
      
      // Get weight loss goal
      WeightLossGoal? goal;
      try {
        goal = await getActiveWeightLossGoal();
      } catch (e) {
        print('No weight loss goal found: $e');
      }
      
      // Calculate BMR
      double bmr = 0.0;
      try {
        bmr = await calculateBMR(_currentUserId!);
      } catch (e) {
        print('BMR calculation failed, using default: $e');
        bmr = 1500.0;
      }
      
      final caloriesConsumed = dayEntry?.totalCaloriesConsumed ?? 0.0;
      final caloriesBurned = dayEntry?.totalCaloriesBurned ?? 0.0;
      
      // Calculate net deficit with weight loss goal context
      double netDeficit;
      double? targetDailyCalories;
      
      if (goal != null) {
        // With weight loss goal: Target + exercise - consumed
        targetDailyCalories = goal.targetDailyCalories(bmr);
        netDeficit = (targetDailyCalories + caloriesBurned) - caloriesConsumed;
      } else {
        // Without goal: maintenance mode (BMR + exercise)
        targetDailyCalories = bmr + caloriesBurned;
        netDeficit = targetDailyCalories - caloriesConsumed;
      }
      
      return {
        'bmr': bmr,
        'caloriesConsumed': caloriesConsumed,
        'caloriesBurned': caloriesBurned,
        'netDeficit': netDeficit,
        'weight': dayEntry?.weight,
        'foodEntries': dayEntry?.foodEntries ?? [],
        'exerciseEntries': dayEntry?.exerciseEntries ?? [],
        'weightLossGoal': goal,
        'targetDailyCalories': targetDailyCalories,
      };
    } catch (e) {
      print('Using default summary for new user: $e');
      return {
        'bmr': 1500.0,
        'caloriesConsumed': 0.0,
        'caloriesBurned': 0.0,
        'netDeficit': 0.0,
        'weight': null,
        'foodEntries': [],
        'exerciseEntries': [],
        'weightLossGoal': null,
        'targetDailyCalories': 1500.0,
      };
    }
  }
} 