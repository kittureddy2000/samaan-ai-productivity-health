import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_profile.dart';
import '../screens/profile_screen.dart';

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({super.key});

  void _showProfileMenu(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile header with picture
            FutureBuilder<UserProfile?>(
              future: user != null 
                  ? context.read<FirebaseService>().getUserProfile(user!.uid)
                  : Future.value(null),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final photoURL = user?.photoURL ?? profile?.photoURL;
                
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: photoURL != null ? Colors.transparent : Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: photoURL != null && photoURL.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            photoURL,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.blue,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.blue,
                        ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              context.read<AuthService>().currentUser?.email ?? 'User',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Profile options
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile Settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthService>().signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => _showProfileMenu(context),
        child: FutureBuilder<UserProfile?>(
          future: user != null 
              ? context.read<FirebaseService>().getUserProfile(user!.uid)
              : Future.value(null),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final photoURL = user?.photoURL ?? profile?.photoURL;
            
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: photoURL != null ? Colors.transparent : Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: photoURL != null && photoURL.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        photoURL,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 24,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 24,
                    ),
            );
          },
        ),
      ),
    );
  }
}