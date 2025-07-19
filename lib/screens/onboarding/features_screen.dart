import 'package:flutter/material.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header
          Text(
            'What You Can Do',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Explore all the ways MyMusicJournal helps you connect with music',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Feature cards
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildFeatureCard(
                    context,
                    Icons.edit_note_rounded,
                    'Personal Journaling',
                    'Write about your musical experiences, thoughts, and memories',
                    Colors.green,
                  ),

                  const SizedBox(height: 16),

                  _buildFeatureCard(
                    context,
                    Icons.library_music_rounded,
                    'Music Collection',
                    'Organize and keep track of your favorite songs and albums',
                    Colors.blue,
                  ),

                  const SizedBox(height: 16),

                  _buildFeatureCard(
                    context,
                    Icons.mood_rounded,
                    'Mood Tracking',
                    'Connect your emotions with music and track your musical journey',
                    Colors.purple,
                  ),

                  const SizedBox(height: 16),

                  _buildFeatureCard(
                    context,
                    Icons.lock_rounded,
                    'Privacy Control',
                    'Keep your thoughts private with secure, personal journaling',
                    Colors.teal,
                  ),

                  const SizedBox(height: 16),

                  _buildFeatureCard(
                    context,
                    Icons.palette_rounded,
                    'Personalization',
                    'Customize themes, fonts, and settings to match your style',
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
