import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/daily_entry.dart';
import '../widgets/profile_menu_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Date selection
  DateTime _selectedDate = DateTime.now();
  
  // Weight
  final _weightController = TextEditingController();
  
  // Glasses (cups of water)
  final _glassesController = TextEditingController();
  
  // Meal controllers - simplified to just calories
  final _breakfastCaloriesController = TextEditingController();
  final _lunchCaloriesController = TextEditingController();
  final _dinnerCaloriesController = TextEditingController();
  final _snacksCaloriesController = TextEditingController();

  // Exercise - simplified to single input
  final _exerciseCaloriesController = TextEditingController();
  
  bool _isLoading = false;
  DailyEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _glassesController.dispose();
    _breakfastCaloriesController.dispose();
    _lunchCaloriesController.dispose();
    _dinnerCaloriesController.dispose();
    _snacksCaloriesController.dispose();
    _exerciseCaloriesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      final firebaseService = context.read<FirebaseService>();
      // Use FirebaseAuth directly since _currentUserId is private
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final entry = await firebaseService.getDailyEntry(uid, _selectedDate);
        
        setState(() {
          _existingEntry = entry;
          
          if (entry != null) {
            // Load existing data
            _weightController.text = entry.weight?.toString() ?? '';
            _glassesController.text = entry.glasses?.toString() ?? '';
            
            // Clear all meal fields first
            _breakfastCaloriesController.clear();
            _lunchCaloriesController.clear();
            _dinnerCaloriesController.clear();
            _snacksCaloriesController.clear();
            _exerciseCaloriesController.clear();
            
            // Load food entries - simplified
            for (var food in entry.foodEntries) {
              switch (food.mealType?.toLowerCase()) {
                case 'breakfast':
                  _breakfastCaloriesController.text = food.calories.toString();
                  break;
                case 'lunch':
                  _lunchCaloriesController.text = food.calories.toString();
                  break;
                case 'dinner':
                  _dinnerCaloriesController.text = food.calories.toString();
                  break;
                case 'snacks':
                  _snacksCaloriesController.text = food.calories.toString();
                  break;
              }
            }
            
            // Load exercise entries - simplified
            if (entry.exerciseEntries.isNotEmpty) {
              final totalCaloriesBurned = entry.exerciseEntries.fold(0.0, (sum, exercise) => sum + exercise.caloriesBurned);
              _exerciseCaloriesController.text = totalCaloriesBurned.toString();
            }
          } else {
            // No existing entry - clear all fields
            _weightController.clear();
            _glassesController.clear();
            _breakfastCaloriesController.clear();
            _lunchCaloriesController.clear();
            _dinnerCaloriesController.clear();
            _snacksCaloriesController.clear();
            _exerciseCaloriesController.clear();
          }
        });
      }
    } catch (e) {
      print('Error loading existing data: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Select date for log entry',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadExistingData(); // Reload data for new date
    }
  }

  void _navigateToPreviousDay() {
    final previousDay = _selectedDate.subtract(const Duration(days: 1));
    // Don't allow going beyond 365 days ago
    final earliestDate = DateTime.now().subtract(const Duration(days: 365));
    if (previousDay.isAfter(earliestDate) || previousDay.isAtSameMomentAs(earliestDate)) {
      setState(() {
        _selectedDate = previousDay;
      });
      _loadExistingData();
    }
  }

  void _navigateToNextDay() {
    final nextDay = _selectedDate.add(const Duration(days: 1));
    final today = DateTime.now();
    // Don't allow going beyond today
    if (nextDay.isBefore(today) || nextDay.isAtSameMomentAs(today)) {
      setState(() {
        _selectedDate = nextDay;
      });
      _loadExistingData();
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = context.read<FirebaseService>();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      // Prepare food entries
      List<FoodEntry> foodEntries = [];
      
      if (_breakfastCaloriesController.text.isNotEmpty) {
        foodEntries.add(FoodEntry(
          name: 'Breakfast', // Meal name is not saved, only calories
          calories: double.parse(_breakfastCaloriesController.text),
          mealType: 'Breakfast',
        ));
      }
      
      if (_lunchCaloriesController.text.isNotEmpty) {
        foodEntries.add(FoodEntry(
          name: 'Lunch', // Meal name is not saved, only calories
          calories: double.parse(_lunchCaloriesController.text),
          mealType: 'Lunch',
        ));
      }
      
      if (_dinnerCaloriesController.text.isNotEmpty) {
        foodEntries.add(FoodEntry(
          name: 'Dinner', // Meal name is not saved, only calories
          calories: double.parse(_dinnerCaloriesController.text),
          mealType: 'Dinner',
        ));
      }
      
      if (_snacksCaloriesController.text.isNotEmpty) {
        foodEntries.add(FoodEntry(
          name: 'Snacks', // Meal name is not saved, only calories
          calories: double.parse(_snacksCaloriesController.text),
          mealType: 'Snacks',
        ));
      }

      // Prepare exercise entries - simplified
      List<ExerciseEntry> exerciseEntries = [];
      if (_exerciseCaloriesController.text.isNotEmpty) {
        exerciseEntries.add(ExerciseEntry(
          name: 'Exercise',
          caloriesBurned: double.parse(_exerciseCaloriesController.text),
          durationMinutes: 30, // Default duration
        ));
      }

      // Create or update daily entry
      final entry = DailyEntry(
        id: _existingEntry?.id ?? '',
        uid: uid,
        date: _selectedDate,
        weight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        glasses: _glassesController.text.isNotEmpty ? double.parse(_glassesController.text) : null,
        foodEntries: foodEntries,
        exerciseEntries: exerciseEntries,
        createdAt: _existingEntry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await firebaseService.createOrUpdateDailyEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily log saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Log'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEntry,
            child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          // Profile icon with dropdown
          const ProfileMenuWidget(),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date Selection with Navigation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Previous day button - larger
                        IconButton(
                          onPressed: () {
                            final earliestDate = DateTime.now().subtract(const Duration(days: 365));
                            final previousDay = _selectedDate.subtract(const Duration(days: 1));
                            if (previousDay.isAfter(earliestDate) || previousDay.isAtSameMomentAs(earliestDate)) {
                              _navigateToPreviousDay();
                            }
                          },
                          icon: Icon(
                            Icons.chevron_left,
                            size: 32, // Larger arrow
                            color: () {
                              final earliestDate = DateTime.now().subtract(const Duration(days: 365));
                              final previousDay = _selectedDate.subtract(const Duration(days: 1));
                              return (previousDay.isAfter(earliestDate) || previousDay.isAtSameMomentAs(earliestDate)) 
                                  ? Colors.blue 
                                  : Colors.grey;
                            }(),
                          ),
                          tooltip: 'Previous day',
                        ),
                        
                        // Date display - tappable to open calendar
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE, MMM d, y').format(_selectedDate), // Shortened format
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit_calendar, size: 18, color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Next day button - larger
                        IconButton(
                          onPressed: () {
                            final today = DateTime.now();
                            final nextDay = _selectedDate.add(const Duration(days: 1));
                            if (nextDay.isBefore(today) || nextDay.isAtSameMomentAs(today)) {
                              _navigateToNextDay();
                            }
                          },
                          icon: Icon(
                            Icons.chevron_right,
                            size: 32, // Larger arrow
                            color: () {
                              final today = DateTime.now();
                              final nextDay = _selectedDate.add(const Duration(days: 1));
                              return (nextDay.isBefore(today) || nextDay.isAtSameMomentAs(today)) 
                                  ? Colors.blue 
                                  : Colors.grey;
                            }(),
                          ),
                          tooltip: 'Next day',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Meals Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Meals',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Breakfast
                    _buildMealRow('Breakfast', _breakfastCaloriesController),
                    const SizedBox(height: 12),
                    
                    // Lunch
                    _buildMealRow('Lunch', _lunchCaloriesController),
                    const SizedBox(height: 12),
                    
                    // Dinner
                    _buildMealRow('Dinner', _dinnerCaloriesController),
                    const SizedBox(height: 12),
                    
                    // Snacks
                    _buildMealRow('Snacks', _snacksCaloriesController),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Exercise Section - simplified
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          'Exercise',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _exerciseCaloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calories Burned',
                        border: OutlineInputBorder(),
                        suffixText: 'cal',
                        hintText: '0',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final calories = double.tryParse(value);
                          if (calories == null || calories < 0) {
                            return 'Invalid calories';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Weight Section - moved to end
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monitor_weight, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Weight',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (lbs)',
                        border: OutlineInputBorder(),
                        suffixText: 'lbs',
                        hintText: 'Optional',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0 || weight > 1100) {
                            return 'Please enter a valid weight';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Water Intake Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_drink, color: Colors.cyan),
                        const SizedBox(width: 8),
                        Text(
                          'Water Intake',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _glassesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Glasses of Water',
                        border: OutlineInputBorder(),
                        suffixText: 'glasses',
                        hintText: 'Optional',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final glasses = double.tryParse(value);
                          if (glasses == null || glasses < 0 || glasses > 50) {
                            return 'Please enter a valid number of glasses';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Save Daily Log',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealRow(String mealName, TextEditingController caloriesController) {
    return Row(
      children: [
        // Meal name label - wider to prevent wrapping
        SizedBox(
          width: 100,
          child: Text(
            mealName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis, // Prevent wrapping
          ),
        ),
        const SizedBox(width: 12),
        // Calories input
        Expanded(
          child: TextFormField(
            controller: caloriesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calories',
              border: OutlineInputBorder(),
              suffixText: 'cal',
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final calories = double.tryParse(value);
                if (calories == null || calories < 0) {
                  return 'Invalid calories';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
} 