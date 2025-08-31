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
      final summary = await context
          .read<FirebaseService>()
          .getSummaryForDate(_selectedDate);
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
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadTodaySummary();
  }

  void _navigateToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadTodaySummary();
  }

  bool _isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Widget _buildDateNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _navigateToPreviousDay,
          ),
          Text(
            DateFormat('EEEE, MMMM d').format(_selectedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday() ? null : _navigateToNextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(double bmr, double caloriesConsumed,
      double caloriesBurned, double netDeficit) {
    final List<Map<String, dynamic>> summaryItems = [
      {
        'title': 'BMR',
        'value': '${bmr.round()}',
        'unit': 'kcal',
        'color': const Color(0xFF3B82F6),
        'icon': Icons.local_fire_department,
      },
      {
        'title': 'Net Deficit',
        'value': '${netDeficit.round()}',
        'unit': 'kcal',
        'color':
            netDeficit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        'icon': Icons.trending_up,
      },
      {
        'title': 'Consumed',
        'value': '${caloriesConsumed.round()}',
        'unit': 'kcal',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.restaurant,
      },
      {
        'title': 'Burned',
        'value': '${caloriesBurned.round()}',
        'unit': 'kcal',
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.fitness_center,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: constraints.maxWidth > 800 ? 400 : 350,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: summaryItems.length,
          itemBuilder: (context, index) {
            final item = summaryItems[index];
            return _buildCompactSummaryCard(
              item['title'],
              item['value'],
              item['unit'],
              item['color'],
              item['icon'],
            );
          },
        );
      },
    );
  }

  Widget _buildCompactSummaryCard(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  TextSpan(text: ' $unit'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    final exerciseEntries =
        _todaySummary!['exerciseEntries'] as List<ExerciseEntry>;

    return RefreshIndicator(
      onRefresh: _loadTodaySummary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateNavigation(),
          const SizedBox(height: 16),
          _buildSummaryGrid(bmr, caloriesConsumed, caloriesBurned, netDeficit),
          const SizedBox(height: 16),
          if (weight != null) ...[
            _buildWeightCard(weight),
            const SizedBox(height: 16),
          ],
          _buildQuickActionsSection(),
          if (foodEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildEntriesSection(
              _isToday() ? 'Today\'s Food' : 'Food Entries',
              Icons.restaurant,
              foodEntries
                  .map((entry) =>
                      '${entry.name} - ${entry.calories.round()} kcal')
                  .toList(),
            ),
          ],
          if (exerciseEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildEntriesSection(
              _isToday() ? 'Today\'s Exercise' : 'Exercise Entries',
              Icons.fitness_center,
              exerciseEntries
                  .map((entry) =>
                      '${entry.name} - ${entry.caloriesBurned.round()} kcal (${entry.durationMinutes} min)')
                  .toList(),
            ),
          ],
          if (foodEntries.isEmpty && exerciseEntries.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isToday()
                        ? 'No entries today'
                        : 'No entries for this date',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isToday()
                        ? 'Start logging your food and exercise'
                        : 'No data found for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWeightCard(double weight) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.monitor_weight,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Weight',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge,
                      children: [
                        TextSpan(
                          text: weight.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const TextSpan(text: ' lbs'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Daily Log Entry',
              'Track your food, exercise, and weight',
              Icons.edit_calendar,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DailyLogScreen()),
                ).then((_) => _loadTodaySummary());
              },
            ),
            const Divider(height: 1),
            _buildActionButton(
              'View Reports',
              'Analyze your progress and trends',
              Icons.analytics,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReportsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesSection(
      String title, IconData icon, List<String> entries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.take(3).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $entry',
                      style: Theme.of(context).textTheme.bodyMedium),
                )),
            if (entries.length > 3)
              Text(
                'and ${entries.length - 3} more...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Scaffold(
        appBar: AppBar(
          title: const Text('Fitness Tracker'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: const [
            ProfileMenuWidget(),
          ],
        ),
        body: _buildDashboardContent(),
      ),
      const ReportsScreen(),
    ];

    return Scaffold(
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
        type: BottomNavigationBarType.fixed,
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
