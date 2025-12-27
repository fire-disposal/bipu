class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int size;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
    );
  }
}
