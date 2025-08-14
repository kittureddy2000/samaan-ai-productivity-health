import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _dailyReminderEnabled = true;
  
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedGender = 'male';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await context.read<FirebaseService>().getUserProfile(user.uid);
      setState(() {
        _userProfile = profile;
        if (profile != null) {
          _heightController.text = profile.height.toString();
          _weightController.text = profile.weight.toString();
          _selectedDate = profile.dateOfBirth;
          _selectedGender = profile.gender;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      helpText: 'Select your date of birth',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null || _userProfile == null) throw Exception('User not authenticated');

      final updatedProfile = _userProfile!.copyWith(
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        dateOfBirth: _selectedDate!,
        gender: _selectedGender,
        updatedAt: DateTime.now(),
      );

      await context.read<FirebaseService>().updateUserProfile(updatedProfile);

      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
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

  Future<void> _showResetDataDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Data'),
          content: const Text(
            'This will permanently delete:\n'
            '• Your profile\n'
            '• All daily entries\n'
            '• Weight loss goals\n\n'
            'This action cannot be undone. Are you sure?'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete All', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetAllData();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<FirebaseService>().deleteAllUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data deleted successfully! Please restart the app.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Sign out to force profile recreation
        context.read<AuthService>().signOut();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete data: $e'),
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'This app collects and processes personal health data including:\n\n'
              '• Account information (email, name)\n'
              '• Health metrics (weight, height, age)\n'
              '• Activity data (food intake, exercise)\n'
              '• Goal tracking information\n\n'
              'Your data is securely stored using Firebase and encrypted in transit and at rest. '
              'We do not sell or share your personal information with third parties without consent.\n\n'
              'You have the right to access, correct, or delete your data at any time through the app settings.\n\n'
              'For the complete privacy policy, visit: [Your Privacy Policy URL]'
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing && _userProfile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: const Text('Save'),
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Reset All Data'),
                onTap: () {
                  _showResetDataDialog();
                },
              ),
              PopupMenuItem(
                child: const Text('Privacy Policy'),
                onTap: () {
                  _showPrivacyPolicy();
                },
              ),
              PopupMenuItem(
                child: const Text('Sign Out'),
                onTap: () {
                  context.read<AuthService>().signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('No profile found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _isEditing ? _buildEditForm() : _buildProfileView(),
                ),
    );
  }

  Widget _buildProfileView() {
    final profile = _userProfile!;
    final user = context.read<AuthService>().currentUser;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Avatar
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blue.shade100,
          child: user?.photoURL != null
              ? ClipOval(child: Image.network(user!.photoURL!, fit: BoxFit.cover))
              : Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.blue.shade400,
                ),
        ),
        const SizedBox(height: 24),

        // User Info
        Text(
          profile.displayName ?? user?.email ?? 'Unknown User',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        // Notification toggle
        Card(
          child: SwitchListTile(
            value: _dailyReminderEnabled,
            title: const Text('Daily Morning Reminder'),
            subtitle: const Text('Get a reminder every morning to log your day'),
            onChanged: (val) async {
              setState(() => _dailyReminderEnabled = val);
              if (val) {
                await NotificationService.instance.scheduleDailyMorning(hour: 8, minute: 0);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily reminder scheduled')),
                  );
                }
              } else {
                await NotificationService.instance.cancelDailyMorning();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily reminder canceled')),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Profile Details Cards
        _buildDetailCard('Age', '${profile.age} years', Icons.cake),
        const SizedBox(height: 16),
        _buildDetailCard('Height', '${profile.height.toStringAsFixed(0)} cm', Icons.height),
        const SizedBox(height: 16),
        _buildDetailCard('Weight', '${profile.weight.toStringAsFixed(1)} lbs', Icons.monitor_weight),
        const SizedBox(height: 16),
        _buildDetailCard('Gender', profile.gender.toUpperCase(), 
            profile.gender == 'male' ? Icons.man : Icons.woman),
        const SizedBox(height: 16),
        _buildDetailCard('Date of Birth', 
            '${profile.dateOfBirth.day}/${profile.dateOfBirth.month}/${profile.dateOfBirth.year}', 
            Icons.calendar_today),
        
        const SizedBox(height: 32),

        // BMR Info Card
        FutureBuilder<double>(
          future: context.read<FirebaseService>().calculateBMR(profile.uid),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Basal Metabolic Rate (BMR)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.data!.round()} calories/day',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is the number of calories your body burns at rest',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade400),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Height Field
          TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              prefixIcon: Icon(Icons.height),
              border: OutlineInputBorder(),
              suffixText: 'cm',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your height';
              }
              final height = double.tryParse(value);
              if (height == null || height < 50 || height > 300) {
                return 'Please enter a valid height (50-300 cm)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Weight Field
          TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight (lbs)',
              prefixIcon: Icon(Icons.monitor_weight),
              border: OutlineInputBorder(),
              suffixText: 'lbs',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight < 45 || weight > 1100) {
                return 'Please enter a valid weight (45-1100 lbs)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Date of Birth Field
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date of Birth'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Gender Selection
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Male'),
                  value: 'male',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Female'),
                  value: 'female',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Cancel Button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                // Reset form fields
                _heightController.text = _userProfile!.height.toString();
                _weightController.text = _userProfile!.weight.toString();
                _selectedDate = _userProfile!.dateOfBirth;
                _selectedGender = _userProfile!.gender;
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 