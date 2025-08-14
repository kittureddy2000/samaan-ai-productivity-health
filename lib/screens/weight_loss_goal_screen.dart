import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/weight_loss_goal.dart';
import '../widgets/profile_menu_widget.dart';

class WeightLossGoalScreen extends StatefulWidget {
  const WeightLossGoalScreen({super.key});

  @override
  State<WeightLossGoalScreen> createState() => _WeightLossGoalScreenState();
}

class _WeightLossGoalScreenState extends State<WeightLossGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetWeightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  
  double _weightLossPerWeek = 1.0; // Default 1 lb per week
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;
  WeightLossGoal? _existingGoal;
  double _estimatedBMR = 2000; // Default, will be updated

  @override
  void initState() {
    super.initState();
    _loadExistingGoal();
    _loadBMR();
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    _currentWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingGoal() async {
    try {
      final goal = await context.read<FirebaseService>().getActiveWeightLossGoal();
      if (goal != null) {
        setState(() {
          _existingGoal = goal;
          _targetWeightController.text = goal.targetWeight.toString();
          _currentWeightController.text = goal.currentWeight.toString();
          _weightLossPerWeek = goal.weightLossPerWeek;
          _startDate = goal.startDate;
        });
      }
    } catch (e) {
      print('Error loading existing goal: $e');
    }
  }

  Future<void> _loadBMR() async {
    try {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        final bmr = await context.read<FirebaseService>().calculateBMR(user.uid);
        setState(() {
          _estimatedBMR = bmr;
        });
      }
    } catch (e) {
      print('Error loading BMR: $e');
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select start date for your goal',
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) throw Exception('User not authenticated');

      final goal = WeightLossGoal(
        uid: user.uid,
        weightLossPerWeek: _weightLossPerWeek,
        targetWeight: double.parse(_targetWeightController.text),
        currentWeight: double.parse(_currentWeightController.text),
        startDate: _startDate,
        isActive: true,
        createdAt: _existingGoal?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await context.read<FirebaseService>().saveWeightLossGoal(goal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight loss goal saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal: $e'),
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

  double get _dailyCalorieDeficit => _weightLossPerWeek * 3500 / 7;
  double get _targetDailyCalories => _estimatedBMR - _dailyCalorieDeficit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Loss Goal'),
        actions: [
          const ProfileMenuWidget(),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Set Your Weight Loss Goal',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a personalized diet plan based on your weight loss target',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Current Weight
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
                          'Current Weight',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _currentWeightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Current Weight (lbs)',
                        border: OutlineInputBorder(),
                        suffixText: 'lbs',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current weight';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 1100) {
                          return 'Please enter a valid weight';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Target Weight
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.track_changes, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Target Weight',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetWeightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Weight (lbs)',
                        border: OutlineInputBorder(),
                        suffixText: 'lbs',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your target weight';
                        }
                        final targetWeight = double.tryParse(value);
                        final currentWeight = double.tryParse(_currentWeightController.text);
                        
                        if (targetWeight == null || targetWeight <= 0 || targetWeight > 1100) {
                          return 'Please enter a valid weight';
                        }
                        
                        if (currentWeight != null && targetWeight >= currentWeight) {
                          return 'Target weight must be less than current weight';
                        }
                        
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Weight Loss Rate
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Weight Loss Rate',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_weightLossPerWeek.toStringAsFixed(1)} lbs per week',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _weightLossPerWeek,
                      min: 0.5,
                      max: 3.0,
                      divisions: 10,
                      label: '${_weightLossPerWeek.toStringAsFixed(1)} lbs/week',
                      onChanged: (value) {
                        setState(() {
                          _weightLossPerWeek = value;
                        });
                      },
                    ),
                    Text(
                      'Recommended: 1-2 lbs per week for safe weight loss',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Calorie Calculation Summary
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Calorie Plan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildCalorieSummaryRow(
                      'Your BMR (Base Metabolic Rate)',
                      '${_estimatedBMR.round()} cal',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildCalorieSummaryRow(
                      'Daily Calorie Deficit Needed',
                      '${_dailyCalorieDeficit.round()} cal',
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildCalorieSummaryRow(
                      'Target Daily Calories',
                      '${_targetDailyCalories.round()} cal',
                      Colors.green,
                      isTotal: true,
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Formula: Target Calories = BMR - (${_weightLossPerWeek.toStringAsFixed(1)} lbs × 3500 ÷ 7 days)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start Date
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          'Start Date',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Icon(Icons.edit_calendar),
                          ],
                        ),
                      ),
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
                onPressed: _isLoading ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _existingGoal != null ? 'Update Goal' : 'Set Goal',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieSummaryRow(String label, String value, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }
}