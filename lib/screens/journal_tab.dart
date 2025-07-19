import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../providers/auth_provider.dart';
import 'music_search_screen.dart';
import 'add_journal_entry_screen.dart';
import '../services/spotify_service.dart';

class JournalTab extends StatefulWidget {
  const JournalTab({Key? key}) : super(key: key);

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  String _searchText = '';
  Mood? _selectedMood;
  int? _selectedRating;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: _selectedMood == null,
          onSelected: (_) => setState(() => _selectedMood = null),
        ),
        ...Mood.values.map(
          (mood) => ChoiceChip(
            label: Text(mood.displayName),
            selected: _selectedMood == mood,
            onSelected: (_) => setState(() => _selectedMood = mood),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('Any'),
          selected: _selectedRating == null,
          onSelected: (_) => setState(() => _selectedRating = null),
        ),
        ...List.generate(5, (i) {
          int rating = i + 1;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                rating,
                (j) => const Icon(Icons.star, size: 16, color: Colors.amber),
              ),
            ),
            selected: _selectedRating == rating,
            onSelected: (_) => setState(() => _selectedRating = rating),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view your journal'));
    }

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by song, artist, or notes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                      )
                      : null,
            ),
            onChanged:
                (val) => setState(() => _searchText = val.trim().toLowerCase()),
          ),
        ),
        // Mood Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterChips(),
          ),
        ),
        // Rating Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildRatingFilter(),
          ),
        ),
        // Entries
        Expanded(
          child: StreamBuilder<List<JournalEntry>>(
            stream: JournalService.getUserEntries(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading entries'));
              }
              final entries = snapshot.data ?? [];

              // Filter entries
              final filtered =
                  entries.where((entry) {
                    // Search
                    final searchMatch =
                        _searchText.isEmpty ||
                        entry.trackName.toLowerCase().contains(_searchText) ||
                        entry.artistName.toLowerCase().contains(_searchText) ||
                        entry.personalNotes?.toLowerCase().contains(
                              _searchText,
                            ) ==
                            true;

                    // Mood filter
                    final moodMatch =
                        _selectedMood == null || entry.mood == _selectedMood;

                    // Rating filter
                    final ratingMatch =
                        _selectedRating == null ||
                        entry.rating == _selectedRating;

                    return searchMatch && moodMatch && ratingMatch;
                  }).toList();

              if (filtered.isEmpty) {
                return Center(child: Text('No journal entries found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final entry = filtered[index];
                  return _buildEntryCard(context, entry);
                },
              );
            },
          ),
        ),
      ],
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
                  // Album art - UPDATED
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
                                      child: Icon(
                                        Icons.music_note,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceVariant,
                                      child: Icon(
                                        Icons.music_note,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                              )
                              : Container(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                child: Icon(
                                  Icons.music_note,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
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
                                      ? Theme.of(context).colorScheme.primary
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

              // Notes preview - UPDATED
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
