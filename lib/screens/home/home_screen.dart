import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../create_post_screen.dart';
import '../feed_tab.dart';
import '../journal_tab.dart';
import '../music_search_screen.dart';
import '../analytics_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 HomeScreen: initState called');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 HomeScreen: build called');

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Insights & Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          debugPrint('🏠 HomeScreen: Consumer builder called');

          if (authProvider.isLoading) {
            debugPrint('🏠 HomeScreen: Still loading...');
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.currentUser;

          return IndexedStack(
            index: _currentIndex,
            children: [
              _buildFeedTab(user),
              _buildJournalTab(user),
              _buildProfileTab(user),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          debugPrint('🏠 HomeScreen: Tab $index tapped');
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton:
          _currentIndex < 2
              ? FloatingActionButton(
                onPressed: () {
                  debugPrint('➕ FAB tapped on tab $_currentIndex');
                  if (_currentIndex == 1) {
                    // Journal tab - navigate to music search
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MusicSearchScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    );
                  }
                },
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Feed';
      case 1:
        return 'My Journal';
      case 2:
        return 'Profile';
      default:
        return 'MyMusicJournal';
    }
  }

  Widget _buildFeedTab(user) {
    debugPrint('🏠 HomeScreen: Building Feed tab');
    return const FeedTab();
  }

  Widget _buildJournalTab(user) {
    return const JournalTab();
  }

  Widget _buildProfileTab(user) {
    debugPrint('🏠 HomeScreen: Building Profile tab');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ??
                          user?.email?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ??
                        user?.email?.split('@')[0] ??
                        'Music Lover',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Actions - Cleaned up
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings & Preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/settings');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => _handleSignOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    debugPrint('🚪 HomeScreen: Sign out tapped');

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      // Navigate to login after sign out
      if (mounted) {
        context.go('/login');
      }
    }
  }
}
