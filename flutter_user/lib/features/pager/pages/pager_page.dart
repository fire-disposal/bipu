import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_user/core/services/im_service.dart';
// VoiceGuideService removed — use AssistantController where needed
import 'package:flutter_user/features/assistant/assistant_controller.dart';
import 'package:flutter_user/models/contact/contact.dart';
import '../../common/widgets/app_button.dart';
import '../widgets/voice_assistant_panel.dart';
// waveform visual removed — keep UI lean and avoid floating overlays
import '../widgets/status_indicator_widget.dart';

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
  StreamSubscription? _speechSubscription;

  // Target Selection
  bool _isDirectInput = false;
  Contact? _selectedContact;
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();

  // Vibration
  bool _isSending = false;

  // Voice assistant
  bool _isVoiceAssistantActive = false;
  // Manual send visual state
  bool _manualSent = false;
  SendStage _sendStage = SendStage.idle;
  Timer? _sentResetTimer;

  @override
  void initState() {
    super.initState();
    _speechSubscription = _assistant.onResult.listen((text) {
      if (mounted) {
        _textController.text = text;
      }
    });

    // waveform controller removed — visual kept minimal

    // Initialize filtered contacts
    _filteredContacts = _imService.contacts;

    // Listen to contacts changes
    _imService.addListener(_onContactsChanged);

    // Initialize voice assistant
    _assistant.addListener(() {
      if (mounted) {
        setState(() {
          _isVoiceAssistantActive =
              _assistant.state.value != AssistantState.idle;
        });
      }
    });

    // Greeting/playback removed; AssistantController can be used if explicit asset available
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    _textController.dispose();
    _idController.dispose();
    _searchController.dispose();
    _imService.removeListener(_onContactsChanged);
    _assistant.dispose();
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildSendProgress()),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: StatusIndicatorWidget()),
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
                                          onPressed: () {
                                            // Voice input hint
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '长按底部麦克风按钮或点击语音助手开始语音输入',
                                                ),
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
                // Voice assistant panel
                const VoiceAssistantPanel(),

                // Compact controls section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Replay button
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _assistant.replay();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('重放提示已触发')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('重放失败：$e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text('重来', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),

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

  void _onContactsChanged() {
    setState(() {
      _filterContacts(_searchController.text);
    });
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      _filteredContacts = _imService.contacts;
    } else {
      _filteredContacts = _imService.contacts.where((contact) {
        final bipupuId = contact.contactBipupuId.toLowerCase();
        final remark = contact.remark?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return bipupuId.contains(searchQuery) || remark.contains(searchQuery);
      }).toList();
    }
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
    // Determine stage index based on assistant state or manual send state
    int index = 0;
    final assistantState = _assistant.state.value;
    if (assistantState == AssistantState.listening) {
      index = 0;
      _sendStage = SendStage.recording;
    } else if (assistantState == AssistantState.thinking) {
      index = 1;
      _sendStage = SendStage.transcribing;
    } else if (assistantState == AssistantState.speaking) {
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
}
