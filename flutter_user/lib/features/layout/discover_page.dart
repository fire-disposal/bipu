import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          _buildDiscoverItem(
            context,
            icon: Icons.bluetooth,
            title: 'Bluetooth Message',
            subtitle: 'Chat via BLE mesh',
            color: Colors.blue,
            route: '/bluetooth',
          ),
          _buildDiscoverItem(
            context,
            icon: Icons.mic,
            title: 'Speech Test',
            subtitle: 'Test voice recognition',
            color: Colors.red,
            route: '/speech_test',
          ),
          _buildDiscoverItem(
            context,
            icon: Icons.public,
            title: 'Moments',
            subtitle: 'Share your life',
            color: Colors.teal,
            route: null, // Not implemented
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? route,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        if (route != null) {
          context.push(route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feature coming soon')),
          );
        }
      },
    );
  }
}
