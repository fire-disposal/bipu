import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_user/core/services/im_service.dart';
import 'package:flutter_user/features/assistant/assistant_controller.dart';
import 'package:flutter_user/models/contact/contact.dart';
import '../../common/widgets/app_button.dart';
import '../widgets/voice_assistant_panel.dart';
// status_indicator_widget removed — assistant-driven UI now provides status

enum SendStage { idle, recording, transcribing, sending, sent, error }

class PagerPage extends StatefulWidget {
  const PagerPage({super.key});

  @override
  State<PagerPage> createState() => _PagerPageState();
}

class _PagerPageState extends State<PagerPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final ImService _imService = ImService();
  final AssistantController _assistant = AssistantController();
  StreamSubscription? _assistantEventSub;
  StreamSubscription? _speechSubscription;
  bool _guideStarted = false;

  // Target Selection
  bool _isDirectInput = false;
  Contact? _selectedContact;
  // search controller removed - contacts read directly from ImService

  // Vibration
  bool _isSending = false;

  // Voice assistant
  // Manual send visual state
  bool _manualSent = false;
  SendStage _sendStage = SendStage.idle;
  Timer? _sentResetTimer;

  void _onAssistantPhaseChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Subscribe to assistant events for richer UI syncing
    _assistantEventSub = _assistant.onEvent.listen((event) {
      if (!mounted) return;

      // Sync text if provided
      if (event.text != null && event.text!.isNotEmpty) {
        setState(() {
          _textController.text = event.text!;
        });
      }

      // When assistant reports recipient change, reflect in UI
      final rid = _assistant.currentRecipientId;
      if (rid != null && rid.isNotEmpty) {
        final match = _imService.contacts.firstWhere(
          (c) => c.contactBipupuId == rid,
          orElse: () => Contact(contactBipupuId: rid),
        );
        setState(() {
          if (_imService.contacts.contains(match)) {
            _selectedContact = match;
            _isDirectInput = false;
            _idController.clear();
          } else {
            _selectedContact = null;
            _isDirectInput = true;
            _idController.text = rid;
          }
        });
      }

      // Ensure guideStarted flag if assistant begins a session
      if (event.state == AssistantState.listening) {
        setState(() => _guideStarted = true);
      }
    });

    // waveform controller removed — visual kept minimal

    // contacts are read directly from ImService when needed

    // Initialize voice assistant

    // Ensure assistant init if needed (safe to call repeatedly)
    _assistant.init().catchError((_) {});

    // Listen to granular assistant phase changes for progress UI
    _assistant.phase.addListener(_onAssistantPhaseChanged);

    // Keep assistant recipient in sync with manual id input
    _idController.addListener(() {
      final id = _idController.text.trim();
      if (id.isNotEmpty) {
        try {
          _assistant.setRecipient(id);
        } catch (_) {}
      }
    });

    // Greeting/playback removed; AssistantController can be used if explicit asset available
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    _textController.dispose();
    _idController.dispose();
    // Do not dispose singleton AssistantController here.
    _assistantEventSub?.cancel();
    _assistant.phase.removeListener(_onAssistantPhaseChanged);
    // _waveformController.dispose();
    _sentResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text('pager_title'.tr()),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await _assistant.replay();
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('重放提示已触发')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('重放失败：$e')));
                }
              }
            },
            icon: const Icon(Icons.replay),
            tooltip: '重放',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildSendProgress()),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: _buildStatusIndicator()),
              ],
            ),
          ),
        ),
      ),
      // Floating operator removed — replaced by inline assistant panel
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
                        // Voice assistant panel (prominent, assistant-first flow)
                        const VoiceAssistantPanel(),

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
                                    // Sync recipient when switching modes
                                    if (selection.first) {
                                      final id = _idController.text.trim();
                                      if (id.isNotEmpty) {
                                        try {
                                          _assistant.setRecipient(id);
                                        } catch (_) {}
                                      }
                                    } else {
                                      if (_selectedContact != null) {
                                        try {
                                          _assistant.setRecipient(
                                            _selectedContact!.contactBipupuId,
                                          );
                                        } catch (_) {}
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (_isDirectInput)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _idController,
                                        decoration: InputDecoration(
                                          labelText: 'bipupu_id'.tr(),
                                          prefixIcon: const Icon(Icons.tag),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '语音输入时请直接说数字ID',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Autocomplete<Contact>(
                                        optionsBuilder:
                                            (
                                              TextEditingValue textEditingValue,
                                            ) {
                                              if (textEditingValue
                                                  .text
                                                  .isEmpty) {
                                                return _imService.contacts;
                                              }
                                              return _imService.contacts.where((
                                                contact,
                                              ) {
                                                final bipupuId = contact
                                                    .contactBipupuId
                                                    .toLowerCase();
                                                final remark =
                                                    contact.remark
                                                        ?.toLowerCase() ??
                                                    '';
                                                final query = textEditingValue
                                                    .text
                                                    .toLowerCase();
                                                return bipupuId.contains(
                                                      query,
                                                    ) ||
                                                    remark.contains(query);
                                              }).toList();
                                            },
                                        displayStringForOption:
                                            (Contact contact) =>
                                                contact.remark ??
                                                contact.contactBipupuId,
                                        onSelected: (Contact contact) {
                                          setState(
                                            () => _selectedContact = contact,
                                          );
                                          try {
                                            _assistant.setRecipient(
                                              contact.contactBipupuId,
                                            );
                                          } catch (_) {}
                                        },
                                        fieldViewBuilder:
                                            (
                                              context,
                                              textEditingController,
                                              focusNode,
                                              onFieldSubmitted,
                                            ) {
                                              return TextField(
                                                controller:
                                                    textEditingController,
                                                focusNode: focusNode,
                                                decoration: InputDecoration(
                                                  labelText: 'search_contact'
                                                      .tr(),
                                                  prefixIcon: const Icon(
                                                    Icons.search,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                        optionsViewBuilder:
                                            (context, onSelected, options) {
                                              return Align(
                                                alignment: Alignment.topLeft,
                                                child: Material(
                                                  elevation: 4,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxHeight: 200,
                                                        ),
                                                    width:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width -
                                                        64,
                                                    child: ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      itemCount: options.length,
                                                      itemBuilder: (context, index) {
                                                        final contact = options
                                                            .elementAt(index);
                                                        return ListTile(
                                                          leading: CircleAvatar(
                                                            child: Text(
                                                              contact
                                                                  .contactBipupuId
                                                                  .substring(
                                                                    0,
                                                                    1,
                                                                  ),
                                                            ),
                                                          ),
                                                          title: Text(
                                                            contact.remark ??
                                                                contact
                                                                    .contactBipupuId,
                                                          ),
                                                          subtitle: Text(
                                                            contact
                                                                .contactBipupuId,
                                                          ),
                                                          onTap: () =>
                                                              onSelected(
                                                                contact,
                                                              ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                      if (_selectedContact != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Chip(
                                            avatar: CircleAvatar(
                                              child: Text(
                                                _selectedContact!
                                                    .contactBipupuId
                                                    .substring(0, 1),
                                              ),
                                            ),
                                            label: Text(
                                              _selectedContact!.remark ??
                                                  _selectedContact!
                                                      .contactBipupuId,
                                            ),
                                            onDeleted: () {
                                              setState(
                                                () => _selectedContact = null,
                                              );
                                              try {
                                                _assistant.setRecipient('');
                                              } catch (_) {}
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Message Input Card
                        // Assistant guidance / stage hints
                        Builder(
                          builder: (context) {
                            final aState = _assistant.state.value;
                            if (aState == AssistantState.listening) {
                              return Card(
                                color: colorScheme.surfaceVariant.withOpacity(
                                  0.06,
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.mic, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'assistant_listening_hint'.tr(),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          try {
                                            await _assistant.stopListening();
                                          } catch (_) {}
                                        },
                                        child: Text('停止'.tr()),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (aState == AssistantState.thinking) {
                              return Card(
                                color: colorScheme.surfaceVariant.withOpacity(
                                  0.04,
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'assistant_processing_hint'.tr(),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (aState == AssistantState.speaking) {
                              return Card(
                                color: colorScheme.primaryContainer.withOpacity(
                                  0.06,
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.volume_up,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'assistant_reading_hint'.tr(),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          try {
                                            await _assistant.replay();
                                          } catch (_) {}
                                        },
                                        icon: Icon(
                                          Icons.replay,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              // idle
                              if (!_guideStarted) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'assistant_start_prompt'.tr(),
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            setState(
                                              () => _guideStarted = true,
                                            );
                                            try {
                                              await _assistant.speakScript(
                                                'greeting',
                                              );
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'assistant_start_failed'
                                                          .tr(
                                                            args: [
                                                              e.toString(),
                                                            ],
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.play_arrow),
                                          label: Text('开始引导'.tr()),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // guide started but idle -> show small hint with replay
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      try {
                                        await _assistant.speakScript(
                                          'greeting',
                                        );
                                      } catch (_) {}
                                    },
                                    icon: Icon(
                                      Icons.replay,
                                      color: colorScheme.primary,
                                    ),
                                    label: Text(
                                      '重放引导'.tr(),
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
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
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            try {
                                              if (_assistant.state.value ==
                                                  AssistantState.listening) {
                                                await _assistant
                                                    .stopListening();
                                              } else {
                                                await _assistant
                                                    .startListening();
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'assistant_start_failed'
                                                          .tr(
                                                            args: [
                                                              e.toString(),
                                                            ],
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: Icon(
                                            Icons.mic,
                                            color: colorScheme.primary,
                                          ),
                                          tooltip: '语音输入提示',
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _textController.clear();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('消息已清空'),
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.clear,
                                            color: colorScheme.error,
                                          ),
                                          tooltip: '清空消息',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outline.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: TextField(
                                          controller: _textController,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            hintText: '请输入消息内容，或使用语音输入...'.tr(),
                                            border: InputBorder.none,
                                            filled: false,
                                          ),
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceVariant
                                              .withOpacity(0.3),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              size: 16,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '可随时手动编辑消息内容',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // (vibration selector removed)
                      ],
                    ),
                  ),
                ),

                // Send Button
                // compact spacing where waveform used to be
                const SizedBox(height: 8),

                Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_assistant.state.value == AssistantState.speaking)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(
                                0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.volume_up,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'assistant_reading_hint'.tr(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await _assistant.replay();
                                    } catch (_) {}
                                  },
                                  icon: Icon(
                                    Icons.replay,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: _isSending
                                  ? 'sending'.tr()
                                  : 'send_pager'.tr(),
                              onPressed: _isSending ? null : _sendMessage,
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              height: 48,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // contact list filtering removed — UI reads contacts on demand from ImService

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

    setState(() {
      _isSending = true;
      _sendStage = SendStage.sending;
      _manualSent = false;
      _sentResetTimer?.cancel();
    });

    try {
      await _imService.messageApi.sendMessage(
        receiverId: targetId,
        content: text,
        msgType: 'device', // Pager means 'device' type likely
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('pager_sent'.tr())));
        _textController.clear();
        setState(() {
          _manualSent = true;
          _sendStage = SendStage.sent;
        });
        _sentResetTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _manualSent = false;
              _sendStage = SendStage.idle;
            });
          }
        });
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

  Widget _buildSendProgress() {
    // Determine stage index based on assistant granular phase or manual send state
    int index = 0;
    final assistantPhase = _assistant.currentPhase;
    if (assistantPhase == AssistantPhase.recording) {
      index = 0;
      _sendStage = SendStage.recording;
    } else if (assistantPhase == AssistantPhase.transcribing) {
      index = 1;
      _sendStage = SendStage.transcribing;
    } else if (assistantPhase == AssistantPhase.sending) {
      index = 2;
      _sendStage = SendStage.sending;
    } else if (assistantPhase == AssistantPhase.sent) {
      index = 3;
      _sendStage = SendStage.sent;
    } else {
      // fallback to manual send status
      if (_manualSent) {
        index = 3;
      } else if (_isSending)
        index = 2;
      else
        index = 0;
    }

    final labels = ['录音', '转写', '发送', '已发送'];
    final steps = labels.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(steps, (i) {
            final done = i <= index;
            final active = i == index;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: done ? Colors.green : Colors.grey.shade400,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.radio_button_unchecked,
                      size: 16,
                      color: done ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : (done ? Colors.green.shade700 : Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (index / (steps - 1)).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    final phase = _assistant.currentPhase;
    Color color;
    String label;
    switch (phase) {
      case AssistantPhase.recording:
        color = Colors.orange;
        label = '录音中';
        break;
      case AssistantPhase.transcribing:
        color = Colors.blue;
        label = '转写中';
        break;
      case AssistantPhase.sending:
        color = Colors.teal;
        label = '发送中';
        break;
      case AssistantPhase.sent:
        color = Colors.green;
        label = '已发送';
        break;
      case AssistantPhase.error:
        color = Colors.red;
        label = '错误';
        break;
      default:
        color = Colors.grey;
        label = '空闲';
    }

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
