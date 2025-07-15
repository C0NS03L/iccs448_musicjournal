import 'package:cloud_firestore/cloud_firestore.dart';
import 'spotify_models.dart';

enum Mood {
  happy('😊', 'Happy'),
  sad('😢', 'Sad'),
  excited('🤩', 'Excited'),
  calm('😌', 'Calm'),
  nostalgic('🥺', 'Nostalgic'),
  energetic('⚡', 'Energetic'),
  melancholy('😔', 'Melancholy'),
  inspired('✨', 'Inspired'),
  relaxed('😴', 'Relaxed'),
  passionate('🔥', 'Passionate');

  const Mood(this.emoji, this.label);
  final String emoji;
  final String label;

  String get displayName => '$emoji $label';
}

class JournalEntry {
  final String id;
  final String userId;
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumImageUrl;
  final String? personalNotes;
  final Mood? mood;
  final int? rating; // 1-5 stars
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumImageUrl,
    this.personalNotes,
    this.mood,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Spotify track
  factory JournalEntry.fromSpotifyTrack({
    required String id,
    required String userId,
    required SpotifyTrack track,
    String? personalNotes,
    Mood? mood,
    int? rating,
  }) {
    final now = DateTime.now();
    return JournalEntry(
      id: id,
      userId: userId,
      trackId: track.id,
      trackName: track.name,
      artistName: track.artistNames,
      albumName: track.album.name,
      albumImageUrl: track.album.imageUrl,
      personalNotes: personalNotes,
      mood: mood,
      rating: rating,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create from Firestore document
  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      trackId: data['trackId'] ?? '',
      trackName: data['trackName'] ?? '',
      artistName: data['artistName'] ?? '',
      albumName: data['albumName'] ?? '',
      albumImageUrl: data['albumImageUrl'],
      personalNotes: data['personalNotes'],
      mood:
          data['mood'] != null
              ? Mood.values.firstWhere(
                (m) => m.name == data['mood'],
                orElse: () => Mood.happy,
              )
              : null,
      rating: data['rating'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'albumImageUrl': albumImageUrl,
      'personalNotes': personalNotes,
      'mood': mood?.name,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  JournalEntry copyWith({String? personalNotes, Mood? mood, int? rating}) {
    return JournalEntry(
      id: id,
      userId: userId,
      trackId: trackId,
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      albumImageUrl: albumImageUrl,
      personalNotes: personalNotes ?? this.personalNotes,
      mood: mood ?? this.mood,
      rating: rating ?? this.rating,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
