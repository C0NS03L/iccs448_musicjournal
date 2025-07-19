import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import '../models/spotify_models.dart';
import 'add_journal_entry_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final String playlistId = '37i9dQZF1DXcBWIGoYBM5M'; // Today's Top Hits
  late Future<List<SpotifyTrack>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tracksFuture = SpotifyService.getPlaylistTracks(playlistId, limit: 20);
  }

  void _addToJournal(SpotifyTrack track) {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AddJournalEntryScreen(track: track, userId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Top Hits")),
      body: FutureBuilder<List<SpotifyTrack>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Unable to load tracks.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const Center(child: Text('No tracks found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Card(
                child: ListTile(
                  leading:
                      track.album.imageUrl != null
                          ? Image.network(
                            track.album.imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.music_note),
                  title: Text(track.name),
                  subtitle: Text('${track.artistNames} • ${track.album.name}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark_add),
                    tooltip: 'Add to Journal',
                    onPressed: () => _addToJournal(track),
                  ),
                  onTap: () => _addToJournal(track),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
