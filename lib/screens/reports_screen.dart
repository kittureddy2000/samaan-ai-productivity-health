import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/logger.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/calorie_report.dart';
import 'daily_log_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with WidgetsBindingObserver {
  String _selectedPeriod = 'weekly';
  String _selectedReportType = 'calories'; // 'calories', 'weight', or 'glasses'
  CalorieReport? _currentReport;
  bool _isLoading = false;
  double? _liveBMR; // Store live BMR calculation
  
  // Navigation state for weekly reports
  DateTime _currentWeekStart = DateTime.now();
  
  // Date selection for monthly/yearly reports
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedYear = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDates();
    _loadReport();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app becomes active again
      _loadReport();
    }
  }
  
  // Public method to refresh reports (can be called from parent widgets)
  void refreshReports() {
    _loadReport();
  }
  
  void _initializeDates() {
    final now = DateTime.now();
    
    // Set current week start to last Wednesday
    _currentWeekStart = _getWeekStart(now);
    _selectedMonth = DateTime(now.year, now.month, 1);
    _selectedYear = DateTime(now.year, 1, 1);
  }
  
  DateTime _getWeekStart(DateTime date) {
    // Find the Wednesday that starts the current week
    final dayOfWeek = date.weekday; // Monday = 1, Sunday = 7
    final daysFromWednesday = (dayOfWeek + 4) % 7; // Wednesday = 0
    return date.subtract(Duration(days: daysFromWednesday));
  }
  
  
  CalorieReport _filterMonthlyDataForWeek(CalorieReport monthlyReport, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    Log.d('Filtering monthly data for week: ${weekStart.toString().split(' ')[0]} to ${weekEnd.toString().split(' ')[0]}');
    Log.d('Monthly report has ${monthlyReport.data.length} total entries');
    
    // Filter monthly data for the specific week
    final weekData = monthlyReport.data.where((data) {
      final entryDate = DateTime(data.date.year, data.date.month, data.date.day);
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEndDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
      
      final isInWeek = (entryDate.isAtSameMomentAs(weekStartDate) ||
                       entryDate.isAtSameMomentAs(weekEndDate) ||
                       (entryDate.isAfter(weekStartDate) && entryDate.isBefore(weekEndDate.add(const Duration(days: 1)))));
      
      if (isInWeek) {
        Log.d('week data ${entryDate.toString().split(' ')[0]}: ${data.caloriesConsumed}');
      }
      
      return isInWeek;
    }).toList();
    
    Log.d('Found ${weekData.length} entries for this week');
    
    // Recalculate totals for the week
    double totalCaloriesConsumed = 0;
    double totalCaloriesBurned = 0;
    double totalNetDeficit = 0;
    double totalBMR = 0;
    double totalGlasses = 0;
    
    for (final entry in weekData) {
      totalCaloriesConsumed += entry.caloriesConsumed;
      totalCaloriesBurned += entry.caloriesBurned;
      totalNetDeficit += entry.netCalorieDeficit;
      totalBMR += entry.bmr;
      totalGlasses += entry.glasses ?? 0;
    }
    
    final averageBMR = weekData.isNotEmpty ? totalBMR / weekData.length : monthlyReport.averageBMR;
    final averageGlasses = weekData.isNotEmpty ? totalGlasses / weekData.length : 0.0;
    
    return CalorieReport(
      period: 'weekly',
      startDate: weekStart,
      endDate: weekEnd,
      data: weekData,
      totalCaloriesConsumed: totalCaloriesConsumed,
      totalCaloriesBurned: totalCaloriesBurned,
      totalNetDeficit: totalNetDeficit,
      averageBMR: averageBMR,
      totalGlasses: totalGlasses,
      averageGlasses: averageGlasses,
      daysWithData: weekData.length,
      totalDays: 7,
    );
  }

  Future<void> _loadReport() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      CalorieReport report;
      
      // For now, let's use a simpler approach - get monthly data and filter it
      if (_selectedPeriod == 'weekly') {
        // Get current month data and filter for the specific week
        final monthlyReport = await context.read<FirebaseService>().generateCalorieReport(
          user.uid,
          'monthly',
        );
        report = _filterMonthlyDataForWeek(monthlyReport, _currentWeekStart);
      } else {
        // For monthly/yearly, use the original method
        report = await context.read<FirebaseService>().generateCalorieReport(
          user.uid,
          _selectedPeriod,
        );
      }
      
      // Get live BMR calculation (correct value)
      final liveBMR = await context.read<FirebaseService>().calculateBMR(user.uid);
      
      // Additional validation of the report data
      if (report.data.any((data) => 
          data.bmr.isNaN || 
          data.caloriesConsumed.isNaN || 
          data.caloriesBurned.isNaN || 
          data.netCalorieDeficit.isNaN)) {
        throw Exception('Report contains invalid numeric data');
      }
      
      setState(() {
        _currentReport = report;
        _liveBMR = liveBMR;
      });
    } catch (e) {
      Log.e('Report loading error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load report: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Set to null to show error state
        setState(() {
          _currentReport = null;
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadReport();
  }
  
  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _loadReport();
  }
  
  void _selectMonth() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      selectableDayPredicate: (date) => date.day == 1, // Only allow first day of month
    );
    
    if (selectedDate != null) {
      setState(() {
        _selectedMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      });
      _loadReport();
    }
  }
  
  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    _loadReport();
  }
  
  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final nowStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    if (!next.isAfter(nowStart)) {
      setState(() {
        _selectedMonth = next;
      });
      _loadReport();
    }
  }
  
  void _selectYear() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedYear,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      selectableDayPredicate: (date) => date.month == 1 && date.day == 1, // Only allow Jan 1st
    );
    
    if (selectedDate != null) {
      setState(() {
        _selectedYear = DateTime(selectedDate.year, 1, 1);
      });
      _loadReport();
    }
  }

  String _getChartTitle() {
    if (_selectedReportType == 'weight') {
      return 'Weight Progress - ${_selectedYear.year}';
    } else if (_selectedReportType == 'glasses') {
      return 'Water Intake Progress - ${_selectedYear.year}';
    }
    
    switch (_selectedPeriod) {
      case 'weekly':
        final endDate = _currentWeekStart.add(const Duration(days: 6));
        return 'Weekly Calorie Tracking\n${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d, yyyy').format(endDate)}';
      case 'monthly':
        return 'Monthly Calorie Tracking - ${DateFormat('MMMM yyyy').format(_selectedMonth)}';
      case 'yearly':
        return 'Yearly Calorie Tracking - ${_selectedYear.year}';
      default:
        return 'Calorie Tracking';
    }
  }
  
  String _getChartDescription() {
    if (_selectedReportType == 'weight') {
      return 'Track your weight changes over time. Only shows days with recorded weight.';
    } else if (_selectedReportType == 'glasses') {
      return 'Track your daily water intake over time. Only shows days with recorded water intake.';
    }
    
    switch (_selectedPeriod) {
      case 'weekly':
        return 'Weekly view (Wednesday to Tuesday): Blue bars show calories consumed, green/red bars show net deficit (positive = good for weight loss)';
      case 'monthly':
        return 'Monthly overview: Shows net calorie deficit for each day. Positive values indicate calorie deficit (good for weight loss).';
      case 'yearly':
        return 'Yearly overview: Shows net calorie deficit trends. Positive values indicate calorie deficit (good for weight loss).';
      default:
        return 'Positive values indicate calorie deficit (good for weight loss). Only shows days with logged food or exercise.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_selectedReportType == 'calories' ? 'Calorie Reports' : _selectedReportType == 'weight' ? 'Weight Reports' : 'Water Intake Reports'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterControls(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentReport == null || _currentReport!.data.isEmpty
                      ? _buildNoDataWidget()
                      : _buildReportContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterRow(
              'Report Type',
              ['calories', 'weight', 'glasses'],
              _selectedReportType,
              (type) {
                setState(() {
                  _selectedReportType = type;
                  if (type == 'weight' || type == 'glasses') {
                    _selectedPeriod = 'yearly';
                  }
                });
                _loadReport();
              },
            ),
            if (_selectedReportType == 'calories') ...[
              const SizedBox(height: 12),
              _buildFilterRow(
                'Time Period',
                ['weekly', 'monthly', 'yearly'],
                _selectedPeriod,
                (period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  _loadReport();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String title, List<String> options, String selectedValue, ValueChanged<String> onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8.0,
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return ChoiceChip(
                label: Text(option[0].toUpperCase() + option.substring(1)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onSelected(option);
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Data Available',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start logging your food and exercise to see reports',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReport,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    final report = _currentReport!;
    
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        children: [
          // Summary Cards
          if (_selectedReportType == 'calories') ...[
            _buildSummaryCards(report),
          ] else if (_selectedReportType == 'glasses') ...[
            _buildGlassesSummaryCards(report),
          ],

          // Chart Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getChartTitle(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getChartDescription(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: _buildChart(report),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data Table
          if (report.data.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildDataTable(report),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(CalorieReport report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Deficit',
                '${report.totalNetDeficit.round()}',
                'kcal',
                report.totalNetDeficit >= 0 ? Colors.green : Colors.red,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Avg BMR',
                '${_liveBMR?.round() ?? report.averageBMR.round()}',
                'kcal/day',
                Colors.blue,
                Icons.local_fire_department,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Consumed',
                '${report.totalCaloriesConsumed.round()}',
                'kcal',
                Colors.orange,
                Icons.restaurant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Burned',
                '${report.totalCaloriesBurned.round()}',
                'kcal',
                Colors.purple,
                Icons.fitness_center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassesSummaryCards(CalorieReport report) {
    final glassesData = report.data.where((data) => data.glasses != null && data.glasses! > 0);
    final totalGlasses = glassesData.fold(0.0, (sum, data) => sum + data.glasses!);
    final averageGlasses = glassesData.isNotEmpty ? totalGlasses / glassesData.length : 0.0;
    final daysWithGlasses = glassesData.length;
    final goalAchieved = glassesData.where((data) => data.glasses! >= 8).length;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Glasses',
                '${totalGlasses.round()}',
                'glasses',
                Colors.cyan,
                Icons.local_drink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Daily Average',
                '${averageGlasses.toStringAsFixed(1)}',
                'glasses/day',
                Colors.blue,
                Icons.water_drop,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Days Logged',
                '$daysWithGlasses',
                'days',
                Colors.green,
                Icons.event_available,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Goal Achieved',
                '$goalAchieved',
                'days (8+ glasses)',
                goalAchieved > 0 ? Colors.green : Colors.orange,
                Icons.emoji_events,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
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
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                        ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(CalorieReport report) {
    if (report.data.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    if (_selectedReportType == 'weight') {
      return _buildWeightChart(report);
    } else if (_selectedReportType == 'glasses') {
      return _buildGlassesChart(report);
    }

    // Sort data by date to ensure proper ordering
    final sortedData = List<CalorieReportData>.from(report.data)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = <BarChartGroupData>[];
    
    if (_selectedPeriod == 'weekly') {
      // For weekly reports, group by day of week
      final weekData = <int, CalorieReportData>{};
      
      for (final data in sortedData) {
        final dayOfWeek = data.date.weekday; // Monday = 1, Sunday = 7
        // Map to Wednesday-based week: Wed=1, Thu=2, Fri=3, Sat=4, Sun=5, Mon=6, Tue=7
        final wednesdayBasedDay = dayOfWeek == 3 ? 1 : // Wednesday -> 1
                                 dayOfWeek == 4 ? 2 : // Thursday -> 2
                                 dayOfWeek == 5 ? 3 : // Friday -> 3
                                 dayOfWeek == 6 ? 4 : // Saturday -> 4
                                 dayOfWeek == 7 ? 5 : // Sunday -> 5
                                 dayOfWeek == 1 ? 6 : // Monday -> 6
                                 7; // Tuesday -> 7
        weekData[wednesdayBasedDay] = data;
      }
      
      // Create bars for each day of the week (1-7, where 1=Wednesday)
      for (int day = 1; day <= 7; day++) {
        final data = weekData[day];
        if (data != null) {
          spots.add(
            BarChartGroupData(
              x: day,
              barRods: [
                // Calories consumed bar (blue)
                BarChartRodData(
                  toY: data.caloriesConsumed,
                  color: Colors.blue,
                  width: 15,
                  borderRadius: BorderRadius.circular(2),
                ),
                // Net deficit bar (green/red)
                BarChartRodData(
                  toY: data.netCalorieDeficit.abs(),
                  color: data.netCalorieDeficit >= 0 ? Colors.green : Colors.red,
                  width: 15,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          );
        } else {
          // Empty bars for days without data
          spots.add(
            BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: 0,
                  color: Colors.transparent,
                  width: 15,
                ),
                BarChartRodData(
                  toY: 0,
                  color: Colors.transparent,
                  width: 15,
                ),
              ],
            ),
          );
        }
      }
    } else {
      // For monthly/yearly reports, render sensible buckets
      if (_selectedPeriod == 'monthly') {
        // Build a complete day map for the selected month (1..daysInMonth)
        final int year = _selectedMonth.year;
        final int month = _selectedMonth.month;
        final int daysInMonth = DateTime(year, month + 1, 0).day;

        final Map<int, double> dayToNet = {for (var d = 1; d <= daysInMonth; d++) d: 0.0};
        for (final d in sortedData) {
          if (d.date.year == year && d.date.month == month) {
            dayToNet[d.date.day] = (dayToNet[d.date.day] ?? 0) + d.netCalorieDeficit;
          }
        }

        for (int day = 1; day <= daysInMonth; day++) {
          final sum = dayToNet[day] ?? 0.0;
          spots.add(
            BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: sum.abs(),
                  color: sum >= 0 ? Colors.green : Colors.red,
                  width: 12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          );
        }
      } else {
        // Yearly: group by month and show 12 bars (Jan..Dec)
        final Map<int, double> monthToNet = {for (var m = 1; m <= 12; m++) m: 0.0};
        for (final d in sortedData) {
          monthToNet[d.date.month] = (monthToNet[d.date.month] ?? 0) + d.netCalorieDeficit;
        }
        for (int m = 1; m <= 12; m++) {
          final sum = monthToNet[m] ?? 0.0;
          spots.add(
            BarChartGroupData(
              x: m,
              barRods: [
                BarChartRodData(
                  toY: sum.abs(),
                  color: sum >= 0 ? Colors.green : Colors.red,
                  width: 18,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          );
        }
      }
    }

    // Calculate max Y value
    double maxY = 100;
    double minY = 0;
    
    if (sortedData.isNotEmpty) {
      final allValues = sortedData.expand((data) => [
        data.caloriesConsumed,
        data.netCalorieDeficit.abs(),
      ]).toList();
      
      maxY = (allValues.reduce((a, b) => a > b ? a : b)).abs() + 200;
      // Keep baseline at 0 for monthly/yearly to avoid a gap at X axis
      minY = 0;
    }

    return Column(
      children: [
        // Legend for weekly view
        if (_selectedPeriod == 'weekly') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Calories Consumed', Colors.blue),
              const SizedBox(width: 20),
              _buildLegendItem('Net Deficit', Colors.green),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: minY,
              barGroups: spots,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.round()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _selectedPeriod == 'weekly'
                        ? 1
                        : (_selectedPeriod == 'yearly' ? 1 : 5),
                    getTitlesWidget: (value, meta) {
                      if (_selectedPeriod == 'weekly') {
                        // Show day names for weekly view (Wednesday to Tuesday)
                        const dayNames = ['', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'];
                        final index = value.toInt();
                        if (index >= 0 && index < dayNames.length) {
                          return Text(
                            dayNames[index],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                      } else if (_selectedPeriod == 'monthly') {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      } else {
                        // Yearly: fixed month labels Jan..Dec
                        const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                        final idx = value.toInt();
                        if (idx >= 1 && idx <= 12) {
                          return Text(
                            months[idx],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: _selectedPeriod == 'weekly' ? 500 : 200,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart(CalorieReport report) {
    // Filter data to only include entries with weight
    final weightData = report.data
        .where((data) => data.weight != null && data.weight! > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (weightData.isEmpty) {
      return const Center(child: Text('No weight data to display'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < weightData.length; i++) {
      spots.add(FlSpot(i.toDouble(), weightData[i].weight!));
    }

    // Calculate min and max for better scaling
    final weights = weightData.map((d) => d.weight!).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b) - 2;
    final maxWeight = weights.reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: weightData.length > 7 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < weightData.length) {
                  final date = weightData[index].date;
                  return Text(
                    DateFormat('MM/dd').format(date),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}lbs',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (weightData.length - 1).toDouble(),
        minY: minWeight,
        maxY: maxWeight,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassesChart(CalorieReport report) {
    // Debug logging
    print('🚰 Building glasses chart with ${report.data.length} total data points');
    for (final data in report.data) {
      print('🚰 Date: ${data.date}, Glasses: ${data.glasses}');
    }
    
    // Filter data to only include entries with glasses
    final glassesData = report.data
        .where((data) => data.glasses != null && data.glasses! > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    print('🚰 Filtered to ${glassesData.length} entries with glasses data');

    if (glassesData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_drink, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No water intake data to display'),
            SizedBox(height: 8),
            Text('Add glasses of water in your daily log to see trends here', 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < glassesData.length; i++) {
      spots.add(FlSpot(i.toDouble(), glassesData[i].glasses!));
    }

    // Calculate min and max for better scaling
    final glasses = glassesData.map((d) => d.glasses!).toList();
    final minGlasses = glasses.reduce((a, b) => a < b ? a : b) - 1;
    final maxGlasses = glasses.reduce((a, b) => a > b ? a : b) + 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: glassesData.length > 7 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < glassesData.length) {
                  final date = glassesData[index].date;
                  return Text(
                    DateFormat('MM/dd').format(date),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)} glasses',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (glassesData.length - 1).toDouble(),
        minY: minGlasses,
        maxY: maxGlasses,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.cyan,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.cyan,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.cyan.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDataTable(CalorieReport report) {
    if (_selectedReportType == 'weight') {
      return _buildWeightDataTable(report);
    } else if (_selectedReportType == 'glasses') {
      return _buildGlassesDataTable(report);
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('BMR')),
          DataColumn(label: Text('Consumed')),
          DataColumn(label: Text('Burned')),
          DataColumn(label: Text('Net Deficit')),
        ],
        rows: report.data.take(10).map((data) {
          return DataRow(
            cells: [
              DataCell(Text(DateFormat('MMM dd').format(data.date))),
              DataCell(Text('${_liveBMR?.round() ?? data.bmr.round()}')),
              DataCell(Text('${data.caloriesConsumed.round()}')),
              DataCell(Text('${data.caloriesBurned.round()}')),
              DataCell(
                Text(
                  '${data.netCalorieDeficit.round()}',
                  style: TextStyle(
                    color: data.netCalorieDeficit >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeightDataTable(CalorieReport report) {
    final weightData = report.data
        .where((data) => data.weight != null && data.weight! > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Weight (lbs)')),
          DataColumn(label: Text('Change')),
        ],
        rows: weightData.take(10).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final prevWeight = index > 0 ? weightData[index - 1].weight : null;
          final change = prevWeight != null ? data.weight! - prevWeight : 0.0;
          
          return DataRow(
            cells: [
              DataCell(Text(DateFormat('MMM dd').format(data.date))),
              DataCell(Text('${data.weight!.toStringAsFixed(1)} lbs')),
              DataCell(
                Text(
                  index > 0 ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} lbs' : '-',
                  style: TextStyle(
                    color: index > 0 
                        ? (change <= 0 ? Colors.green : Colors.red)
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlassesDataTable(CalorieReport report) {
    final glassesData = report.data
        .where((data) => data.glasses != null && data.glasses! > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Water Intake')),
          DataColumn(label: Text('Goal Progress')),
        ],
        rows: glassesData.take(10).map((data) {
          final goalProgress = data.glasses! / 8.0; // Assuming 8 glasses daily goal
          final progressText = '${(goalProgress * 100).toStringAsFixed(0)}%';
          final isOnTrack = goalProgress >= 1.0;
          
          return DataRow(
            cells: [
              DataCell(Text(DateFormat('MMM dd').format(data.date))),
              DataCell(Text('${data.glasses!.toStringAsFixed(0)} glasses')),
              DataCell(
                Text(
                  progressText,
                  style: TextStyle(
                    color: isOnTrack ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
} 