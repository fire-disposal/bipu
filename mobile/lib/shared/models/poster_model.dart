import 'package:json_annotation/json_annotation.dart';
import '../../core/config/app_config.dart';

part 'poster_model.g.dart';

/// 海报模型 - 用于前端轮播展示
@JsonSerializable()
class PosterResponse {
  /// 海报ID
  final int id;

  /// 海报标题
  final String title;

  /// 点击跳转链接
  @JsonKey(name: 'link_url')
  final String? linkUrl;

  /// 显示顺序，数字越小越靠前
  @JsonKey(name: 'display_order')
  final int displayOrder;

  /// 是否激活
  @JsonKey(name: 'is_active')
  final bool isActive;

  /// 创建时间
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// 更新时间
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// 海报图片URL - 通过API获取（相对路径）
  String get imageUrl => '/api/posters/$id/image';

  /// 获取完整的海报图片URL
  String get fullImageUrl => '${AppConfig.baseUrl}$imageUrl';

  PosterResponse({
    required this.id,
    required this.title,
    this.linkUrl,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PosterResponse.fromJson(Map<String, dynamic> json) =>
      _$PosterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PosterResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosterResponse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          linkUrl == other.linkUrl &&
          displayOrder == other.displayOrder &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      linkUrl.hashCode ^
      displayOrder.hashCode ^
      isActive.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'PosterResponse(id: $id, title: $title, linkUrl: $linkUrl, displayOrder: $displayOrder, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// 海报列表响应
@JsonSerializable()
class PosterListResponse {
  final List<PosterResponse> posters;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;

  PosterListResponse({
    required this.posters,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PosterListResponse.fromJson(Map<String, dynamic> json) =>
      _$PosterListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PosterListResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosterListResponse &&
          runtimeType == other.runtimeType &&
          posters == other.posters &&
          total == other.total &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode =>
      posters.hashCode ^ total.hashCode ^ page.hashCode ^ pageSize.hashCode;

  @override
  String toString() {
    return 'PosterListResponse(posters: $posters, total: $total, page: $page, pageSize: $pageSize)';
  }
}

/// 海报图片响应（包含base64编码）
@JsonSerializable()
class PosterImageResponse {
  @JsonKey(name: 'poster_id')
  final int posterId;
  final String title;
  @JsonKey(name: 'image_data')
  final String imageData; // base64编码的图片数据
  @JsonKey(name: 'mime_type')
  final String mimeType;

  PosterImageResponse({
    required this.posterId,
    required this.title,
    required this.imageData,
    required this.mimeType,
  });

  factory PosterImageResponse.fromJson(Map<String, dynamic> json) =>
      _$PosterImageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PosterImageResponseToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosterImageResponse &&
          runtimeType == other.runtimeType &&
          posterId == other.posterId &&
          title == other.title &&
          imageData == other.imageData &&
          mimeType == other.mimeType;

  @override
  int get hashCode =>
      posterId.hashCode ^
      title.hashCode ^
      imageData.hashCode ^
      mimeType.hashCode;

  @override
  String toString() {
    return 'PosterImageResponse(posterId: $posterId, title: $title, mimeType: $mimeType)';
  }
}
