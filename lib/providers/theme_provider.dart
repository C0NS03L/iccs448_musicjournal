import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _accentColorKey = 'accent_color';

  ThemeMode _themeMode = ThemeMode.light;
  double _fontSize = 16.0;
  Color _accentColor = Colors.blue;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  Color get accentColor => _accentColor;

  ThemeProvider() {
    _loadFromPrefs();
  }

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentColor,
        brightness: brightness,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: _fontSize),
        bodyMedium: TextStyle(fontSize: _fontSize - 2),
        bodySmall: TextStyle(fontSize: _fontSize - 4),
        headlineLarge: TextStyle(fontSize: _fontSize + 12),
        headlineMedium: TextStyle(fontSize: _fontSize + 8),
        headlineSmall: TextStyle(fontSize: _fontSize + 4),
        titleLarge: TextStyle(fontSize: _fontSize + 6),
        titleMedium: TextStyle(fontSize: _fontSize + 2),
        titleSmall: TextStyle(fontSize: _fontSize),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? null : _accentColor,
        foregroundColor: isDark ? null : Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(12.0, 24.0);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    _fontSize = prefs.getDouble(_fontSizeKey) ?? 16.0;

    final colorValue = prefs.getInt(_accentColorKey) ?? Colors.blue.value;
    _accentColor = Color(colorValue);

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    await prefs.setDouble(_fontSizeKey, _fontSize);
    await prefs.setInt(_accentColorKey, _accentColor.value);
  }

  // Helper methods for specific theme strings
  String get themeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  void setThemeFromString(String themeString) {
    switch (themeString) {
      case 'light':
        setThemeMode(ThemeMode.light);
        break;
      case 'dark':
        setThemeMode(ThemeMode.dark);
        break;
      case 'system':
        setThemeMode(ThemeMode.system);
        break;
    }
  }
}
