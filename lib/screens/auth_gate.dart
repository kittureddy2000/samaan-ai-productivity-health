import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'main_dashboard_screen_updated.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // Show loading while checking authentication state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Handle errors
            if (snapshot.hasError) {
              print('Auth error: ${snapshot.error}');
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Authentication Error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Try to restart the auth stream
                          authService.signOut();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // User is not authenticated
            if (snapshot.data == null) {
              return const LoginScreen();
            }

            // User is authenticated, check if profile is complete
            return FutureBuilder(
              future: context.read<FirebaseService>().getUserProfile(snapshot.data!.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Handle profile errors
                if (profileSnapshot.hasError) {
                  print('Profile error: ${profileSnapshot.error}');
                  return const ProfileSetupScreen();
                }

                // Profile doesn't exist or is incomplete
                if (profileSnapshot.data == null) {
                  return const ProfileSetupScreen();
                }

                // Profile exists, go to main dashboard
                return const MainDashboardScreenUpdated();
              },
            );
          },
        );
      },
    );
  }
} 