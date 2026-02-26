class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List<dynamic>).map(fromJsonT).toList(),
      total: json['total'] is int
          ? json['total'] as int
          : int.parse(json['total'].toString()),
      page: json['page'] is int
          ? json['page'] as int
          : int.parse(json['page'].toString()),
      size: json['size'] is int
          ? json['size'] as int
          : int.parse(json['size'].toString()),
      pages: json['pages'] is int
          ? json['pages'] as int
          : int.parse(json['pages'].toString()),
    );
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => {
    'items': items.map(toJsonT).toList(),
    'total': total,
    'page': page,
    'size': size,
    'pages': pages,
  };
}
