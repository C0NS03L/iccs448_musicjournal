import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../providers/auth_provider.dart';
import 'music_search_screen.dart';
import 'add_journal_entry_screen.dart';
import '../services/spotify_service.dart';

class JournalTab extends StatelessWidget {
  const JournalTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view your journal'));
    }

    return StreamBuilder<List<JournalEntry>>(
      stream: JournalService.getUserEntries(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text('Error loading journal entries'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Trigger rebuild
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildEntryCard(context, entry);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Music Journal',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your personal soundtrack by adding songs that move you',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MusicSearchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Song'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, JournalEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editEntry(context, entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with track info
              Row(
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child:
                          entry.albumImageUrl != null
                              ? CachedNetworkImage(
                                imageUrl: entry.albumImageUrl!,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceVariant,
                                      child: const Icon(Icons.music_note),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceVariant,
                                      child: const Icon(Icons.music_note),
                                    ),
                              )
                              : Container(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                child: const Icon(Icons.music_note),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Track details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.trackName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.artistName,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.formattedDate,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rating and mood
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (entry.rating != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < entry.rating!
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color:
                                  index < entry.rating!
                                      ? Colors.amber
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.3),
                            );
                          }),
                        ),
                      if (entry.mood != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entry.mood!.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Notes preview
              if (entry.personalNotes != null &&
                  entry.personalNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.personalNotes!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editEntry(BuildContext context, JournalEntry entry) async {
    // Get the track details from Spotify
    final track = await SpotifyService.getTrack(entry.trackId);

    if (track != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AddJournalEntryScreen(
                track: track,
                userId: entry.userId,
                existingEntry: entry,
              ),
        ),
      );

      // The StreamBuilder will automatically update when the entry is modified
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load track details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
