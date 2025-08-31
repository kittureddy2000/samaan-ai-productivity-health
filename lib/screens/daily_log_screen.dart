import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/daily_entry.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();

  final _weightController = TextEditingController();
  final _breakfastCaloriesController = TextEditingController();
  final _lunchCaloriesController = TextEditingController();
  final _dinnerCaloriesController = TextEditingController();
  final _snacksCaloriesController = TextEditingController();
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final entry = await firebaseService.getDailyEntry(uid, _selectedDate);

        setState(() {
          _existingEntry = entry;

          if (entry != null) {
            _weightController.text = entry.weight?.toString() ?? '';
            _breakfastCaloriesController.clear();
            _lunchCaloriesController.clear();
            _dinnerCaloriesController.clear();
            _snacksCaloriesController.clear();
            _exerciseCaloriesController.clear();

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

            if (entry.exerciseEntries.isNotEmpty) {
              final totalCaloriesBurned = entry.exerciseEntries
                  .fold(0.0, (sum, exercise) => sum + exercise.caloriesBurned);
              _exerciseCaloriesController.text = totalCaloriesBurned.toString();
            }
          } else {
            _weightController.clear();
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
      _loadExistingData();
    }
  }

  void _navigateToPreviousDay() {
    final previousDay = _selectedDate.subtract(const Duration(days: 1));
    final earliestDate = DateTime.now().subtract(const Duration(days: 365));
    if (previousDay.isAfter(earliestDate) ||
        previousDay.isAtSameMomentAs(earliestDate)) {
      setState(() {
        _selectedDate = previousDay;
      });
      _loadExistingData();
    }
  }

  void _navigateToNextDay() {
    final nextDay = _selectedDate.add(const Duration(days: 1));
    final today = DateTime.now();
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

      List<FoodEntry> foodEntries = [];
      _addFoodEntry(foodEntries, 'Breakfast', _breakfastCaloriesController);
      _addFoodEntry(foodEntries, 'Lunch', _lunchCaloriesController);
      _addFoodEntry(foodEntries, 'Dinner', _dinnerCaloriesController);
      _addFoodEntry(foodEntries, 'Snacks', _snacksCaloriesController);

      List<ExerciseEntry> exerciseEntries = [];
      if (_exerciseCaloriesController.text.isNotEmpty) {
        exerciseEntries.add(ExerciseEntry(
          name: 'Exercise',
          caloriesBurned: double.parse(_exerciseCaloriesController.text),
          durationMinutes: 30,
        ));
      }

      final entry = DailyEntry(
        id: _existingEntry?.id ?? '',
        uid: uid,
        date: _selectedDate,
        weight: _weightController.text.isNotEmpty
            ? double.parse(_weightController.text)
            : null,
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

  void _addFoodEntry(
      List<FoodEntry> list, String mealType, TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      list.add(FoodEntry(
        name: mealType,
        calories: double.parse(controller.text),
        mealType: mealType,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Log'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                FirebaseAuth.instance.currentUser?.email
                        ?.substring(0, 1)
                        .toUpperCase() ??
                    'U',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildDateSelector(),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meals',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildMealRow('Breakfast', _breakfastCaloriesController),
                    const SizedBox(height: 12),
                    _buildMealRow('Lunch', _lunchCaloriesController),
                    const SizedBox(height: 12),
                    _buildMealRow('Dinner', _dinnerCaloriesController),
                    const SizedBox(height: 12),
                    _buildMealRow('Snacks', _snacksCaloriesController),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercise',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildCustomTextField(
                      controller: _exerciseCaloriesController,
                      labelText: 'Calories Burned',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weight',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildCustomTextField(
                      controller: _weightController,
                      labelText: 'Weight (lbs)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEntry,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Daily Log'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: _navigateToPreviousDay,
          icon: const Icon(Icons.chevron_left, size: 28),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE, MMM d, y').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_calendar,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _navigateToNextDay,
          icon: const Icon(Icons.chevron_right, size: 28),
        ),
      ],
    );
  }

  Widget _buildMealRow(
      String mealName, TextEditingController caloriesController) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            mealName,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCustomTextField(
            controller: caloriesController,
            labelText: 'Calories',
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField(
      {required TextEditingController controller, required String labelText}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: labelText,
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final number = double.tryParse(value);
          if (number == null || number < 0) {
            return 'Invalid number';
          }
        }
        return null;
      },
    );
  }
}
