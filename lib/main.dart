import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:samaanai_fitness_tracker/config/firebase_config.dart';
import 'package:samaanai_fitness_tracker/screens/auth_gate.dart';
import 'package:samaanai_fitness_tracker/services/auth_service.dart';
import 'package:samaanai_fitness_tracker/services/firebase_service.dart';
import 'package:samaanai_fitness_tracker/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:samaanai_fitness_tracker/utils/firebase_debug.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(
        'FlutterError: \\n${details.exceptionAsString()}\\n${details.stack}');
  };

  try {
    debugPrint('🚀 Starting Firebase initialization...');

    // Check if Firebase is already initialized to prevent duplicate app error
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint('✅ Firebase already initialized, using existing app');
    }

    // Log Firebase config in debug builds to help diagnose Android init issues
    FirebaseDebug.logCurrentConfiguration();
  } catch (e, stackTrace) {
    debugPrint('❌ FATAL: Firebase initialization failed');
    debugPrint('Error: $e');
    debugPrint('Stack trace: $stackTrace');

    // Don't proceed if Firebase fails to initialize
    runApp(MaterialApp(
      title: 'Samaan AI - Init Error',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Firebase initialization failed'),
              const SizedBox(height: 8),
              Text('Error: $e', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(auth: FirebaseAuth.instance),
        ),
        ChangeNotifierProvider<FirebaseService>(
          create: (_) => FirebaseService(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
            httpClient: http.Client(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Samaan AI Fitness Tracker',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
