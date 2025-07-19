import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/preferences_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: Consumer2<PreferencesProvider, AuthProvider>(
        builder: (context, prefsProvider, authProvider, child) {
          final userId = authProvider.currentUser?.uid;

          if (userId == null) {
            return const Center(
              child: Text('Please log in to access settings'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Appearance'),
                _buildAppearanceSection(context, prefsProvider, userId),
                const SizedBox(height: 24),

                _buildSectionTitle(context, 'Journal & Posts'),
                _buildJournalSection(context, prefsProvider, userId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    PreferencesProvider provider,
    String userId,
  ) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(provider.preferences.appTheme.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, provider, userId),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Size'),
            subtitle: Text(provider.preferences.fontSize.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFontSizeDialog(context, provider, userId),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalSection(
    BuildContext context,
    PreferencesProvider provider,
    String userId,
  ) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.public),
            title: const Text('Default Public Posts'),
            subtitle: const Text('Make new journal entries public by default'),
            value: provider.preferences.defaultPublicPosts,
            onChanged:
                (value) => provider.updateDefaultPublicPosts(value, userId),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    PreferencesProvider provider,
    String userId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  AppTheme.values
                      .map(
                        (theme) => RadioListTile<AppTheme>(
                          title: Text(theme.label),
                          subtitle: Text(theme.description),
                          value: theme,
                          groupValue: provider.preferences.appTheme,
                          onChanged: (value) {
                            if (value != null) {
                              provider.updateTheme(value, userId);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  void _showFontSizeDialog(
    BuildContext context,
    PreferencesProvider provider,
    String userId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Font Size'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  FontSize.values
                      .map(
                        (fontSize) => RadioListTile<FontSize>(
                          title: Text(fontSize.label),
                          subtitle: Text('Scale: ${fontSize.scale}x'),
                          value: fontSize,
                          groupValue: provider.preferences.fontSize,
                          onChanged: (value) {
                            if (value != null) {
                              provider.updateFontSize(value, userId);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }
}
