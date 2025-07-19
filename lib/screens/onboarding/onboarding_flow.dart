import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/preferences_provider.dart';
import 'welcome_screen.dart';
import 'features_screen.dart';
import 'spotify_setup_screen.dart';
import 'preferences_setup_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Widget> _pages = [
    const WelcomeScreen(),
    const FeaturesScreen(),
    const SpotifySetupScreen(),
    const PreferencesSetupScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Progress indicator
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _pages.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: _pages,
            ),
          ),

          // Navigation buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(),

                  Row(
                    children: [
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: () => _completeOnboarding(),
                          child: const Text('Skip'),
                        ),

                      const SizedBox(width: 8),

                      FilledButton(
                        onPressed:
                            _currentPage < _pages.length - 1
                                ? () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                                : () => _completeOnboarding(),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Next'
                              : 'Get Started',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() async {
    debugPrint('🎯 OnboardingFlow: Completing onboarding...');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefsProvider = Provider.of<PreferencesProvider>(
      context,
      listen: false,
    );

    final userId = authProvider.currentUser?.uid;
    if (userId != null) {
      try {
        // Mark onboarding as complete
        await authProvider.updateUserDocument(userId, {
          'onboardingCompleted': true,
        });

        // Ensure preferences are saved
        await prefsProvider.savePreferences(userId);

        debugPrint('✅ OnboardingFlow: Onboarding completed successfully');

        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        debugPrint('❌ OnboardingFlow: Error completing onboarding: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error completing setup: $e')));
        }
      }
    }
  }
}
