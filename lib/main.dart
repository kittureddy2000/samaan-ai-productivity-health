import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:samaanai_fitness_tracker/firebase_options.dart';
import 'package:samaanai_fitness_tracker/screens/auth_gate.dart';
import 'package:samaanai_fitness_tracker/services/auth_service.dart';
import 'package:samaanai_fitness_tracker/services/firebase_service.dart';
import 'package:samaanai_fitness_tracker/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
