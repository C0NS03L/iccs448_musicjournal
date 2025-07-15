class SpotifyTrack {
  final String id;
  final String name;
  final List<SpotifyArtist> artists;
  final SpotifyAlbum album;
  final int durationMs;
  final String? previewUrl;
  final int popularity;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
    required this.durationMs,
    this.previewUrl,
    required this.popularity,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      artists:
          (json['artists'] as List?)
              ?.map((artist) => SpotifyArtist.fromJson(artist))
              .toList() ??
          [],
      album: SpotifyAlbum.fromJson(json['album'] ?? {}),
      durationMs: json['duration_ms'] ?? 0,
      previewUrl: json['preview_url'],
      popularity: json['popularity'] ?? 0,
    );
  }

  String get artistNames => artists.map((artist) => artist.name).join(', ');

  String get formattedDuration {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class SpotifyArtist {
  final String id;
  final String name;

  SpotifyArtist({required this.id, required this.name});

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(id: json['id'] ?? '', name: json['name'] ?? '');
  }
}

class SpotifyAlbum {
  final String id;
  final String name;
  final List<SpotifyImage> images;
  final String? releaseDate;

  SpotifyAlbum({
    required this.id,
    required this.name,
    required this.images,
    this.releaseDate,
  });

  factory SpotifyAlbum.fromJson(Map<String, dynamic> json) {
    return SpotifyAlbum(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      images:
          (json['images'] as List?)
              ?.map((image) => SpotifyImage.fromJson(image))
              .toList() ??
          [],
      releaseDate: json['release_date'],
    );
  }

  String? get imageUrl {
    if (images.isEmpty) return null;
    // Return medium-sized image (usually index 1)
    return images.length > 1 ? images[1].url : images[0].url;
  }

  String? get smallImageUrl {
    if (images.isEmpty) return null;
    // Return smallest image (usually last)
    return images.last.url;
  }
}

class SpotifyImage {
  final String url;
  final int? height;
  final int? width;

  SpotifyImage({required this.url, this.height, this.width});

  factory SpotifyImage.fromJson(Map<String, dynamic> json) {
    return SpotifyImage(
      url: json['url'] ?? '',
      height: json['height'],
      width: json['width'],
    );
  }
}

class SpotifySearchResult {
  final List<SpotifyTrack> tracks;
  final int total;
  final int limit;
  final int offset;

  SpotifySearchResult({
    required this.tracks,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory SpotifySearchResult.fromJson(Map<String, dynamic> json) {
    final tracksData = json['tracks'] ?? {};
    return SpotifySearchResult(
      tracks:
          (tracksData['items'] as List?)
              ?.map((track) => SpotifyTrack.fromJson(track))
              .toList() ??
          [],
      total: tracksData['total'] ?? 0,
      limit: tracksData['limit'] ?? 0,
      offset: tracksData['offset'] ?? 0,
    );
  }
}
