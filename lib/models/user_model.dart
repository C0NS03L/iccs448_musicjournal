class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? bio;
  final UserPreferences preferences;
  final List<String> following;
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.bio,
    required this.preferences,
    this.following = const [],
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      bio: map['bio'],
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
      following: List<String>.from(map['following'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      lastActive: DateTime.parse(map['lastActive']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'preferences': preferences.toMap(),
      'following': following,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? bio,
    UserPreferences? preferences,
    List<String>? following,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      preferences: preferences ?? this.preferences,
      following: following ?? this.following,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class UserPreferences {
  final String theme; // 'light', 'dark', 'colorful'
  final double fontSize; // 14.0, 16.0, 18.0
  final String accentColor; // hex color string
  final List<String> favoriteGenres;

  UserPreferences({
    this.theme = 'light',
    this.fontSize = 16.0,
    this.accentColor = '#2196F3', // Material Blue
    this.favoriteGenres = const [],
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] ?? 'light',
      fontSize: (map['fontSize'] ?? 16.0).toDouble(),
      accentColor: map['accentColor'] ?? '#2196F3',
      favoriteGenres: List<String>.from(map['favoriteGenres'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'fontSize': fontSize,
      'accentColor': accentColor,
      'favoriteGenres': favoriteGenres,
    };
  }

  UserPreferences copyWith({
    String? theme,
    double? fontSize,
    String? accentColor,
    List<String>? favoriteGenres,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      accentColor: accentColor ?? this.accentColor,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
    );
  }
}
