import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'config/firebase_config.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable Provider debug check for production
  Provider.debugCheckInvalidValueType = null;
  
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue with the app even if Firebase fails
  }
  // Initialize notifications (Android safe)
  await NotificationService.instance.initialize();
  await NotificationService.instance.scheduleDailyMorning(hour: 8, minute: 0);
  
  runApp(const SamaanAiApp());
}

class SamaanAiApp extends StatelessWidget {
  const SamaanAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirebaseService()),
      ],
      child: MaterialApp(
        title: 'Samaan AI - Productivity & Health',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
