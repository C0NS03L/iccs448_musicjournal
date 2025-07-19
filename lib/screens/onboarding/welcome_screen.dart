import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'Music Lover';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Icon/Logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),

          const SizedBox(height: 32),

          // Welcome message
          Text(
            'Welcome to MyMusicJournal, $displayName! 🎵',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Your personal space to discover, journal, and share your musical journey with a community of music lovers.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Feature highlights
          _buildFeatureHighlight(
            context,
            Icons.search_rounded,
            'Discover Music',
            'Search and explore millions of songs',
          ),

          const SizedBox(height: 16),

          _buildFeatureHighlight(
            context,
            Icons.book_rounded,
            'Journal Your Journey',
            'Track your musical experiences and memories',
          ),

          const SizedBox(height: 16),

          _buildFeatureHighlight(
            context,
            Icons.people_rounded,
            'Connect & Share',
            'Share your discoveries with the community',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
