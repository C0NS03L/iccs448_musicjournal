import 'package:flutter/material.dart';

class SpotifySetupScreen extends StatelessWidget {
  const SpotifySetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spotify Logo placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954), // Spotify green
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Music Powered by Spotify',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'We use Spotify\'s vast music library to help you discover and journal about your favorite songs.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Benefits
          _buildBenefit(
            context,
            Icons.library_music_rounded,
            'Access to millions of songs',
          ),

          const SizedBox(height: 16),

          _buildBenefit(
            context,
            Icons.album_rounded,
            'Complete track information and album art',
          ),

          const SizedBox(height: 16),

          _buildBenefit(
            context,
            Icons.trending_up_rounded,
            'Discover trending music in the community',
          ),

          const SizedBox(height: 48),

          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No Spotify account required! We use public music data to enhance your experience.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1DB954), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
