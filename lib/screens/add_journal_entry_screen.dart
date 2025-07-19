import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/spotify_models.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../providers/preferences_provider.dart';

class AddJournalEntryScreen extends StatefulWidget {
  final SpotifyTrack track;
  final String userId;
  final JournalEntry? existingEntry;

  const AddJournalEntryScreen({
    Key? key,
    required this.track,
    required this.userId,
    this.existingEntry,
  }) : super(key: key);

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Mood? _selectedMood;
  int? _selectedRating;
  bool? _isPublic; // Make nullable to set from preferences
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingEntry != null;

    if (_isEditing) {
      _notesController.text = widget.existingEntry!.personalNotes ?? '';
      _selectedMood = widget.existingEntry!.mood;
      _selectedRating = widget.existingEntry!.rating;
      _isPublic = widget.existingEntry!.isPublic;
    }

    _checkExistingEntry();
  }

  Future<void> _checkExistingEntry() async {
    if (!_isEditing) {
      final existing = await JournalService.getExistingEntry(
        widget.userId,
        widget.track.id,
      );
      if (existing != null && mounted) {
        setState(() {
          _isEditing = true;
          _notesController.text = existing.personalNotes ?? '';
          _selectedMood = existing.mood;
          _selectedRating = existing.rating;
          _isPublic = existing.isPublic;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'You\'ve already journaled this song! Editing existing entry.',
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final prefsProvider = Provider.of<PreferencesProvider>(
      context,
      listen: false,
    );

    // Trigger haptic feedback if enabled
    prefsProvider.hapticFeedback();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing && widget.existingEntry != null) {
        await JournalService.updateEntry(
          entryId: widget.existingEntry!.id,
          personalNotes:
              _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
          mood: _selectedMood,
          rating: _selectedRating,
          isPublic: _isPublic!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Journal entry updated successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        await JournalService.createEntry(
          userId: widget.userId,
          track: widget.track,
          personalNotes:
              _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
          mood: _selectedMood,
          rating: _selectedRating,
          isPublic: _isPublic!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Journal entry added successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: $e'),
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
        title: Text(_isEditing ? 'Edit Entry' : 'Add to Journal'),
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
              onPressed: _saveEntry,
              child: Text(
                _isEditing ? 'Update' : 'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<PreferencesProvider>(
        builder: (context, prefsProvider, child) {
          // Set default privacy from preferences if not already set
          if (_isPublic == null) {
            _isPublic = prefsProvider.preferences.defaultPublicPosts;
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Track Info Card
                  _buildTrackInfoCard(),
                  const SizedBox(height: 24),

                  // Privacy Section with preferences integration
                  _buildPrivacySection(prefsProvider),
                  const SizedBox(height: 24),

                  // Rating Section
                  _buildRatingSection(),
                  const SizedBox(height: 24),

                  // Mood Section
                  _buildMoodSection(prefsProvider),
                  const SizedBox(height: 24),

                  // Notes Section
                  _buildNotesSection(),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEntry,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _isEditing
                                    ? 'Update Journal Entry'
                                    : 'Add to Journal',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacySection(PreferencesProvider prefsProvider) {
    final defaultSetting = prefsProvider.preferences.defaultPublicPosts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _isPublic! ? Icons.public : Icons.lock,
                      color:
                          _isPublic!
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sharing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Switch(
                      value: _isPublic!,
                      onChanged: (value) => setState(() => _isPublic = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _isPublic!
                      ? 'This entry will be shared in the community feed'
                      : 'This entry will remain private in your journal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (_isPublic == defaultSetting) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Using your default setting',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection(PreferencesProvider prefsProvider) {
    final showEmojis = prefsProvider.preferences.showMoodEmojis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What mood does this song give you?',
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
              children:
                  Mood.values.map((mood) {
                    final isSelected = _selectedMood == mood;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedMood = mood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
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
                          showEmojis
                              ? '${mood.emoji} ${mood.displayName}'
                              : mood.displayName,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Keep all your other existing methods (_buildTrackInfoCard, _buildRatingSection, etc.)
  // Just update the colors to use theme colors instead of hardcoded ones

  Widget _buildTrackInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child:
                    widget.track.album.imageUrl != null
                        ? CachedNetworkImage(
                          imageUrl: widget.track.album.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                child: Icon(
                                  Icons.music_note,
                                  size: 40,
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
                                  size: 40,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                        )
                        : Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Icon(
                            Icons.music_note,
                            size: 40,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.track.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.track.artistNames,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.track.album.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.track.formattedDuration,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
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

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How much did you enjoy this song?',
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
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = _selectedRating == rating;

                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = rating),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    size: 36,
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
        ),
        if (_selectedRating != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _getRatingText(_selectedRating!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Notes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'What memories, thoughts, or feelings does this song bring up?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _notesController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    'This song reminds me of...\n\nI discovered it when...\n\nIt makes me feel...',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '⭐ Not for me';
      case 2:
        return '⭐⭐ It\'s okay';
      case 3:
        return '⭐⭐⭐ I like it';
      case 4:
        return '⭐⭐⭐⭐ Really good!';
      case 5:
        return '⭐⭐⭐⭐⭐ Absolutely love it!';
      default:
        return '';
    }
  }
}
