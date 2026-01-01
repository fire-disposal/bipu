import 'package:flutter/material.dart';
import '../../core/services/theme_service.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement language selection
                  },
                ),
                const Divider(),
                ListenableBuilder(
                  listenable: ThemeService(),
                  builder: (context, _) {
                    final currentMode = ThemeService().themeMode;
                    return ListTile(
                      leading: const Icon(Icons.brightness_6),
                      title: const Text('Theme'),
                      subtitle: Text(currentMode.toString().split('.').last),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showThemeDialog(context, currentMode),
                    );
                  },
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                  subtitle: Text('Bipupu Admin Panel v1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Theme'),
        children: [
          _buildThemeOption(
            context,
            'System Default',
            ThemeMode.system,
            currentMode,
          ),
          _buildThemeOption(context, 'Light', ThemeMode.light, currentMode),
          _buildThemeOption(context, 'Dark', ThemeMode.dark, currentMode),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        ThemeService().updateThemeMode(mode);
        Navigator.pop(context);
      },
      child: Row(
        children: [
          Icon(
            mode == currentMode
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: mode == currentMode
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
