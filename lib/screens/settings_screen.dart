import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            title: 'Dark Theme',
            subtitle: 'Light theme is the default. Switch this on for dark mode.',
            cardColor: cardColor,
            subtitleColor: scheme.onSurfaceVariant,
            trailing: Switch.adaptive(
              value: themeProvider.isDarkMode,
              activeThumbColor: const Color(AppConstants.primaryColor),
              onChanged: themeProvider.setDarkMode,
            ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Location Tracking'),
          _SettingsTile(
            title: 'Global Tracking',
            subtitle: 'Allow weau to collect and share your location heartbeat.',
            cardColor: cardColor,
            subtitleColor: scheme.onSurfaceVariant,
            trailing: Switch.adaptive(
              value: user.trackingEnabled,
              activeThumbColor: const Color(AppConstants.primaryColor),
              onChanged: (val) {
                auth.updateSettings(trackingEnabled: val);
              },
            ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Visibility Level'),
          _OptionTile(
            title: 'Public',
            subtitle: 'Any user can see your location on the map.',
            selected: user.visibilityLevel == 'public',
            cardColor: cardColor,
            subtitleColor: scheme.onSurfaceVariant,
            onTap: () => auth.updateSettings(visibilityLevel: 'public'),
          ),
          _OptionTile(
            title: 'Friends Only',
            subtitle: 'Only your confirmed friends can track you.',
            selected: user.visibilityLevel == 'friends',
            cardColor: cardColor,
            subtitleColor: scheme.onSurfaceVariant,
            onTap: () => auth.updateSettings(visibilityLevel: 'friends'),
          ),
          _OptionTile(
            title: 'Private',
            subtitle: 'Nobody can see your current location.',
            selected: user.visibilityLevel == 'none',
            cardColor: cardColor,
            subtitleColor: scheme.onSurfaceVariant,
            onTap: () => auth.updateSettings(visibilityLevel: 'none'),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Precision (Access Grain)'),
          _OptionTile(
            title: 'Exact Location',
            subtitle: 'Share your precise GPS coordinates.',
            selected: user.precisionLevel == 'exact',
            cardColor: cardColor,
            subtitleColor: scheme.onSurfaceVariant,
            onTap: () => auth.updateSettings(precisionLevel: 'exact'),
          ),
          _OptionTile(
            title: 'City Level (Blurred)',
            subtitle: 'Only share the general area (snapped to ~5km grid).',
            selected: user.precisionLevel == 'city',
            cardColor: cardColor,
            subtitleColor: scheme.onSurfaceVariant,
            onTap: () => auth.updateSettings(precisionLevel: 'city'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: const Color(AppConstants.accentColor),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color cardColor;
  final Color subtitleColor;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.cardColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 13)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color cardColor;
  final Color subtitleColor;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.cardColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(AppConstants.primaryColor).withValues(alpha: 0.2)
              : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(AppConstants.primaryColor) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 13)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Color(AppConstants.primaryColor)),
          ],
        ),
      ),
    );
  }
}
