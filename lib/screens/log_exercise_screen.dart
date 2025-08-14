import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/daily_entry.dart';

class LogExerciseScreen extends StatefulWidget {
  const LogExerciseScreen({super.key});

  @override
  State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveExerciseEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final exerciseEntry = ExerciseEntry(
        name: _nameController.text.trim(),
        caloriesBurned: double.parse(_caloriesController.text),
        durationMinutes: int.parse(_durationController.text),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      await context.read<FirebaseService>().addExerciseEntry(exerciseEntry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise entry added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add exercise entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Exercise'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExerciseEntry,
            child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Exercise Entry',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Log your workout activity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Exercise Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Running, Weight Training',
                  prefixIcon: Icon(Icons.directions_run),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the exercise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duration Field
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g., 30',
                  prefixIcon: Icon(Icons.timer),
                  border: OutlineInputBorder(),
                  suffixText: 'minutes',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the duration';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Please enter a valid duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Calories Burned Field
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories Burned',
                  hintText: 'e.g., 300',
                  prefixIcon: Icon(Icons.local_fire_department),
                  border: OutlineInputBorder(),
                  suffixText: 'kcal',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter calories burned';
                  }
                  final calories = double.tryParse(value);
                  if (calories == null || calories <= 0) {
                    return 'Please enter a valid calorie amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field (Optional)
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Moderate intensity, outdoor',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Quick Add Buttons
              Text(
                'Quick Add',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAddChip('Walking (30 min)', 30, 150),
                  _buildQuickAddChip('Running (30 min)', 30, 300),
                  _buildQuickAddChip('Cycling (45 min)', 45, 400),
                  _buildQuickAddChip('Swimming (30 min)', 30, 350),
                  _buildQuickAddChip('Weight Training (45 min)', 45, 250),
                  _buildQuickAddChip('Yoga (60 min)', 60, 200),
                ],
              ),
              const Spacer(),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveExerciseEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Add Exercise Entry',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddChip(String name, int duration, int calories) {
    return ActionChip(
      label: Text('$name - ${calories}kcal'),
      onPressed: () {
        // Extract exercise name (before parentheses)
        final exerciseName = name.split(' (')[0];
        _nameController.text = exerciseName;
        _durationController.text = duration.toString();
        _caloriesController.text = calories.toString();
      },
      backgroundColor: Colors.purple.withOpacity(0.1),
      side: BorderSide(color: Colors.purple.withOpacity(0.3)),
    );
  }
} 