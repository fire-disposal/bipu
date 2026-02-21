import 'dart:developer';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../models/contact/contact.dart';
import '../../models/message/message_response.dart';
import 'bluetooth_device_service.dart';

class MessageForwarder {
  final BluetoothDeviceService _bluetoothService;

  final List<Contact> Function() _contactsLookup;
  MessageForwarder(this._bluetoothService, this._contactsLookup);

  Future<void> forwardNewMessages(List<MessageResponse> newMessages) async {
    // Check connection state with retry logic
    if (!await _checkBluetoothConnection()) {
      log('MessageForwarder: Bluetooth not connected, skipping forwarding');
      return;
    }

    log('MessageForwarder: Forwarding ${newMessages.length} messages');

    for (final message in newMessages) {
      try {
        final formattedMessage = _formatMessageForBluetooth(message);
        await _sendToBluetooth(formattedMessage);
        log('MessageForwarder: Successfully forwarded message ${message.id}');
      } catch (e) {
        log('MessageForwarder: Failed to forward message ${message.id}: $e');
        // Continue with other messages even if one fails
      }
    }
  }

  /// Check Bluetooth connection with basic retry logic
  Future<bool> _checkBluetoothConnection() async {
    final state = _bluetoothService.connectionState.value;

    if (state == BluetoothConnectionState.connected) {
      return true;
    }

    // If connecting, wait a bit and check again
    if (state == BluetoothConnectionState.connecting) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _bluetoothService.connectionState.value ==
          BluetoothConnectionState.connected;
    }

    return false;
  }

  String _formatMessageForBluetooth(MessageResponse message) {
    final senderContact = _contactsLookup().firstWhere(
      (contact) => contact.contactBipupuId == message.senderBipupuId,
      orElse: () => Contact(
        id: 0,
        contactBipupuId: message.senderBipupuId,
        remark: 'Unknown',
        createdAt: DateTime.now(),
      ),
    );

    final senderName = senderContact.remark ?? senderContact.contactBipupuId;
    return 'From $senderName: ${message.content}';
  }

  /// Send message to Bluetooth with chunking for long messages
  Future<void> _sendToBluetooth(String message) async {
    const maxChunkSize = 200; // Conservative MTU limit for Bluetooth

    if (message.length <= maxChunkSize) {
      await _bluetoothService.sendTextMessage(message);
      return;
    }

    // Split long message into chunks
    for (var i = 0; i < message.length; i += maxChunkSize) {
      final end = i + maxChunkSize;
      final chunk = message.substring(
        i,
        end < message.length ? end : message.length,
      );
      await _bluetoothService.sendTextMessage(
        '[${(i ~/ maxChunkSize) + 1}] $chunk',
      );

      // Small delay between chunks to avoid overwhelming the Bluetooth stack
      if (end < message.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
