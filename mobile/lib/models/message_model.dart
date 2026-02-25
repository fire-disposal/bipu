import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

/// 消息创建请求
@JsonSerializable()
class MessageCreate {
  @JsonKey(name: 'receiver_id')
  final String receiverId;
  final String content;
  @JsonKey(name: 'message_type')
  final String messageType;
  final Map<String, dynamic>? pattern;
  final List<int>? waveform;

  MessageCreate({
    required this.receiverId,
    required this.content,
    this.messageType = 'NORMAL',
    this.pattern,
    this.waveform,
  });

  factory MessageCreate.fromJson(Map<String, dynamic> json) =>
      _$MessageCreateFromJson(json);

  Map<String, dynamic> toJson() => _$MessageCreateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageCreate &&
          runtimeType == other.runtimeType &&
          receiverId == other.receiverId &&
          content == other.content &&
          messageType == other.messageType &&
          pattern == other.pattern &&
          waveform == other.waveform;

  @override
  int get hashCode =>
      receiverId.hashCode ^
      content.hashCode ^
      messageType.hashCode ^
      pattern.hashCode ^
      waveform.hashCode;

  @override
  String toString() {
    return 'MessageCreate(receiverId: $receiverId, content: $content, messageType: $messageType, pattern: $pattern, waveform: $waveform)';
  }
}

/// 消息响应
@JsonSerializable()
class MessageResponse {
  final int id;
  @JsonKey(name: 'sender_bipupu_id')
  final String senderBipupuId;
  @JsonKey(name: 'receiver_bipupu_id')
  final String receiverBipupuId;
  final String content;
  @JsonKey(name: 'message_type')
  final String messageType;
  final Map<String, dynamic>? pattern;
  final List<int>? waveform;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  MessageResponse({
    required this.id,
    required this.senderBipupuId,
    required this.receiverBipupuId,
    required this.content,
    required this.messageType,
    this.pattern,
    this.waveform,
    required this.createdAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageResponse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          senderBipupuId == other.senderBipupuId &&
          receiverBipupuId == other.receiverBipupuId &&
          content == other.content &&
          messageType == other.messageType &&
          pattern == other.pattern &&
          waveform == other.waveform &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      senderBipupuId.hashCode ^
      receiverBipupuId.hashCode ^
      content.hashCode ^
      messageType.hashCode ^
      pattern.hashCode ^
      waveform.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'MessageResponse(id: $id, senderBipupuId: $senderBipupuId, receiverBipupuId: $receiverBipupuId, content: $content, messageType: $messageType, pattern: $pattern, waveform: $waveform, createdAt: $createdAt)';
  }
}

/// 消息列表响应
@JsonSerializable()
class MessageListResponse {
  final List<MessageResponse> messages;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;

  MessageListResponse({
    required this.messages,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory MessageListResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageListResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageListResponse &&
          runtimeType == other.runtimeType &&
          messages == other.messages &&
          total == other.total &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode =>
      messages.hashCode ^ total.hashCode ^ page.hashCode ^ pageSize.hashCode;

  @override
  String toString() {
    return 'MessageListResponse(messages: $messages, total: $total, page: $page, pageSize: $pageSize)';
  }
}

/// 收藏创建请求
@JsonSerializable()
class FavoriteCreate {
  final String? note;

  FavoriteCreate({this.note});

  factory FavoriteCreate.fromJson(Map<String, dynamic> json) =>
      _$FavoriteCreateFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteCreateToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteCreate &&
          runtimeType == other.runtimeType &&
          note == other.note;

  @override
  int get hashCode => note.hashCode;

  @override
  String toString() => 'FavoriteCreate(note: $note)';
}

/// 收藏响应
@JsonSerializable()
class FavoriteResponse {
  final int id;
  @JsonKey(name: 'message_id')
  final int messageId;
  @JsonKey(name: 'user_id')
  final int userId;
  final String? note;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  FavoriteResponse({
    required this.id,
    required this.messageId,
    required this.userId,
    this.note,
    required this.createdAt,
  });

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoriteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteResponse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          messageId == other.messageId &&
          userId == other.userId &&
          note == other.note &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      messageId.hashCode ^
      userId.hashCode ^
      note.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'FavoriteResponse(id: $id, messageId: $messageId, userId: $userId, note: $note, createdAt: $createdAt)';
  }
}

/// 收藏列表响应
@JsonSerializable()
class FavoriteListResponse {
  final List<FavoriteResponse> favorites;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;

  FavoriteListResponse({
    required this.favorites,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory FavoriteListResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoriteListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteListResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteListResponse &&
          runtimeType == other.runtimeType &&
          favorites == other.favorites &&
          total == other.total &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode =>
      favorites.hashCode ^ total.hashCode ^ page.hashCode ^ pageSize.hashCode;

  @override
  String toString() {
    return 'FavoriteListResponse(favorites: $favorites, total: $total, page: $page, pageSize: $pageSize)';
  }
}
