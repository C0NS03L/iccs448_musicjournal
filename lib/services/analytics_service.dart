import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'journal_entries';

  // Get all entries for user
  static Future<List<JournalEntry>> getAllEntries(String userId) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .get();
    return snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();
  }

  // Get mood counts
  static Future<Map<Mood, int>> getMoodCounts(String userId) async {
    final entries = await getAllEntries(userId);
    final moodCounts = <Mood, int>{};
    for (final entry in entries) {
      if (entry.mood != null) {
        moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
      }
    }
    return moodCounts;
  }

  // Get favorite artists
  static Future<Map<String, int>> getFavoriteArtists(String userId) async {
    final entries = await getAllEntries(userId);
    final artistCounts = <String, int>{};
    for (final entry in entries) {
      artistCounts[entry.artistName] =
          (artistCounts[entry.artistName] ?? 0) + 1;
    }
    return artistCounts;
  }

  // Get entries per month
  static Future<Map<String, int>> getEntriesPerMonth(String userId) async {
    final entries = await getAllEntries(userId);
    final counts = <String, int>{};
    for (final entry in entries) {
      final key =
          "${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}";
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  // Get average rating over time
  static Future<List<Map<String, dynamic>>> getAverageRatingPerMonth(
    String userId,
  ) async {
    final entries = await getAllEntries(userId);
    final ratingsByMonth = <String, List<int>>{};

    for (final entry in entries) {
      if (entry.rating != null) {
        final key =
            "${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}";
        ratingsByMonth.putIfAbsent(key, () => []).add(entry.rating!);
      }
    }

    return ratingsByMonth.entries
        .map(
          (e) => {
            'month': e.key,
            'avgRating':
                e.value.isEmpty
                    ? 0.0
                    : e.value.reduce((a, b) => a + b) / e.value.length,
          },
        )
        .toList();
  }
}
