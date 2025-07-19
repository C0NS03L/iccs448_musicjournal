import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../models/post_entry.dart';
import '../services/journal_service.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

// Create a unified feed item class
class FeedItem {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumImageUrl;
  final String? content; // caption for posts, personalNotes for journal entries
  final Mood? mood;
  final int? rating;
  final DateTime createdAt;
  final String type; // 'post' or 'journal'
  final int likesCount;
  final List<String> likedBy;
  final bool isPublic; // Only relevant for journal entries

  FeedItem({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumImageUrl,
    this.content,
    this.mood,
    this.rating,
    required this.createdAt,
    required this.type,
    this.likesCount = 0,
    this.likedBy = const [],
    this.isPublic = true,
  });

  // Create from Post
  factory FeedItem.fromPost(Post post) {
    return FeedItem(
      id: post.id,
      userId: post.userId,
      userName: post.userName,
      userPhotoUrl: post.userPhotoUrl,
      trackName: post.trackName,
      artistName: post.artistName,
      albumName: post.albumName,
      albumImageUrl: post.albumImageUrl,
      content: post.caption,
      mood: post.mood,
      rating: post.rating,
      createdAt: post.createdAt,
      type: 'post',
      likesCount: post.likesCount,
      likedBy: post.likedBy,
    );
  }

