import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/preferences_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 App: Starting Firebase initialization...');
  await Firebase.initializeApp();
  debugPrint('✅ App: Firebase initialized successfully');

  runApp(MyMusicJournalApp());
}

class MyMusicJournalApp extends StatelessWidget {
  MyMusicJournalApp({Key? key}) : super(key: key);

  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          debugPrint('🧭 Router: Navigating to Splash');
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          debugPrint('🧭 Router: Navigating to Login');
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          debugPrint('🧭 Router: Navigating to SignUp');
          return const SignUpScreen();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          debugPrint('🧭 Router: Navigating to Onboarding');
          return const OnboardingFlow();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          debugPrint('🧭 Router: Navigating to Home');
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          debugPrint('🧭 Router: Navigating to Settings');
          return const SettingsScreen();
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🔧 App: Creating AuthProvider');
            return AuthProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🔧 App: Creating ThemeProvider');
            return ThemeProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🔧 App: Creating PreferencesProvider');
            return PreferencesProvider();
          },
        ),
      ],
      child: Consumer2<ThemeProvider, PreferencesProvider>(
        builder: (context, themeProvider, preferencesProvider, child) {
          return MaterialApp.router(
            title: 'MyMusicJournal',
            // Use preferences provider theme if available, fallback to theme provider
            theme: preferencesProvider.getThemeData(context),
            darkTheme: preferencesProvider.getThemeData(context),
            themeMode: _getThemeMode(preferencesProvider, themeProvider),
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(
    PreferencesProvider prefsProvider,
    ThemeProvider themeProvider,
  ) {
    // Use preferences if available
    switch (prefsProvider.preferences.appTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
      case AppTheme.colorful:
        return ThemeMode.dark; // Colorful theme uses dark mode
      default:
        return themeProvider.themeMode; // Fallback to theme provider
    }
  }
}
