// Fallback/Default operators
import 'package:flutter/material.dart';

class VirtualOperator {
  final String id;
  final String name;
  final String description;
  final String avatarAssetPath;
  final String voicePackageId;
  final Color themeColor;

  const VirtualOperator({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarAssetPath,
    required this.voicePackageId,
    this.themeColor = const Color(0xFF2196F3),
  });

  // Placeholder for equality check if needed
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirtualOperator &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const List<VirtualOperator> defaultOperators = [
  VirtualOperator(
    id: 'op_karen',
    name: 'Karen',
    description: 'Professional and calm operator.',
    avatarAssetPath: 'assets/images/operators/karen.png',
    voicePackageId: 'voice_karen',
    themeColor: Colors.blueAccent,
  ),
  VirtualOperator(
    id: 'op_luna',
    name: 'Luna',
    description: 'Energetic and friendly assistant.',
    avatarAssetPath: 'assets/images/operators/luna.png',
    voicePackageId: 'voice_luna',
    themeColor: Colors.pinkAccent,
  ),
  VirtualOperator(
    id: 'op_system',
    name: 'System',
    description: 'Minimalistic system interface.',
    avatarAssetPath: 'assets/images/operators/system.png',
    voicePackageId: 'voice_system',
    themeColor: Colors.grey,
  ),
];