  // Create from JournalEntry (only public ones)
  factory FeedItem.fromJournalEntry(JournalEntry entry) {
    return FeedItem(
      id: entry.id,
      userId: entry.userId,
      userName: entry.userName,
      userPhotoUrl: entry.userPhotoUrl,
      trackName: entry.trackName,
      artistName: entry.artistName,
      albumName: entry.albumName,
      albumImageUrl: entry.albumImageUrl,
      content: entry.personalNotes,
      mood: entry.mood,
      rating: entry.rating,
      createdAt: entry.createdAt,
      type: 'journal',
      isPublic: entry.isPublic,
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

  String get displayUserName {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }
    return 'User ${userId.substring(0, 8)}...';
  }

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

  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}

class FeedTab extends StatefulWidget {
  const FeedTab({Key? key}) : super(key: key);

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  // Cache for user info to avoid repeated API calls
  final Map<String, Map<String, String?>> _userInfoCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view your feed.'));
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Journal', icon: Icon(Icons.person)),
            Tab(text: 'Community', icon: Icon(Icons.people)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildMyFeed(userId), _buildCommunityFeed()],
          ),
        ),
      ],
    );
  }

  // Keep your existing _buildMyFeed and _buildCommunityFeed methods...

  Widget _buildEmptyFeed(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Journal list for "My Journal" tab - UPDATED with theme colors
  Widget _buildJournalList(List<JournalEntry> entries) {
    final currentUserId = Provider.of<AuthProvider>(context).currentUser?.uid;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy indicator and date - UPDATED colors
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          entry.isPublic ? Icons.public : Icons.lock,
                          size: 16,
                          color:
                              entry.isPublic
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.isPublic ? 'Public' : 'Private',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                entry.isPublic
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      entry.formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Track info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          entry.albumImageUrl != null
                              ? Image.network(
                                entry.albumImageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 60,
                                height: 60,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.trackName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${entry.artistName} • ${entry.albumName}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (entry.mood != null) ...[
                                Text(entry.mood!.displayName),
                                const SizedBox(width: 12),
                              ],
                              if (entry.rating != null && entry.rating! > 0)
                                Row(
                                  children: List.generate(
                                    entry.rating!,
                                    (_) => Icon(
                                      Icons.star,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Options menu
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await _deleteJournalEntry(entry.id);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                    ),
                  ],
                ),

                // Personal notes - UPDATED colors
                if (entry.personalNotes != null &&
                    entry.personalNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.personalNotes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Unified feed list - UPDATED with theme colors
  Widget _buildUnifiedFeedList(List<FeedItem> feedItems) {
    final currentUserId = Provider.of<AuthProvider>(context).currentUser?.uid;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feedItems.length,
      itemBuilder: (context, index) {
        final item = feedItems[index];
        final isPost = item.type == 'post';
        final isLiked =
            currentUserId != null ? item.isLikedBy(currentUserId) : false;
        final isOwnItem = item.userId == currentUserId;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info header with content type indicator
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          item.userPhotoUrl != null
                              ? NetworkImage(item.userPhotoUrl!)
                              : null,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child:
                          item.userPhotoUrl == null
                              ? Text(
                                item.userInitials,
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.displayUserName,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              // Content type indicator - UPDATED colors
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isPost
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                          : Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isPost ? 'POST' : 'JOURNAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isPost
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item.formattedDate,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwnItem)
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            if (isPost) {
                              await _deletePost(item.id);
                            } else {
                              await _deleteJournalEntry(item.id);
                            }
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                if (item.content != null && item.content!.isNotEmpty) ...[
                  Text(
                    item.content!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],

                // Track info - UPDATED colors
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            item.albumImageUrl != null
                                ? Image.network(
                                  item.albumImageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  width: 50,
                                  height: 50,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.trackName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${item.artistName} • ${item.albumName}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
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

                // Mood and rating
                if (item.mood != null ||
                    (item.rating != null && item.rating! > 0)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (item.mood != null) ...[
                        Text(item.mood!.displayName),
                        const SizedBox(width: 12),
                      ],
                      if (item.rating != null && item.rating! > 0)
                        Row(
                          children: List.generate(
                            item.rating!,
                            (_) => Icon(
                              Icons.star,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // Like button (only for posts) - UPDATED colors
                if (isPost) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap:
                            currentUserId != null
                                ? () => _toggleLike(item.id, currentUserId)
                                : null,
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color:
                                  isLiked
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.likesCount}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Keep your existing helper methods unchanged...
  Future<void> _toggleLike(String postId, String userId) async {
    try {
      await PostService.toggleLike(postId, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to like post: $e')));
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await PostService.deletePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
      }
    }
  }

  Future<void> _deleteJournalEntry(String entryId) async {
    try {
      await JournalService.deleteEntry(entryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete entry: $e')));
      }
    }
  }

  // Keep the missing methods from your original code...
  Widget _buildMyFeed(String userId) {
    return StreamBuilder<List<JournalEntry>>(
      stream: JournalService.getUserEntries(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading your feed.'));
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return _buildEmptyFeed(
            'Your journal is empty!',
            'Start journaling music to see your activity here.',
          );
        }
        return _buildJournalList(entries);
      },
    );
  }

  Widget _buildCommunityFeed() {
    return StreamBuilder<List<Post>>(
      stream: PostService.getAllPosts(limit: 50),
      builder: (context, postSnapshot) {
        return StreamBuilder<List<JournalEntry>>(
          stream: JournalService.getAllPublicEntries(limit: 50),
          builder: (context, journalSnapshot) {
            if (postSnapshot.connectionState == ConnectionState.waiting ||
                journalSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (postSnapshot.hasError || journalSnapshot.hasError) {
              return const Center(child: Text('Error loading community feed.'));
            }

            final posts = postSnapshot.data ?? [];
            final journalEntries = journalSnapshot.data ?? [];

            // Convert to unified feed items
            final feedItems = <FeedItem>[];

            // Add posts
            feedItems.addAll(posts.map((post) => FeedItem.fromPost(post)));

            // Add public journal entries
            feedItems.addAll(
              journalEntries
                  .where((entry) => entry.isPublic)
                  .map((entry) => FeedItem.fromJournalEntry(entry)),
            );

            // Sort by creation date (newest first)
            feedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (feedItems.isEmpty) {
              return _buildEmptyFeed(
                'No community activity yet!',
                'Be the first to share your music with the community.',
              );
            }

            return _buildUnifiedFeedList(feedItems);
          },
        );
      },
    );
  }
}
