class RecentSearch {
  final int id;
  final String brand;
  final String productName;
  final String searchKeyword;
  final String imageUrl;
  final DateTime? createdAt;

  const RecentSearch({
    required this.id,
    required this.brand,
    required this.productName,
    required this.searchKeyword,
    required this.imageUrl,
    required this.createdAt,
  });

  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      id: json["id"] ?? 0,
      brand: json["brand"] ?? "",
      productName: json["productName"] ?? "",
      searchKeyword: json["searchKeyword"] ?? "",
      imageUrl: json["imageUrl"] ?? "",
      createdAt: _parseDateTime(json["createdAt"]),
    );
  }

  String get title {
    if (brand.isEmpty && productName.isEmpty) return searchKeyword;
    if (brand.isEmpty) return productName;
    if (productName.isEmpty) return brand;
    return "$brand $productName";
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;

    return DateTime.tryParse(value);
  }
}
