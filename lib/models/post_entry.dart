import 'package:cloud_firestore/cloud_firestore.dart';
import 'spotify_models.dart';
import 'journal_entry.dart'; // For Mood enum

class Post {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumImageUrl;
  final String? caption; // Different from personalNotes
  final Mood? mood;
  final int? rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy; // User IDs who liked this post

  Post({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumImageUrl,
    this.caption,
    this.mood,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.likedBy = const [],
  });

  // Create from Spotify track
  factory Post.fromSpotifyTrack({
    required String id,
    required String userId,
    String? userName,
    String? userPhotoUrl,
    required SpotifyTrack track,
    String? caption,
    Mood? mood,
    int? rating,
  }) {
    final now = DateTime.now();
    return Post(
      id: id,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      trackId: track.id,
      trackName: track.name,
      artistName: track.artistNames,
      albumName: track.album.name,
      albumImageUrl: track.album.imageUrl,
      caption: caption,
      mood: mood,
      rating: rating,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create from Firestore document
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'],
      userPhotoUrl: data['userPhotoUrl'],
      trackId: data['trackId'] ?? '',
      trackName: data['trackName'] ?? '',
      artistName: data['artistName'] ?? '',
      albumName: data['albumName'] ?? '',
      albumImageUrl: data['albumImageUrl'],
      caption: data['caption'],
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
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'albumImageUrl': albumImageUrl,
      'caption': caption,
      'mood': mood?.name,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likesCount': likesCount,
      'likedBy': likedBy,
    };
  }

  // Create a copy with updated fields
  Post copyWith({
    String? caption,
    Mood? mood,
    int? rating,
    int? likesCount,
    List<String>? likedBy,
  }) {
    return Post(
      id: id,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      trackId: trackId,
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      albumImageUrl: albumImageUrl,
      caption: caption ?? this.caption,
      mood: mood ?? this.mood,
      rating: rating ?? this.rating,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
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

  // Get user display name or fallback
  String get displayUserName {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }
    return 'User ${userId.substring(0, 8)}...';
  }

  // Get user initials for avatar
  String get userInitials {
    if (userName != null && userName!.isNotEmpty) {
      final parts = userName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return userName!.substring(0, 2).toUpperCase();
      }
    }
    return userId.substring(0, 2).toUpperCase();
  }

  // Check if current user liked this post
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}
