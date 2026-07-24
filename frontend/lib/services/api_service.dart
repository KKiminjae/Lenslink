import 'dart:io';

import 'package:dio/dio.dart';

import '../models/recent_search.dart';
import '../models/search_response.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:8080",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  Future<SearchResponse> analyzeImage(File image) async {
    final formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(
        image.path,
        filename: image.path.split("/").last,
      ),
    });

    final response = await _dio.post("/api/searches/analyze", data: formData);

    return SearchResponse.fromJson(response.data);
  }

  Future<List<RecentSearch>> getRecentSearches() async {
    final response = await _dio.get("/api/searches/history/recent");
    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => RecentSearch.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<SearchHistoryPage> getSearchHistory({
    required int page,
    int size = 30,
  }) async {
    final response = await _dio.get(
      "/api/searches/history",
      queryParameters: {"page": page, "size": size},
    );
    final data = response.data;

    if (data is! Map) {
      return const SearchHistoryPage(searches: [], last: true);
    }

    final content = data["content"];

    return SearchHistoryPage(
      searches: content is List
          ? content
                .whereType<Map>()
                .map(
                  (item) =>
                      RecentSearch.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : [],
      last: data["last"] ?? true,
    );
  }
}

class SearchHistoryPage {
  final List<RecentSearch> searches;
  final bool last;

  const SearchHistoryPage({required this.searches, required this.last});
}
