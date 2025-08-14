import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Samaan AI Dashboard'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthService>().signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                child: Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1565C0).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Welcome Message
            Text(
              'Welcome back, ${user?.email?.split('@')[0] ?? 'User'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a tool to get started with your productivity and health journey',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Dashboard Tiles
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Fitness Tracker Tile (Active)
                  _buildDashboardTile(
                    context: context,
                    title: 'Fitness Tracker',
                    subtitle: 'Track calories, exercise & weight',
                    icon: Icons.fitness_center,
                    color: const Color(0xFF1565C0), // Deep Blue
                    isActive: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // Task Manager Tile (Coming Soon)
                  _buildDashboardTile(
                    context: context,
                    title: 'Task Manager',
                    subtitle: 'Organize and track your tasks',
                    icon: Icons.task_alt,
                    color: const Color(0xFF1976D2), // Medium Blue
                    isActive: false,
                  ),
                  
                  // Study Planner Tile (Coming Soon)
                  _buildDashboardTile(
                    context: context,
                    title: 'Study Planner',
                    subtitle: 'Plan your learning schedule',
                    icon: Icons.school,
                    color: const Color(0xFF1E88E5), // Light Blue
                    isActive: false,
                  ),
                  
                  // Habit Tracker Tile (Coming Soon)
                  _buildDashboardTile(
                    context: context,
                    title: 'Habit Tracker',
                    subtitle: 'Build positive daily habits',
                    icon: Icons.refresh,
                    color: const Color(0xFF2196F3), // Sky Blue
                    isActive: false,
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

  Widget _buildDashboardTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: isActive ? 8 : 3,
      shadowColor: isActive ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isActive 
            ? onTap 
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Coming Soon!'),
                    backgroundColor: color,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isActive 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      color.withOpacity(0.05),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.withOpacity(0.05),
                    ],
                  ),
            border: isActive 
                ? Border.all(color: color.withOpacity(0.2), width: 1)
                : Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isActive 
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.2),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey.withOpacity(0.1),
                            Colors.grey.withOpacity(0.15),
                          ],
                        ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: isActive ? color : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isActive ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.1),
                        color.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
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
}