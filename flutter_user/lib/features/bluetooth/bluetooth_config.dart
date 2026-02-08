class BluetoothConfig {
  // Connection settings - no license required for basic FlutterBluePlus functionality
  static const Duration connectionTimeout = Duration(seconds: 35);
  static const Duration reconnectionTimeout = Duration(seconds: 15);
  static const int defaultMtu = 512;
  static const bool autoConnect = true;
}
