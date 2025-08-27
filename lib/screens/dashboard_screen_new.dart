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

  // Beautiful Header Section
  Widget _buildHeaderSection() {
    final user = context.read<AuthService>().currentUser;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1565C0),
            const Color(0xFF0D47A1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello 👋',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email?.split('@')[0] ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ProfileMenuWidget(),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isToday() ? 'Today' : DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
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

  // Compact Date Navigation
  Widget _buildDateNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _buildDateNavButton(
            Icons.chevron_left,
            () {
              final earliestDate = DateTime.now().subtract(const Duration(days: 365));
              final previousDay = _selectedDate.subtract(const Duration(days: 1));
              if (previousDay.isAfter(earliestDate) || previousDay.isAtSameMomentAs(earliestDate)) {
                _navigateToPreviousDay();
              }
            },
            enabled: () {
              final earliestDate = DateTime.now().subtract(const Duration(days: 365));
              final previousDay = _selectedDate.subtract(const Duration(days: 1));
              return previousDay.isAfter(earliestDate) || previousDay.isAtSameMomentAs(earliestDate);
            }(),
          ),
          Expanded(
            child: Text(
              DateFormat('EEEE, MMMM d').format(_selectedDate),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildDateNavButton(
            Icons.chevron_right,
            () {
              final today = DateTime.now();
              final nextDay = _selectedDate.add(const Duration(days: 1));
              if (nextDay.isBefore(today) || nextDay.isAtSameMomentAs(today)) {
                _navigateToNextDay();
              }
            },
            enabled: () {
              final today = DateTime.now();
              final nextDay = _selectedDate.add(const Duration(days: 1));
              return nextDay.isBefore(today) || nextDay.isAtSameMomentAs(today);
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavButton(IconData icon, VoidCallback onPressed, {required bool enabled}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // Compact Summary Grid - Smaller tiles
  Widget _buildSummaryGrid(double bmr, double caloriesConsumed, double caloriesBurned, double netDeficit) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5, // Made taller/more compact
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildCompactSummaryCard(
          'BMR',
          '${bmr.round()}',
          'kcal',
          const Color(0xFF3B82F6),
          Icons.local_fire_department,
        ),
        _buildCompactSummaryCard(
          'Net Deficit',
          '${netDeficit.round()}',
          'kcal',
          netDeficit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          Icons.trending_up,
        ),
        _buildCompactSummaryCard(
          'Consumed',
          '${caloriesConsumed.round()}',
          'kcal',
          const Color(0xFFF59E0B),
          Icons.restaurant,
        ),
        _buildCompactSummaryCard(
          'Burned',
          '${caloriesBurned.round()}',
          'kcal',
          const Color(0xFF8B5CF6),
          Icons.fitness_center,
        ),
      ],
    );
  }

  // Compact Summary Card - Much smaller and elegant
  Widget _buildCompactSummaryCard(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 28, // Smaller icon container
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16, // Smaller icon
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10), // Reduced spacing
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 11, // Smaller text
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                      fontSize: 18, // Smaller number
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                      fontSize: 10, // Smaller unit
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Colors.white,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadTodaySummary,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful Header Section
              _buildHeaderSection(),
              
              // Main Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Navigation
                    _buildDateNavigation(),
                    const SizedBox(height: 20),
                    
                    // Summary Cards Grid - Smaller and more elegant
                    _buildSummaryGrid(bmr, caloriesConsumed, caloriesBurned, netDeficit),
                    const SizedBox(height: 20),

                    // Weight Card (if available)
                    if (weight != null) ...[
                      _buildWeightCard(weight),
                      const SizedBox(height: 20),
                    ],

                    // Quick Actions Section
                    _buildQuickActionsSection(),

                    // Entries sections (simplified)
                    if (foodEntries.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildEntriesSection(
                        _isToday() ? 'Today\'s Food' : 'Food Entries',
                        Icons.restaurant,
                        foodEntries.map((entry) => 
                          '${entry.name} - ${entry.calories.round()} kcal'
                        ).toList(),
                      ),
                    ],

                    if (exerciseEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildEntriesSection(
                        _isToday() ? 'Today\'s Exercise' : 'Exercise Entries',
                        Icons.fitness_center,
                        exerciseEntries.map((entry) => 
                          '${entry.name} - ${entry.caloriesBurned.round()} kcal (${entry.durationMinutes} min)'
                        ).toList(),
                      ),
                    ],

                    // No entries message
                    if (foodEntries.isEmpty && exerciseEntries.isEmpty) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.timeline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isToday() ? 'No entries today' : 'No entries for this date',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isToday() 
                                  ? 'Start logging your food and exercise'
                                  : 'No data found for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Elegant Weight Card
  Widget _buildWeightCard(double weight) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_weight,
                color: Color(0xFF6366F1),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Weight',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: weight.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        TextSpan(
                          text: ' lbs',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  // Modern Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        
        // Daily Log Button
        _buildActionButton(
          'Daily Log Entry',
          'Track your food, exercise, and weight',
          Icons.edit_calendar,
          const Color(0xFF3B82F6),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyLogScreen(),
              ),
            ).then((_) => _loadTodaySummary());
          },
        ),
        const SizedBox(height: 12),
        
        // Reports Button
        _buildActionButton(
          'View Reports',
          'Analyze your progress and trends',
          Icons.analytics,
          const Color(0xFF10B981),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  // Modern Action Button
  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesSection(String title, IconData icon, List<String> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...entries.take(3).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $entry',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF374151),
                ),
              ),
            )),
            if (entries.length > 3)
              Text(
                'and ${entries.length - 3} more...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
          ],
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