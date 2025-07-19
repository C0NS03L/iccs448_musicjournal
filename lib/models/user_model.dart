import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? bio;
  final UserPreferences preferences;
  final List<String> following;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool onboardingCompleted;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.bio,
    required this.preferences,
    this.following = const [],
    required this.createdAt,
    required this.lastActive,
    this.onboardingCompleted = false,
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
      onboardingCompleted: map['onboardingCompleted'] ?? false,
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
      'onboardingCompleted': onboardingCompleted,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? bio,
    UserPreferences? preferences,
    List<String>? following,
    DateTime? lastActive,
    bool? onboardingCompleted,
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
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  String get userInitials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return displayName!.substring(0, 2).toUpperCase();
      }
    } else if (email.isNotEmpty) {
      return email.substring(0, 2).toUpperCase();
    }
    return 'U';
  }

  String get displayUserName {
    return displayName ?? email.split('@')[0];
  }
}

// Enhanced UserPreferences class with all the new features
enum AppTheme {
  system('System', 'Follow device theme'),
  light('Light', 'Light theme'),
  dark('Dark', 'Dark theme'),
  colorful('Colorful', 'Vibrant music-themed colors');

  const AppTheme(this.label, this.description);
  final String label;
  final String description;
}

enum FontSize {
  small('Small', 14.0, 0.9),
  medium('Medium', 16.0, 1.0),
  large('Large', 18.0, 1.1),
  extraLarge('Extra Large', 20.0, 1.2);

  const FontSize(this.label, this.size, this.scale);
  final String label;
  final double size;
  final double scale;
}

class UserPreferences {
  final AppTheme appTheme;
  final FontSize fontSize;
  final String accentColor; // Keep your existing hex color
  final List<String> favoriteGenres;
  final bool enableNotifications;
  final bool autoSaveJournalEntries;
  final bool defaultPublicPosts;
  final bool showMoodEmojis;
  final bool enableHapticFeedback;
  final String? preferredGenre;
  final DateTime? lastUpdated;

  UserPreferences({
    this.appTheme = AppTheme.system,
    this.fontSize = FontSize.medium,
    this.accentColor = '#2196F3', // Keep your existing default
    this.favoriteGenres = const [],
    this.enableNotifications = true,
    this.autoSaveJournalEntries = true,
    this.defaultPublicPosts = true,
    this.showMoodEmojis = true,
    this.enableHapticFeedback = true,
    this.preferredGenre,
    this.lastUpdated,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      appTheme: AppTheme.values.firstWhere(
        (t) =>
            t.name == map['appTheme'] ||
            t.name == map['theme'], // Support both old and new
        orElse: () => AppTheme.system,
      ),
      fontSize: FontSize.values.firstWhere(
        (f) => f.size == (map['fontSize'] ?? 16.0).toDouble(),
        orElse: () => FontSize.medium,
      ),
      accentColor: map['accentColor'] ?? '#2196F3',
      favoriteGenres: List<String>.from(map['favoriteGenres'] ?? []),
      enableNotifications: map['enableNotifications'] ?? true,
      autoSaveJournalEntries: map['autoSaveJournalEntries'] ?? true,
      defaultPublicPosts: map['defaultPublicPosts'] ?? true,
      showMoodEmojis: map['showMoodEmojis'] ?? true,
      enableHapticFeedback: map['enableHapticFeedback'] ?? true,
      preferredGenre: map['preferredGenre'],
      lastUpdated:
          map['lastUpdated'] != null
              ? DateTime.parse(map['lastUpdated'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appTheme': appTheme.name,
      'theme': appTheme.name, // Keep for backward compatibility
      'fontSize': fontSize.size,
      'accentColor': accentColor,
      'favoriteGenres': favoriteGenres,
      'enableNotifications': enableNotifications,
      'autoSaveJournalEntries': autoSaveJournalEntries,
      'defaultPublicPosts': defaultPublicPosts,
      'showMoodEmojis': showMoodEmojis,
      'enableHapticFeedback': enableHapticFeedback,
      'preferredGenre': preferredGenre,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    AppTheme? appTheme,
    FontSize? fontSize,
    String? accentColor,
    List<String>? favoriteGenres,
    bool? enableNotifications,
    bool? autoSaveJournalEntries,
    bool? defaultPublicPosts,
    bool? showMoodEmojis,
    bool? enableHapticFeedback,
    String? preferredGenre,
  }) {
    return UserPreferences(
      appTheme: appTheme ?? this.appTheme,
      fontSize: fontSize ?? this.fontSize,
      accentColor: accentColor ?? this.accentColor,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoSaveJournalEntries:
          autoSaveJournalEntries ?? this.autoSaveJournalEntries,
      defaultPublicPosts: defaultPublicPosts ?? this.defaultPublicPosts,
      showMoodEmojis: showMoodEmojis ?? this.showMoodEmojis,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      preferredGenre: preferredGenre ?? this.preferredGenre,
      lastUpdated: DateTime.now(),
    );
  }

  // Helper method to get hex color as Color object
  Color get accentColorValue {
    try {
      return Color(int.parse(accentColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue; // Fallback
    }
  }

  // Backward compatibility - convert old string theme to AppTheme
  static AppTheme _themeFromString(String? themeString) {
    switch (themeString) {
      case 'light':
        return AppTheme.light;
      case 'dark':
        return AppTheme.dark;
      case 'colorful':
        return AppTheme.colorful;
      default:
        return AppTheme.system;
    }
  }
}
