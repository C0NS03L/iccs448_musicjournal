import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart'; // Import from user_model.dart instead
import '../services/auth_service.dart';

class PreferencesProvider extends ChangeNotifier {
  UserPreferences _preferences = UserPreferences();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  UserPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;

  // Get theme data based on preferences
  ThemeData getThemeData(BuildContext context) {
    final brightness = _getThemeBrightness(context);
    final colorScheme = _getColorScheme(brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      textTheme: _getScaledTextTheme(context, brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        systemOverlayStyle:
            brightness == Brightness.light
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Brightness _getThemeBrightness(BuildContext context) {
    switch (_preferences.appTheme) {
      case AppTheme.light:
        return Brightness.light;
      case AppTheme.dark:
        return Brightness.dark;
      case AppTheme.system:
        return MediaQuery.of(context).platformBrightness;
      case AppTheme.colorful:
        return Brightness.dark; // Colorful theme is dark-based
    }
  }

  ColorScheme _getColorScheme(Brightness brightness) {
    switch (_preferences.appTheme) {
      case AppTheme.colorful:
        return ColorScheme.fromSeed(
          seedColor: _preferences.accentColorValue,
          brightness: brightness,
        ).copyWith(
          primary: _preferences.accentColorValue,
          secondary: const Color(0xFFEC4899),
          tertiary: const Color(0xFF06B6D4),
        );
      default:
        return ColorScheme.fromSeed(
          seedColor: _preferences.accentColorValue,
          brightness: brightness,
        );
    }
  }

  TextTheme _getScaledTextTheme(BuildContext context, Brightness brightness) {
    final baseTheme =
        brightness == Brightness.light
            ? ThemeData.light().textTheme
            : ThemeData.dark().textTheme;

    final scale = _preferences.fontSize.scale;

    // First, ensure all text styles have default font sizes
    final textThemeWithDefaults = TextTheme(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: baseTheme.displayLarge?.fontSize ?? 57,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: baseTheme.displayMedium?.fontSize ?? 45,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: baseTheme.displaySmall?.fontSize ?? 36,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: baseTheme.headlineLarge?.fontSize ?? 32,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: baseTheme.headlineMedium?.fontSize ?? 28,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: baseTheme.headlineSmall?.fontSize ?? 24,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: baseTheme.titleLarge?.fontSize ?? 22,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: baseTheme.titleMedium?.fontSize ?? 16,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: baseTheme.titleSmall?.fontSize ?? 14,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: baseTheme.bodyLarge?.fontSize ?? 16,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: baseTheme.bodyMedium?.fontSize ?? 14,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: baseTheme.bodySmall?.fontSize ?? 12,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: baseTheme.labelLarge?.fontSize ?? 14,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: baseTheme.labelMedium?.fontSize ?? 12,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: baseTheme.labelSmall?.fontSize ?? 11,
      ),
    );

    // Now apply the scaling safely
    return textThemeWithDefaults.apply(
      fontSizeFactor: scale,
      fontFamily: 'Roboto',
    );
  }

  // Load preferences from Firestore
  Future<void> loadPreferences(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = await _authService.getUserDocument(userId);
      if (userDoc?.preferences != null) {
        _preferences = userDoc!.preferences;
      }
    } catch (e) {
      debugPrint('❌ Failed to load preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save preferences to Firestore
  Future<void> savePreferences(String userId) async {
    try {
      await _authService.updateUserDocument(userId, {
        'preferences': _preferences.toMap(),
      });
      debugPrint('✅ Preferences saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save preferences: $e');
      throw Exception('Failed to save preferences: $e');
    }
  }

  // Update specific preferences
  Future<void> updateTheme(AppTheme theme, String userId) async {
    _preferences = _preferences.copyWith(appTheme: theme);
    notifyListeners();
    await savePreferences(userId);
  }

  Future<void> updateFontSize(FontSize fontSize, String userId) async {
    _preferences = _preferences.copyWith(fontSize: fontSize);
    notifyListeners();
    await savePreferences(userId);
  }

  Future<void> updateAccentColor(String colorHex, String userId) async {
    _preferences = _preferences.copyWith(accentColor: colorHex);
    notifyListeners();
    await savePreferences(userId);
  }

  Future<void> updateNotifications(bool enabled, String userId) async {
    _preferences = _preferences.copyWith(enableNotifications: enabled);
    notifyListeners();
    await savePreferences(userId);
  }

  Future<void> updateAutoSave(bool enabled, String userId) async {
    _preferences = _preferences.copyWith(autoSaveJournalEntries: enabled);
    notifyListeners();
    await savePreferences(userId);
  }

  Future<void> updateDefaultPublicPosts(bool enabled, String userId) async {
    _preferences = _preferences.copyWith(defaultPublicPosts: enabled);
    notifyListeners();
    await savePreferences(userId);
  }

  Future<void> updateShowMoodEmojis(bool enabled, String userId) async {
    _preferences = _preferences.copyWith(showMoodEmojis: enabled);
    notifyListeners();
    await savePreferences(userId);
  }

  Future<void> updateHapticFeedback(bool enabled, String userId) async {
    _preferences = _preferences.copyWith(enableHapticFeedback: enabled);
    notifyListeners();
    await savePreferences(userId);

    // Apply haptic feedback setting immediately
    if (enabled) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> updatePreferredGenre(String? genre, String userId) async {
    _preferences = _preferences.copyWith(preferredGenre: genre);
    notifyListeners();
    await savePreferences(userId);
  }

  Future<void> updateFavoriteGenres(List<String> genres, String userId) async {
    _preferences = _preferences.copyWith(favoriteGenres: genres);
    notifyListeners();
    await savePreferences(userId);
  }

  // Trigger haptic feedback if enabled
  void hapticFeedback() {
    if (_preferences.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }
}
