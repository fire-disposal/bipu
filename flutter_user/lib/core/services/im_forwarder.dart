import 'dart:developer';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../models/message/message_response.dart';
import '../../models/contact/contact.dart';
import 'bluetooth_device_service.dart';

class MessageForwarder {
  MessageForwarder(this._bluetoothService, this._contactsLookup);

  final BluetoothDeviceService _bluetoothService;
  final List<Contact> Function() _contactsLookup;

  void forwardNewMessages(List<MessageResponse> newMessages) {
    if (_bluetoothService.connectionState.value !=
        BluetoothConnectionState.connected) {
      return;
    }

    for (final message in newMessages) {
      try {
        final formattedMessage = _formatMessageForBluetooth(message);
        _bluetoothService.sendTextMessage(formattedMessage);
        log('MessageForwarder: forwarded message ${message.id}');
      } catch (e) {
        log('MessageForwarder: failed to forward ${message.id}: $e');
      }
    }
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
}
