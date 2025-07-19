import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/spotify_config.dart';
import '../models/spotify_models.dart';
import 'package:flutter/foundation.dart';

class SpotifyService {
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  /// Get access token using Client Credentials flow (for searching public data)
  static Future<String> _getAccessToken() async {
    // Check if we have a valid token
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    debugPrint('🎵 SpotifyService: Getting new access token');

    try {
      final credentials = base64Encode(
        utf8.encode('${SpotifyConfig.clientId}:${SpotifyConfig.clientSecret}'),
      );

      final response = await http.post(
        Uri.parse(SpotifyConfig.authUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int; // seconds
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: expiresIn - 60),
        ); // 60s buffer

        debugPrint(
          '🎵 SpotifyService: Access token obtained, expires in ${expiresIn}s',
        );
        return _accessToken!;
      } else {
        debugPrint(
          '❌ SpotifyService: Auth failed: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to get Spotify access token: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ SpotifyService: Auth error: $e');
      throw Exception('Failed to authenticate with Spotify: $e');
    }
  }

  /// Search for tracks on Spotify
  static Future<SpotifySearchResult> searchTracks(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return SpotifySearchResult(
        tracks: [],
        total: 0,
        limit: limit,
        offset: offset,
      );
    }

    debugPrint('🔍 SpotifyService: Searching for "$query"');

    try {
      final token = await _getAccessToken();

      final uri = Uri.parse('${SpotifyConfig.baseUrl}/search').replace(
        queryParameters: {
          'q': query.trim(),
          'type': 'track',
          'limit': limit.toString(),
          'offset': offset.toString(),
          'market': 'US', // For availability
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = SpotifySearchResult.fromJson(data);
        debugPrint('🎵 SpotifyService: Found ${result.tracks.length} tracks');
        return result;
      } else {
        debugPrint(
          '❌ SpotifyService: Search failed: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to search Spotify: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ SpotifyService: Search error: $e');
      throw Exception('Failed to search tracks: $e');
    }
  }

  /// Get track details by ID
  static Future<SpotifyTrack?> getTrack(String trackId) async {
    debugPrint('🎵 SpotifyService: Getting track details for $trackId');

    try {
      final token = await _getAccessToken();

      final response = await http.get(
        Uri.parse('${SpotifyConfig.baseUrl}/tracks/$trackId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SpotifyTrack.fromJson(data);
      } else {
        debugPrint(
          '❌ SpotifyService: Get track failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ SpotifyService: Get track error: $e');
      return null;
    }
  }

  static Future<List<SpotifyTrack>> getPlaylistTracks(
    String playlistId, {
    int limit = 20,
  }) async {
    final token = await _getAccessToken();
    final uri = Uri.parse(
      'https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=$limit',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((item) {
        final trackJson = item['track'];
        return SpotifyTrack.fromJson(trackJson);
      }).toList();
    } else {
      throw Exception(
        'SpotifyService: Get playlist tracks failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Clear stored tokens (useful for testing)
  static void clearTokens() {
    _accessToken = null;
    _tokenExpiry = null;
  }
}
