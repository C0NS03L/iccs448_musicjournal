import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_entry.dart';
import '../models/spotify_models.dart';
import '../models/journal_entry.dart';
import 'auth_service.dart';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'posts';
  static final AuthService _authService = AuthService();

  static Future<String> createPost({
    required String userId,
    required SpotifyTrack track,
    String? caption,
    Mood? mood,
    int? rating,
  }) async {
    debugPrint(
      '📝 PostService: Creating post for "${track.name}" by ${track.artistNames}',
    );

    try {
      final docRef = _firestore.collection(_collection).doc();

      // Automatically fetch user info when creating post
      debugPrint('👤 PostService: Fetching user info for $userId');
      final userInfo = await _authService.getUserInfo(userId);
      final userName = userInfo['displayName'];
      final userPhotoUrl = userInfo['photoURL'];

      debugPrint(
        '👤 PostService: Found user info - Name: $userName, Photo: ${userPhotoUrl != null ? 'Yes' : 'No'}',
      );

      final post = Post.fromSpotifyTrack(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        track: track,
        caption: caption,
        mood: mood,
        rating: rating,
      );

      await docRef.set(post.toFirestore());
      debugPrint('✅ PostService: Post created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ PostService: Create post error: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  // Get all posts for community feed
  static Stream<List<Post>> getAllPosts({int limit = 50}) {
    debugPrint('🌍 PostService: Getting all posts (limit: $limit)');

    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          debugPrint('🌍 PostService: Received ${snapshot.docs.length} posts');
          return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        });
  }

  // Get posts by a specific user
  static Stream<List<Post>> getUserPosts(String userId) {
    debugPrint('📖 PostService: Getting posts for user: $userId');

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '📖 PostService: Received ${snapshot.docs.length} user posts',
          );
          return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        });
  }

  // Like/unlike a post
  static Future<void> toggleLike(String postId, String userId) async {
    debugPrint(
      '❤️ PostService: Toggling like for post: $postId by user: $userId',
    );

    try {
      final postRef = _firestore.collection(_collection).doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final post = Post.fromFirestore(postDoc);
        final isCurrentlyLiked = post.isLikedBy(userId);

        List<String> newLikedBy = List.from(post.likedBy);
        int newLikesCount = post.likesCount;

        if (isCurrentlyLiked) {
          // Unlike
          newLikedBy.remove(userId);
          newLikesCount = (newLikesCount - 1).clamp(0, double.infinity).toInt();
        } else {
          // Like
          if (!newLikedBy.contains(userId)) {
            newLikedBy.add(userId);
            newLikesCount++;
          }
        }

        transaction.update(postRef, {
          'likedBy': newLikedBy,
          'likesCount': newLikesCount,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });

      debugPrint('✅ PostService: Like toggled successfully');
    } catch (e) {
      debugPrint('❌ PostService: Toggle like error: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Delete a post
  static Future<void> deletePost(String postId) async {
    debugPrint('🗑️ PostService: Deleting post: $postId');

    try {
      await _firestore.collection(_collection).doc(postId).delete();
      debugPrint('✅ PostService: Post deleted successfully');
    } catch (e) {
      debugPrint('❌ PostService: Delete post error: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // Update a post
  static Future<void> updatePost({
    required String postId,
    String? caption,
    Mood? mood,
    int? rating,
  }) async {
    debugPrint('✏️ PostService: Updating post: $postId');

    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (caption != null) updateData['caption'] = caption;
      if (mood != null) updateData['mood'] = mood.name;
      if (rating != null) updateData['rating'] = rating;

      await _firestore.collection(_collection).doc(postId).update(updateData);
      debugPrint('✅ PostService: Post updated successfully');
    } catch (e) {
      debugPrint('❌ PostService: Update post error: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  // Get trending tracks from posts
  static Future<List<Map<String, dynamic>>> getTrendingTracksFromPosts({
    int limit = 20,
  }) async {
    debugPrint(
      '📈 PostService: Getting trending tracks from posts (limit: $limit)',
    );

    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot =
          await _firestore
              .collection(_collection)
              .where('createdAt', isGreaterThan: oneWeekAgo)
              .get();

      debugPrint(
        '📈 PostService: Analyzing ${snapshot.docs.length} recent posts',
      );

      // Count track occurrences
      final trackCounts = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final post = Post.fromFirestore(doc);
        final trackKey = '${post.trackName}_${post.artistName}';

        if (trackCounts.containsKey(trackKey)) {
          trackCounts[trackKey]!['count']++;
        } else {
          trackCounts[trackKey] = {
            'trackName': post.trackName,
            'artistName': post.artistName,
            'albumName': post.albumName,
            'albumImageUrl': post.albumImageUrl,
            'trackId': post.trackId,
            'count': 1,
          };
        }
      }

      // Sort by count and return top tracks
      final sortedTracks =
          trackCounts.values.toList()
            ..sort((a, b) => b['count'].compareTo(a['count']));

      final result = sortedTracks.take(limit).toList();
      debugPrint(
        '📈 PostService: Found ${result.length} trending tracks from posts',
      );
      return result;
    } catch (e) {
      debugPrint('❌ PostService: Get trending tracks error: $e');
      throw Exception('Failed to get trending tracks: $e');
    }
  }
}
