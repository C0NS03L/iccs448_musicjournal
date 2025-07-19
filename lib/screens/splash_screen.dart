import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkAuthAndNavigate();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation AND auth initialization
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth provider to fully initialize
    while (authProvider.isLoading && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    debugPrint('🔍 SplashScreen: Auth Status: ${authProvider.isAuthenticated}');
    debugPrint('🔍 SplashScreen: Is Loading: ${authProvider.isLoading}');
    debugPrint(
      '🔍 SplashScreen: Current User: ${authProvider.currentUser?.email}',
    );

    // Check if user is already authenticated (persisted login)
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final user = authProvider.currentUser!;

      debugPrint(
        '🔍 SplashScreen: Onboarding Completed: ${user.onboardingCompleted}',
      );

      // User is logged in - check onboarding status
      if (!user.onboardingCompleted) {
        debugPrint('💫 SplashScreen: Existing user needs onboarding');
        context.go('/onboarding');
      } else {
        debugPrint('🏠 SplashScreen: Existing user going to home');
        context.go('/home');
      }
    } else {
      debugPrint('🔐 SplashScreen: No authenticated user - going to login');
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 20),
              Text(
                'MyMusicJournal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your musical journey awaits',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
