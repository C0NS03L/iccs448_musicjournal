import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/spotify_models.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../services/post_service.dart';
import '../services/spotify_service.dart';
import '../providers/auth_provider.dart';
import '../providers/preferences_provider.dart';

class CreatePostScreen extends StatefulWidget {
  final SpotifyTrack? initialTrack;

  const CreatePostScreen({Key? key, this.initialTrack}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  SpotifyTrack? _selectedTrack;
  List<SpotifyTrack> _searchResults = [];
  Mood? _selectedMood;
  int? _selectedRating;
  bool _isSearching = false;
  bool _isLoading = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTrack != null) {
      _selectedTrack = widget.initialTrack;
    } else {
      _showSearch = true;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchTracks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await SpotifyService.searchTracks(query, limit: 20);
      setState(() {
        _searchResults = results.tracks;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate() || _selectedTrack == null) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefsProvider = Provider.of<PreferencesProvider>(
      context,
      listen: false,
    );
    final userId = authProvider.currentUser?.uid;

    if (userId == null) return;

    // Trigger haptic feedback if enabled
    prefsProvider.hapticFeedback();

    setState(() {
      _isLoading = true;
    });

    try {
      await PostService.createPost(
        userId: userId,
        track: _selectedTrack!,
        caption:
            _captionController.text.trim().isEmpty
                ? null
                : _captionController.text.trim(),
        mood: _selectedMood,
        rating: _selectedRating,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post shared with community!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _selectedTrack != null ? _createPost : null,
              child: Text(
                'Post',
                style: TextStyle(
                  color:
                      _selectedTrack != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Music Selection Section
              if (_selectedTrack == null) _buildMusicSearchSection(),
              if (_selectedTrack != null) _buildSelectedTrackCard(),
              const SizedBox(height: 24),

              // Public Post Notice
              if (_selectedTrack != null) _buildPublicNotice(),
              if (_selectedTrack != null) const SizedBox(height: 24),

              // Caption Section
              if (_selectedTrack != null) _buildCaptionSection(),
              if (_selectedTrack != null) const SizedBox(height: 24),

              // Mood Section
              if (_selectedTrack != null) _buildMoodSection(),
              if (_selectedTrack != null) const SizedBox(height: 24),

              // Rating Section
              if (_selectedTrack != null) _buildRatingSection(),
              if (_selectedTrack != null) const SizedBox(height: 32),

              // Create Post Button
              if (_selectedTrack != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(
                              'Share with Community',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublicNotice() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.public, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Public Post',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'This post will be visible to everyone in the community',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Music to Your Post',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search for songs, artists, or albums...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _searchTracks,
                ),
                if (_isSearching) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...(_searchResults
                      .take(5)
                      .map((track) => _buildTrackTile(track))),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(SpotifyTrack track) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child:
            track.album.imageUrl != null
                ? CachedNetworkImage(
                  imageUrl: track.album.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                : Container(
                  width: 50,
                  height: 50,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
      ),
      title: Text(track.name),
      subtitle: Text('${track.artistNames} • ${track.album.name}'),
      onTap: () {
        setState(() {
          _selectedTrack = track;
          _showSearch = false;
        });
      },
    );
  }

  Widget _buildSelectedTrackCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  _selectedTrack!.album.imageUrl != null
                      ? CachedNetworkImage(
                        imageUrl: _selectedTrack!.album.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 60,
                        height: 60,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTrack!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedTrack!.artistNames,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _selectedTrack!.album.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedTrack = null;
                  _showSearch = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _captionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What\'s this song about? Share your thoughts...',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Consumer<PreferencesProvider>(
      builder: (context, prefsProvider, child) {
        final showEmojis = prefsProvider.preferences.showMoodEmojis;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood (Optional)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMoodChip(
                      label: 'None',
                      isSelected: _selectedMood == null,
                      onTap: () => setState(() => _selectedMood = null),
                    ),
                    ...Mood.values.map(
                      (mood) => _buildMoodChip(
                        label:
                            showEmojis
                                ? '${mood.emoji} ${mood.displayName}'
                                : mood.displayName,
                        isSelected: _selectedMood == mood,
                        onTap: () => setState(() => _selectedMood = mood),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating (Optional)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedRating = null),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _selectedRating == null
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'None',
                      style: TextStyle(
                        color:
                            _selectedRating == null
                                ? Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                ...List.generate(5, (index) {
                  final rating = index + 1;
                  final isSelected = _selectedRating == rating;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = rating),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      size: 32,
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
