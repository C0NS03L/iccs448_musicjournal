import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';

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
    debugLogDiagnostics: true, // Add debug logging for router
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
        path: '/home',
        builder: (context, state) {
          debugPrint('🧭 Router: Navigating to Home');
          return const HomeScreen();
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'MyMusicJournal',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
