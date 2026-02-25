import 'package:json_annotation/json_annotation.dart';
import 'message_model.dart';

part 'favorite_model.g.dart';

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
  final int messageId;
  final String userId;
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
  String toString() =>
      'FavoriteResponse(id: $id, messageId: $messageId, userId: $userId, note: $note, createdAt: $createdAt)';
}

/// 收藏列表响应
@JsonSerializable()
class FavoriteListResponse {
  final List<FavoriteResponse> items;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  FavoriteListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory FavoriteListResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoriteListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FavoriteListResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteListResponse &&
          runtimeType == other.runtimeType &&
          items == other.items &&
          total == other.total &&
          page == other.page &&
          pageSize == other.pageSize &&
          totalPages == other.totalPages;

  @override
  int get hashCode =>
      items.hashCode ^
      total.hashCode ^
      page.hashCode ^
      pageSize.hashCode ^
      totalPages.hashCode;

  @override
  String toString() =>
      'FavoriteListResponse(items: $items, total: $total, page: $page, pageSize: $pageSize, totalPages: $totalPages)';
}

/// 带消息详情的收藏响应
@JsonSerializable()
class FavoriteWithMessageResponse {
  final FavoriteResponse favorite;
  final MessageResponse message;

  FavoriteWithMessageResponse({required this.favorite, required this.message});

  factory FavoriteWithMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoriteWithMessageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FavoriteWithMessageResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteWithMessageResponse &&
          runtimeType == other.runtimeType &&
          favorite == other.favorite &&
          message == other.message;

  @override
  int get hashCode => favorite.hashCode ^ message.hashCode;

  @override
  String toString() =>
      'FavoriteWithMessageResponse(favorite: $favorite, message: $message)';
}

/// 收藏统计
@JsonSerializable()
class FavoriteStats {
  final int total;
  final int today;
  final int thisWeek;
  final int thisMonth;

  FavoriteStats({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });

  factory FavoriteStats.fromJson(Map<String, dynamic> json) =>
      _$FavoriteStatsFromJson(json);
  Map<String, dynamic> toJson() => _$FavoriteStatsToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteStats &&
          runtimeType == other.runtimeType &&
          total == other.total &&
          today == other.today &&
          thisWeek == other.thisWeek &&
          thisMonth == other.thisMonth;

  @override
  int get hashCode =>
      total.hashCode ^ today.hashCode ^ thisWeek.hashCode ^ thisMonth.hashCode;

  @override
  String toString() =>
      'FavoriteStats(total: $total, today: $today, thisWeek: $thisWeek, thisMonth: $thisMonth)';
}
