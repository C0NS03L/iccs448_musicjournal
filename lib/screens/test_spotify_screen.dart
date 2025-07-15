import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import '../models/spotify_models.dart';

class TestSpotifyScreen extends StatefulWidget {
  @override
  State<TestSpotifyScreen> createState() => _TestSpotifyScreenState();
}

class _TestSpotifyScreenState extends State<TestSpotifyScreen> {
  final _searchController = TextEditingController();
  List<SpotifyTrack> _tracks = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _searchTracks() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await SpotifyService.searchTracks(_searchController.text);
      setState(() {
        _tracks = result.tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Spotify')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for music',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchTracks,
                ),
              ),
              onSubmitted: (_) => _searchTracks(),
            ),
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Error: $_error',
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                return ListTile(
                  leading:
                      track.album.imageUrl != null
                          ? Image.network(
                            track.album.imageUrl!,
                            width: 50,
                            height: 50,
                          )
                          : Icon(Icons.music_note),
                  title: Text(track.name),
                  subtitle: Text('${track.artistNames} • ${track.album.name}'),
                  trailing: Text(track.formattedDuration),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
