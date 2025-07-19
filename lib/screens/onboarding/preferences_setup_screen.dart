import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/auth_provider.dart';

class PreferencesSetupScreen extends StatefulWidget {
  const PreferencesSetupScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesSetupScreen> createState() => _PreferencesSetupScreenState();
}

class _PreferencesSetupScreenState extends State<PreferencesSetupScreen> {
  AppTheme? _selectedTheme;
  FontSize? _selectedFontSize;
  String? _selectedGenre;

  final List<String> _genres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'R&B',
    'Country',
    'Electronic',
    'Jazz',
    'Classical',
    'Folk',
    'Reggae',
    'Blues',
    'Metal',
    'Punk',
    'Indie',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Customize Your Experience',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Set up your preferences to make MyMusicJournal feel like home',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme selection
                  _buildSectionHeader(context, 'Choose Your Theme'),
                  const SizedBox(height: 12),
                  _buildThemeSelector(),

                  const SizedBox(height: 32),

                  // Font size selection
                  _buildSectionHeader(context, 'Font Size'),
                  const SizedBox(height: 12),
                  _buildFontSizeSelector(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply preferences button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _applyPreferences,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Preferences'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildThemeSelector() {
    return Column(
      children:
          AppTheme.values
              .map(
                (theme) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<AppTheme>(
                    title: Text(theme.label),
                    subtitle: Text(theme.description),
                    value: theme,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      setState(() {
                        _selectedTheme = value;
                      });
                    },
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildFontSizeSelector() {
    return Column(
      children:
          FontSize.values
              .map(
                (fontSize) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<FontSize>(
                    title: Text(fontSize.label),
                    subtitle: Text('Scale: ${fontSize.scale}x'),
                    value: fontSize,
                    groupValue: _selectedFontSize,
                    onChanged: (value) {
                      setState(() {
                        _selectedFontSize = value;
                      });
                    },
                  ),
                ),
              )
              .toList(),
    );
  }

  void _applyPreferences() async {
    final prefsProvider = Provider.of<PreferencesProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) return;

    // Apply selected preferences
    if (_selectedTheme != null) {
      await prefsProvider.updateTheme(_selectedTheme!, userId);
    }

    if (_selectedFontSize != null) {
      await prefsProvider.updateFontSize(_selectedFontSize!, userId);
    }

    if (_selectedGenre != null) {
      await prefsProvider.updatePreferredGenre(_selectedGenre, userId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences applied successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
