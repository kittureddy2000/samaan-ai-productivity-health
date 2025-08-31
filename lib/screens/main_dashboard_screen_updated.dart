import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_profile.dart';
import '../widgets/profile_menu_widget.dart';
import 'dashboard_screen.dart';

class MainDashboardScreenUpdated extends StatelessWidget {
  const MainDashboardScreenUpdated({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Samaan AI', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        actions: const [
          ProfileMenuWidget(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore your productivity and health tools.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final List<Map<String, dynamic>> dashboardItems = [
                        {
                          'title': 'Fitness Tracker',
                          'icon': Icons.fitness_center,
                          'isActive': true,
                          'onTap': () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const DashboardScreen()),
                            );
                          },
                        },
                        {
                          'title': 'Task Manager',
                          'icon': Icons.task_alt,
                          'isActive': false,
                          'onTap': null,
                        },
                        {
                          'title': 'Study Planner',
                          'icon': Icons.school,
                          'isActive': false,
                          'onTap': null,
                        },
                        {
                          'title': 'Habit Tracker',
                          'icon': Icons.refresh,
                          'isActive': false,
                          'onTap': null,
                        },
                      ];

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: dashboardItems.length,
                        itemBuilder: (context, index) {
                          final item = dashboardItems[index];
                          return _buildDashboardTile(
                            context: context,
                            title: item['title'],
                            icon: item['icon'],
                            isActive: item['isActive'],
                            onTap: item['onTap'],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isActive
            ? onTap
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This feature is coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isActive ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
