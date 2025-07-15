import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/spotify_models.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';

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
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You\'ve already journaled this song! Editing existing entry.',
            ),
            backgroundColor: Colors.orange,
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
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Journal entry updated successfully!'),
              backgroundColor: Colors.green,
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
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Journal entry added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: $e'),
            backgroundColor: Colors.red,
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Track Info Card
              _buildTrackInfoCard(),
              const SizedBox(height: 24),

              // Rating Section
              _buildRatingSection(),
              const SizedBox(height: 24),

              // Mood Section
              _buildMoodSection(),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
      ),
    );
  }

  Widget _buildTrackInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Album Art
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
                                child: const Icon(Icons.music_note, size: 40),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                child: const Icon(Icons.music_note, size: 40),
                              ),
                        )
                        : Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Icon(Icons.music_note, size: 40),
                        ),
              ),
            ),
            const SizedBox(width: 16),

            // Track Details
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
                  onTap: () {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    size: 36,
                    color:
                        isSelected
                            ? Colors.amber
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

  Widget _buildMoodSection() {
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
                      onTap: () {
                        setState(() {
                          _selectedMood = mood;
                        });
                      },
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
                                  ).colorScheme.primary.withOpacity(0.1)
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
                          mood.displayName,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
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
