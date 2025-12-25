import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openapi/openapi.dart';
import '../../core/injection/service_locator.dart';

class MessageManagementState {
  final List<MessageResponse> messages;
  final bool loading;
  final String? error;

  const MessageManagementState({
    this.messages = const [],
    this.loading = false,
    this.error,
  });

  MessageManagementState copyWith({
    List<MessageResponse>? messages,
    bool? loading,
    String? error,
  }) {
    return MessageManagementState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class MessageManagementCubit extends Cubit<MessageManagementState> {
  final MessagesApi _api;

  MessageManagementCubit({MessagesApi? api})
    : _api = api ?? ServiceLocatorConfig.get<Openapi>().getMessagesApi(),
      super(const MessageManagementState());

  Future<void> loadMessages() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final res = await _api.adminGetAllMessagesApiMessagesAdminAllGet();
      final messages = (res.data as List<MessageResponse>? ?? []);
      emit(state.copyWith(messages: messages, loading: false));
    } catch (e) {
      emit(state.copyWith(error: '消息获取失败: $e', loading: false));
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _api.adminDeleteMessageApiMessagesAdminMessageIdDelete(
        messageId: messageId,
      );
      await loadMessages();
    } catch (e) {
      emit(state.copyWith(error: '删除失败: $e'));
    }
  }
}
