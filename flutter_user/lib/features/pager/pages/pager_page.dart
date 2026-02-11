import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_user/core/services/im_service.dart';
import 'package:flutter_user/core/services/speech_recognition_service.dart';
import 'package:flutter_user/core/services/voice_guide_service.dart';
import 'package:flutter_user/models/contact/contact.dart';
import '../../common/widgets/app_button.dart';
import '../widgets/floating_operator_widget.dart';

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final ImService _imService = ImService();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final VoiceGuideService _voiceService = VoiceGuideService(); // Add service
  StreamSubscription? _speechSubscription;

  // Target Selection
  bool _isDirectInput = false;
  Contact? _selectedContact;

  // Vibration
  String _selectedVibration = 'default';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _speechSubscription = _speechService.onResult.listen((text) {
      if (mounted) {
        _textController.text = text;
      }
    });

    // Play greeting with cooldown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _voiceService.playVoice(
        'pager_welcome',
        cooldown: const Duration(minutes: 5),
        interrupt: false,
      );
    });
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    _textController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('pager_title'.tr()),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      floatingActionButton: FloatingOperatorWidget(
        onPressed: () {
          _voiceService.playVoice('help_menu', interrupt: true);
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: Text('operator_assistance'.tr()),
              content: Text('pager_help_text'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text('got_it'.tr()),
                ),
              ],
            ),
          );
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Target Selector Card
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_search,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'select_recipient'.tr(),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SegmentedButton<bool>(
                                  segments: [
                                    ButtonSegment(
                                      value: false,
                                      label: Text('contacts_tab'.tr()),
                                      icon: const Icon(Icons.contacts),
                                    ),
                                    ButtonSegment(
                                      value: true,
                                      label: Text('manual_input_tab'.tr()),
                                      icon: const Icon(Icons.edit),
                                    ),
                                  ],
                                  selected: {_isDirectInput},
                                  onSelectionChanged: (selection) {
                                    setState(
                                      () => _isDirectInput = selection.first,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (_isDirectInput)
                                  TextField(
                                    controller: _idController,
                                    decoration: InputDecoration(
                                      labelText: 'bipupu_id'.tr(),
                                      prefixIcon: const Icon(Icons.tag),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  )
                                else
                                  DropdownButtonFormField<Contact>(
                                    decoration: InputDecoration(
                                      labelText: 'select_contact'.tr(),
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    initialValue: _selectedContact,
                                    items: _imService.contacts
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              c.remark ?? c.contactBipupuId,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (c) =>
                                        setState(() => _selectedContact = c),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Message Input Card
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.message,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'message_content'.tr(),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        // Voice input hint
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('长按底部麦克风按钮开始语音输入'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.mic,
                                        color: colorScheme.primary,
                                      ),
                                      tooltip: '语音输入提示',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _textController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'enter_message_hint'.tr(),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Vibration Selector Card
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.vibration,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'vibration_mode'.tr(),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surface,
                                  ),
                                  initialValue: _selectedVibration,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'default',
                                      child: Text('default_vibration'.tr()),
                                    ),
                                    DropdownMenuItem(
                                      value: 'sos',
                                      child: Text('sos_mode'.tr()),
                                    ),
                                    DropdownMenuItem(
                                      value: 'heartbeat',
                                      child: Text('heartbeat_mode'.tr()),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedVibration = v!),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Send Button
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: AppButton(
                    text: _isSending ? 'sending'.tr() : 'send_pager'.tr(),
                    onPressed: _isSending ? null : _sendMessage,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    height: 56,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('enter_message'.tr())));
      return;
    }

    String? targetId;
    if (_isDirectInput) {
      targetId = _idController.text.trim();
    } else {
      targetId = _selectedContact?.contactBipupuId;
    }

    if (targetId == null || targetId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('select_recipient_error'.tr())));
      return;
    }

    setState(() => _isSending = true);

    try {
      await _imService.messageApi.sendMessage(
        receiverId: targetId,
        content: text,
        msgType: 'device', // Pager means 'device' type likely
        pattern: {'vibration': _selectedVibration},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('pager_sent'.tr())));
        _textController.clear();
        _speechService.clearBuffer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('send_failed'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
