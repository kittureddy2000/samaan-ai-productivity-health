import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/daily_entry.dart';
import '../widgets/profile_menu_widget.dart';
import 'log_food_screen.dart';
import 'log_exercise_screen.dart';
import 'log_weight_screen.dart';
import 'reports_screen.dart';
import 'daily_log_screen.dart';
import 'profile_screen.dart';
import 'weight_loss_goal_screen.dart';
import '../models/weight_loss_goal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _todaySummary;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodaySummary();
  }

  Future<void> _loadTodaySummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await context.read<FirebaseService>().getSummaryForDate(_selectedDate);
      setState(() {
        _todaySummary = summary;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load summary: $e'),
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

  void _navigateToPreviousDay() {
    final previousDay = _selectedDate.subtract(const Duration(days: 1));
    // Don't allow going beyond 365 days ago
    final earliestDate = DateTime.now().subtract(const Duration(days: 365));
    if (previousDay.isAfter(earliestDate) || previousDay.isAtSameMomentAs(earliestDate)) {
      setState(() {
        _selectedDate = previousDay;
      });
      _loadTodaySummary();
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
      _loadTodaySummary();
    }
  }

  bool _isToday() {
    final today = DateTime.now();
    return _selectedDate.year == today.year &&
           _selectedDate.month == today.month &&
           _selectedDate.day == today.day;
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todaySummary == null) {
      return const Center(
        child: Text('Failed to load data. Please try again.'),
      );
    }

    final bmr = _todaySummary!['bmr'] ?? 0.0;
    final caloriesConsumed = _todaySummary!['caloriesConsumed'] ?? 0.0;
    final caloriesBurned = _todaySummary!['caloriesBurned'] ?? 0.0;
    final netDeficit = _todaySummary!['netDeficit'] ?? 0.0;
    final weight = _todaySummary!['weight'];
    final foodEntries = _todaySummary!['foodEntries'] as List<FoodEntry>;
    final exerciseEntries = _todaySummary!['exerciseEntries'] as List<ExerciseEntry>;
    final weightLossGoal = _todaySummary!['weightLossGoal'] as WeightLossGoal?;
    final targetDailyCalories = _todaySummary!['targetDailyCalories'] as double?;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.02),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadTodaySummary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Date Navigation
              Row(
              children: [
                // Previous day button
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
                    size: 28,
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
                
                // Date display
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Next day button
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
                    size: 28,
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
            const SizedBox(height: 16),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'BMR',
                    '${bmr.round()}',
                    'kcal',
                    Colors.blue,
                    Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Net Deficit',
                    '${netDeficit.round()}',
                    'kcal',
                    netDeficit >= 0 ? Colors.green : Colors.red,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Consumed',
                    '${caloriesConsumed.round()}',
                    'kcal',
                    Colors.orange,
                    Icons.restaurant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Burned',
                    '${caloriesBurned.round()}',
                    'kcal',
                    Colors.purple,
                    Icons.fitness_center,
                  ),
                ),
              ],
            ),

            if (weight != null) ...[
              const SizedBox(height: 12),
              _buildSummaryCard(
                'Current Weight',
                '${weight.toStringAsFixed(1)}',
                'lbs',
                Colors.indigo,
                Icons.monitor_weight,
                fullWidth: true,
              ),
            ],


            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Single Daily Log Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DailyLogScreen(),
                    ),
                  ).then((_) => _loadTodaySummary());
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Daily Log Entry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Reports Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Reports'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Weight Loss Goal Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeightLossGoalScreen(),
                    ),
                  ).then((_) => _loadTodaySummary());
                },
                icon: const Icon(Icons.flag),
                label: Text(weightLossGoal != null ? 'Update Goal' : 'Set Weight Loss Goal'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Selected Date's Entries
            if (foodEntries.isNotEmpty) ...[
              _buildEntriesSection(
                _isToday() ? 'Today\'s Food' : 'Food Entries',
                Icons.restaurant,
                foodEntries.map((entry) => 
                  '${entry.name} - ${entry.calories.round()} kcal'
                ).toList(),
              ),
              const SizedBox(height: 16),
            ],

            if (exerciseEntries.isNotEmpty) ...[
              _buildEntriesSection(
                _isToday() ? 'Today\'s Exercise' : 'Exercise Entries',
                Icons.fitness_center,
                exerciseEntries.map((entry) => 
                  '${entry.name} - ${entry.caloriesBurned.round()} kcal (${entry.durationMinutes} min)'
                ).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // If no entries today
            if (foodEntries.isEmpty && exerciseEntries.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isToday() ? 'No entries today' : 'No entries for this date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isToday() 
                            ? 'Start logging your food and exercise to track your progress'
                            : 'No food or exercise entries found for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withOpacity(0.03),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: fullWidth ? 24 : 20,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesSection(String title, IconData icon, List<String> entries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.take(3).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $entry',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )),
            if (entries.length > 3)
              Text(
                'and ${entries.length - 3} more...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogFood() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogFoodScreen()),
    );
    if (result == true) {
      _loadTodaySummary();
    }
  }

  void _navigateToLogExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogExerciseScreen()),
    );
    if (result == true) {
      _loadTodaySummary();
    }
  }

  void _navigateToLogWeight() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogWeightScreen()),
    );
    if (result == true) {
      _loadTodaySummary();
    }
  }

  Widget _buildGoalProgressCard(WeightLossGoal goal, double targetCalories, double consumedCalories) {
    final remainingCalories = targetCalories - consumedCalories;
    final progressPercentage = (consumedCalories / targetCalories * 100).clamp(0, 100);
    
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.indigo.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.flag, color: Colors.purple.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Weight Loss Goal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            
            // Goal summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Target: ${goal.targetWeight.toStringAsFixed(1)} lbs (-${goal.weightLossPerWeek.toStringAsFixed(1)} lbs/week)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Calorie targets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Calories',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${targetCalories.round()} cal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${remainingCalories.round()} cal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: remainingCalories > 0 ? Colors.orange.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress bar
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressPercentage <= 100 ? Colors.indigo.shade600 : Colors.orange.shade600,
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${progressPercentage.round()}% of daily target',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.purple.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardContent(),
      const ReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Fitness Tracker' : 'Reports'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        actions: [
          // Profile icon with dropdown
          const ProfileMenuWidget(),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
} 