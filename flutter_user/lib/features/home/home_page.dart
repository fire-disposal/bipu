import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/bluetooth/ble_pipeline.dart';
import '../../core/bluetooth/ble_simple_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BlePipeline _blePipeline = BlePipeline();
  late final SimpleBleState _bleState;

  @override
  void initState() {
    super.initState();
    _bleState = SimpleBleState();
    _bleState.addListener(_onBleStateChanged);
  }

  @override
  void dispose() {
    _bleState.removeListener(_onBleStateChanged);
    _bleState.dispose();
    super.dispose();
  }

  void _onBleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildConnectionStatus() {
    if (_bleState.isConnecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 4),
            Text(
              'Connecting',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (_bleState.isConnected) {
      final batteryLevel = _bleState.batteryLevel;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bluetooth_connected,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              'Connected',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (batteryLevel != null) ...[
              const SizedBox(width: 8),
              Icon(
                batteryLevel > 20 ? Icons.battery_std : Icons.battery_alert,
                size: 14,
                color: batteryLevel > 20 ? Colors.green : Colors.red,
              ),
              Text(
                '$batteryLevel%',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.error),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off,
              size: 14,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Disconnected',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BIPUPU',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: 'Bluetooth',
            onPressed: () {
              if (_bleState.isConnected) {
                context.push('/bluetooth/control');
              } else {
                context.push('/bluetooth/scan');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Primary Device',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Connection status
                        _buildConnectionStatus(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.developer_board,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _bleState.isConnected
                                  ? (_bleState.connectedDevice?.platformName ??
                                        'Unknown Device')
                                  : 'No Device Bound',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _bleState.isConnected
                                  ? 'ID: ${_bleState.connectedDevice?.remoteId.str ?? '--'}'
                                  : 'ID: --',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_bleState.isConnected) {
                          context.push('/bluetooth/control');
                        } else {
                          context.push('/bluetooth/scan');
                        }
                      },
                      icon: Icon(
                        _bleState.isConnected
                            ? Icons.settings_remote
                            : Icons.add_link,
                      ),
                      label: Text(
                        _bleState.isConnected
                            ? 'Control Device'
                            : 'Connect Device',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions / Widgets
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickActionCard(
                    context,
                    'Contacts',
                    Icons.people,
                    Colors.purple,
                    () => context.push('/contacts'),
                  ),
                  _buildQuickActionCard(
                    context,
                    'Discover',
                    Icons.explore,
                    Colors.orange,
                    () {
                      context.push('/discover');
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    'Subscription',
                    Icons.card_membership,
                    Colors.teal,
                    () => context.push('/subscription'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
