import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../models/spotify_models.dart';
import 'auth_service.dart';

class JournalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'journal_entries';
  static final AuthService _authService = AuthService();

  static Future<String> createEntry({
    required String userId,
    required SpotifyTrack track,
    String? personalNotes,
    Mood? mood,
    int? rating,
    bool isPublic = true,
  }) async {
    debugPrint(
      '📝 JournalService: Creating entry for "${track.name}" by ${track.artistNames}',
    );

    try {
      final docRef = _firestore.collection(_collection).doc();

      // Automatically fetch user info when creating entry
      debugPrint('👤 JournalService: Fetching user info for $userId');
      final userInfo = await _authService.getUserInfo(userId);
      final userName = userInfo['displayName'];
      final userPhotoUrl = userInfo['photoURL'];

      debugPrint(
        '👤 JournalService: Found user info - Name: $userName, Photo: ${userPhotoUrl != null ? 'Yes' : 'No'}',
      );

      final entry = JournalEntry.fromSpotifyTrack(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        track: track,
        personalNotes: personalNotes,
        mood: mood,
        rating: rating,
        isPublic: isPublic,
      );

      await docRef.set(entry.toFirestore());
      debugPrint('✅ JournalService: Entry created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ JournalService: Create entry error: $e');
      throw Exception('Failed to create journal entry: $e');
    }
  }

  static Stream<List<JournalEntry>> getUserEntries(String userId) {
    debugPrint('📖 JournalService: Getting entries for user: $userId');

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '📖 JournalService: Received ${snapshot.docs.length} entries',
          );
          return snapshot.docs
              .map((doc) => JournalEntry.fromFirestore(doc))
              .toList();
        });
  }

  // NEW: Get all public entries for community feed
  static Stream<List<JournalEntry>> getAllPublicEntries({int limit = 50}) {
    debugPrint('🌍 JournalService: Getting public entries (limit: $limit)');

    return _firestore
        .collection(_collection)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '🌍 JournalService: Received ${snapshot.docs.length} public entries',
          );
          return snapshot.docs
              .map((doc) => JournalEntry.fromFirestore(doc))
              .toList();
        });
  }

  // NEW: Get trending tracks (most journaled songs recently)
  static Future<List<Map<String, dynamic>>> getTrendingTracks({
    int limit = 20,
  }) async {
    debugPrint('📈 JournalService: Getting trending tracks (limit: $limit)');

    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot =
          await _firestore
              .collection(_collection)
              .where('isPublic', isEqualTo: true)
              .where('createdAt', isGreaterThan: oneWeekAgo)
              .get();

      debugPrint(
        '📈 JournalService: Analyzing ${snapshot.docs.length} recent entries',
      );

      // Count track occurrences
      final trackCounts = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final entry = JournalEntry.fromFirestore(doc);
        final trackKey = '${entry.trackName}_${entry.artistName}';

        if (trackCounts.containsKey(trackKey)) {
          trackCounts[trackKey]!['count']++;
        } else {
          trackCounts[trackKey] = {
            'trackName': entry.trackName,
            'artistName': entry.artistName,
            'albumName': entry.albumName,
            'albumImageUrl': entry.albumImageUrl,
            'trackId': entry.trackId,
            'count': 1,
          };
        }
      }

      // Sort by count and return top tracks
      final sortedTracks =
          trackCounts.values.toList()
            ..sort((a, b) => b['count'].compareTo(a['count']));

      final result = sortedTracks.take(limit).toList();
      debugPrint('📈 JournalService: Found ${result.length} trending tracks');
      return result;
    } catch (e) {
      debugPrint('❌ JournalService: Get trending tracks error: $e');
      throw Exception('Failed to get trending tracks: $e');
    }
  }

  static Future<void> updateEntry({
    required String entryId,
    String? personalNotes,
    Mood? mood,
    int? rating,
    bool? isPublic,
  }) async {
    debugPrint('✏️ JournalService: Updating entry: $entryId');

    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (personalNotes != null) updateData['personalNotes'] = personalNotes;
      if (mood != null) updateData['mood'] = mood.name;
      if (rating != null) updateData['rating'] = rating;
      if (isPublic != null) updateData['isPublic'] = isPublic;

      await _firestore.collection(_collection).doc(entryId).update(updateData);
      debugPrint('✅ JournalService: Entry updated successfully');
    } catch (e) {
      debugPrint('❌ JournalService: Update entry error: $e');
      throw Exception('Failed to update journal entry: $e');
    }
  }

  static Future<void> deleteEntry(String entryId) async {
    debugPrint('🗑️ JournalService: Deleting entry: $entryId');

    try {
      await _firestore.collection(_collection).doc(entryId).delete();
      debugPrint('✅ JournalService: Entry deleted successfully');
    } catch (e) {
      debugPrint('❌ JournalService: Delete entry error: $e');
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    debugPrint('📊 JournalService: Getting stats for user: $userId');

    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .get();

      final entries =
          snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();

      final totalEntries = entries.length;
      final uniqueArtists = entries.map((e) => e.artistName).toSet().length;
      final uniqueAlbums = entries.map((e) => e.albumName).toSet().length;
      final averageRating =
          entries.where((e) => e.rating != null).isEmpty
              ? 0.0
              : entries
                      .where((e) => e.rating != null)
                      .map((e) => e.rating!)
                      .reduce((a, b) => a + b) /
                  entries.where((e) => e.rating != null).length;

      final moodCounts = <Mood, int>{};
      for (final entry in entries) {
        if (entry.mood != null) {
          moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
        }
      }

      final mostCommonMood =
          moodCounts.isNotEmpty
              ? moodCounts.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key
              : null;

      final stats = {
        'totalEntries': totalEntries,
        'uniqueArtists': uniqueArtists,
        'uniqueAlbums': uniqueAlbums,
        'averageRating': averageRating,
        'mostCommonMood': mostCommonMood?.name,
      };

      debugPrint('📊 JournalService: Stats calculated: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ JournalService: Get stats error: $e');
      throw Exception('Failed to get user stats: $e');
    }
  }

  static Future<JournalEntry?> getExistingEntry(
    String userId,
    String trackId,
  ) async {
    debugPrint('🔍 JournalService: Checking for existing entry: $trackId');

    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('trackId', isEqualTo: trackId)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final entry = JournalEntry.fromFirestore(snapshot.docs.first);
        debugPrint('✅ JournalService: Found existing entry');
        return entry;
      }

      debugPrint('📝 JournalService: No existing entry found');
      return null;
    } catch (e) {
      debugPrint('❌ JournalService: Check existing entry error: $e');
      return null;
    }
  }
}
