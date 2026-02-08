import 'dart:convert';
import 'dart:typed_data';

enum BleCommandType {
  message(0x01);

  final int value;
  const BleCommandType(this.value);
}

enum VibrationType {
  none(0x00, 'None'),
  standard(0x01, 'Standard'),
  urgent(0x02, 'Urgent'),
  gentle(0x03, 'Gentle'),
  notification(0x04, 'Notification');

  final int value;
  final String label;
  const VibrationType(this.value, this.label);
}

enum ScreenEffect {
  none(0x00, 'None'),
  scroll(0x01, 'Scroll'),
  blink(0x02, 'Blink'),
  breathing(0x03, 'Breathing');

  final int value;
  final String label;
  const ScreenEffect(this.value, this.label);
}

class BleProtocol {
  static const int protocolVersion = 0x01;
  static int _sequenceNumber = 0;

  static Uint8List createPacket({
    VibrationType vibration = VibrationType.none,
    ScreenEffect screenEffect = ScreenEffect.none,
    String text = '',
  }) {
    final buffer = BytesBuilder();

    // 1. Protocol Version (1 byte)
    buffer.addByte(protocolVersion);

    // 2. Command Type (1 byte)
    buffer.addByte(BleCommandType.message.value);

    // 3. Sequence Number (2 bytes, Little Endian)
    _sequenceNumber = (_sequenceNumber + 1) % 65536;
    buffer.addByte(_sequenceNumber & 0xFF);
    buffer.addByte((_sequenceNumber >> 8) & 0xFF);

    // 4. Vibration Mode (1 byte)
    buffer.addByte(vibration.value);

    // 5. Vibration Strength (1 byte) - Always standard
    buffer.addByte(1);

    // 6. Text Length (1 byte) & 7. Text Content
    final textBytes = utf8.encode(text);
    // Limit text to 64 bytes
    final validTextBytes = textBytes.take(64).toList();
    buffer.addByte(validTextBytes.length);
    buffer.add(validTextBytes);

    // 8. Screen Effect (1 byte)
    buffer.addByte(screenEffect.value);

    // 9. Checksum (1 byte)
    // Sum of all previous bytes & 0xFF
    int checksum = 0;
    for (final byte in buffer.toBytes()) {
      checksum += byte;
    }
    buffer.addByte(checksum & 0xFF);

    return buffer.toBytes();
  }
}
