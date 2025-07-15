import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/spotify_service.dart';
import '../models/spotify_models.dart';
import '../providers/auth_provider.dart';
import 'add_journal_entry_screen.dart';
import 'dart:async';

class MusicSearchScreen extends StatefulWidget {
  const MusicSearchScreen({Key? key}) : super(key: key);

  @override
  State<MusicSearchScreen> createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final _searchController = TextEditingController();
  final _debounceTimer = Duration(milliseconds: 500);
  Timer? _timer;

  List<SpotifyTrack> _tracks = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _timer?.cancel();
    if (_searchController.text.trim().isNotEmpty) {
      _timer = Timer(_debounceTimer, () {
        _searchTracks();
      });
    } else {
      setState(() {
        _tracks = [];
        _hasSearched = false;
        _error = null;
      });
    }
  }

  Future<void> _searchTracks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final result = await SpotifyService.searchTracks(query, limit: 30);
      if (mounted) {
        setState(() {
          _tracks = result.tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _tracks = [];
        });
      }
    }
  }

  void _selectTrack(SpotifyTrack track) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddJournalEntryScreen(
              track: track,
              userId: authProvider.currentUser!.uid,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Music'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for songs, artists, or albums...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
          ),

          // Results
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching Spotify...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Search Failed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _searchTracks,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Results Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return _buildTrackTile(track);
      },
    );
  }

  Widget _buildEmptyState() {
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
              'Discover Your Next Favorite Song',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Search for any song, artist, or album to add to your music journal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Try artist names like "Taylor Swift"'),
                    const Text(
                      '• Search for song titles like "Bohemian Rhapsody"',
                    ),
                    const Text('• Look up albums like "Abbey Road"'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(SpotifyTrack track) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child:
                track.album.smallImageUrl != null
                    ? CachedNetworkImage(
                      imageUrl: track.album.smallImageUrl!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.music_note),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.music_note),
                          ),
                    )
                    : Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Icon(Icons.music_note),
                    ),
          ),
        ),
        title: Text(
          track.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.artistNames,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              track.album.name,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              track.formattedDuration,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        onTap: () => _selectTrack(track),
      ),
    );
  }
}
