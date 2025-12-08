import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:pupshape/providers/auth_provider.dart';
import 'package:pupshape/providers/dog_provider.dart';
import 'package:pupshape/providers/meal_provider.dart';
import 'package:pupshape/providers/plan_provider.dart';
import 'package:pupshape/screens/splash/splash_screen.dart';
import 'package:pupshape/screens/start/start_screen.dart';
import 'package:pupshape/screens/main_navigation_screen.dart';
import 'package:pupshape/screens/calendar/calendar_screen.dart';
import 'package:pupshape/screens/onboarding/onboarding_screen.dart';
import 'package:pupshape/screens/auth/auth_screen.dart';
import 'package:pupshape/screens/assessment/assessment_wizard.dart';
import 'package:pupshape/screens/home/new_home_screen.dart';
import 'package:pupshape/screens/profile/profile_screen.dart';
import 'package:pupshape/screens/settings/settings_screen.dart';
import 'package:pupshape/screens/progress/progress_screen.dart';
import 'package:pupshape/screens/progress/weight_logging_screen.dart';
import 'package:pupshape/screens/meals/meal_suggestions_screen.dart';
import 'package:pupshape/screens/tips/tip_history_screen.dart';
import 'package:pupshape/config/theme.dart';
import 'package:pupshape/services/onesignal_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize OneSignal for push notifications
  if (!kIsWeb) {
    try {
      await OneSignalService.initialize();
      print('OneSignal initialized successfully');
    } catch (e) {
      print('Error initializing OneSignal: $e');
    }
  }
  
  // Initialize Superwall (only on mobile platforms)
  if (!kIsWeb) {
    try {
      final apiKey = Platform.isAndroid
          ? 'pk_Hz5P_K1_-85NbshijzF0D' // Android key
          : 'pk_ZfnAw6GKKacCVyebj2wls'; // iOS key
      
      await Superwall.configure(apiKey);
      print('Superwall initialized successfully');
    } catch (e) {
      print('Error initializing Superwall: $e');
    }
  }
  
  runApp(const PupShapeApp());
}

class PupShapeApp extends StatelessWidget {
  const PupShapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DogProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
      ],
      child: MaterialApp(
        title: 'PupShape',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/auth': (context) => const AuthScreen(),
          '/start': (context) => const StartScreen(),
          '/assessment': (context) => const AssessmentWizard(),
          '/main': (context) => const MainNavigationScreen(),
          '/home': (context) => const MainNavigationScreen(initialIndex: 0),
          '/calendar': (context) => const MainNavigationScreen(initialIndex: 1),
          '/meal-suggestions': (context) => const MainNavigationScreen(initialIndex: 2),
          '/progress': (context) => const MainNavigationScreen(initialIndex: 3),
          '/profile': (context) => const MainNavigationScreen(initialIndex: 4),
          '/settings': (context) => const SettingsScreen(),
          '/weight-logging': (context) => const WeightLoggingScreen(),
          '/tip-history': (context) => const TipHistoryScreen(),
        },
      ),
    );
  }
}
