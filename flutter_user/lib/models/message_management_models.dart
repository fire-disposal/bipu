class MessageStatsRequest {
  final DateTime? dateFrom;
  final DateTime? dateTo;

  MessageStatsRequest({this.dateFrom, this.dateTo});

  Map<String, dynamic> toJson() {
    return {
      if (dateFrom != null) 'date_from': dateFrom!.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo!.toIso8601String(),
    };
  }
}

class MessageStatsResponse {
  final int totalSent;
  final int totalReceived;
  final int totalFavorites;
  final Map<String, int> byType;
  final Map<String, int> byDate;

  MessageStatsResponse({
    required this.totalSent,
    required this.totalReceived,
    required this.totalFavorites,
    required this.byType,
    required this.byDate,
  });

  factory MessageStatsResponse.fromJson(Map<String, dynamic> json) {
    return MessageStatsResponse(
      totalSent: json['total_sent'] as int,
      totalReceived: json['total_received'] as int,
      totalFavorites: json['total_favorites'] as int,
      byType: Map<String, int>.from(json['by_type'] as Map),
      byDate: Map<String, int>.from(json['by_date'] as Map),
    );
  }
}

class ExportMessagesRequest {
  final String? messageType; // 'sent' or 'received' or null
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool includeContent;
  final bool includeMetadata;
  final String format; // 'json', 'csv', etc

  ExportMessagesRequest({
    this.messageType,
    this.dateFrom,
    this.dateTo,
    this.includeContent = true,
    this.includeMetadata = true,
    this.format = 'json',
  });

  Map<String, dynamic> toJson() {
    return {
      if (messageType != null) 'message_type': messageType,
      if (dateFrom != null) 'date_from': dateFrom!.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo!.toIso8601String(),
      'include_content': includeContent,
      'include_metadata': includeMetadata,
      'format': format,
    };
  }
}

class ExportMessagesResponse {
  final String downloadUrl;
  final int fileSize;
  final int recordCount;
  final DateTime expiresAt;

  ExportMessagesResponse({
    required this.downloadUrl,
    required this.fileSize,
    required this.recordCount,
    required this.expiresAt,
  });

  factory ExportMessagesResponse.fromJson(Map<String, dynamic> json) {
    return ExportMessagesResponse(
      downloadUrl: json['download_url'] as String,
      fileSize: json['file_size'] as int,
      recordCount: json['record_count'] as int,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}
