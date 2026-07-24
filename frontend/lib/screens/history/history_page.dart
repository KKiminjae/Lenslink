import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recent_search.dart';
import '../../services/api_service.dart';
import '../../widgets/lens_bottom_navigation.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  final List<RecentSearch> _searches = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadHistory(refresh: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 180) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) return;

    setState(() {
      if (refresh) {
        _isLoading = true;
        _page = 0;
        _hasMore = true;
        _errorMessage = null;
      } else {
        _isLoadingMore = true;
        _errorMessage = null;
      }
    });

    try {
      final result = await _apiService.getSearchHistory(page: _page);

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _searches
            ..clear()
            ..addAll(result.searches);
        } else {
          _searches.addAll(result.searches);
        }

        _hasMore = !result.last;
        _page += 1;
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = refresh ? "검색 기록을 불러오지 못했어요" : "더 불러오지 못했어요";
      });
    }
  }

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: _goHome,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          "검색 기록",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadHistory(refresh: true),
          color: AppColors.primary,
          child: _HistoryBody(
            searches: _searches,
            isLoading: _isLoading,
            isLoadingMore: _isLoadingMore,
            errorMessage: _errorMessage,
            scrollController: _scrollController,
            onRetry: () => _loadHistory(refresh: true),
            onLoadMoreRetry: () => _loadHistory(),
          ),
        ),
      ),
      bottomNavigationBar: LensBottomNavigation(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) _goHome();
        },
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  final List<RecentSearch> searches;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final VoidCallback onLoadMoreRetry;

  const _HistoryBody({
    required this.searches,
    required this.isLoading,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.scrollController,
    required this.onRetry,
    required this.onLoadMoreRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (errorMessage != null && searches.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 90, 20, 24),
        children: [
          _HistoryMessage(
            icon: Icons.error_outline,
            message: errorMessage!,
            actionText: "다시 시도",
            onAction: onRetry,
          ),
        ],
      );
    }

    if (searches.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 90, 20, 24),
        children: const [
          _HistoryMessage(icon: Icons.history, message: "검색 기록이 없습니다."),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount:
          searches.length + (isLoadingMore || errorMessage != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= searches.length) {
          if (errorMessage != null) {
            return _LoadMoreError(
              message: errorMessage!,
              onRetry: onLoadMoreRetry,
            );
          }

          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        return _HistoryTile(search: searches[index]);
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final RecentSearch search;

  const _HistoryTile({required this.search});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _HistoryImage(imageUrl: search.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  search.brand.isEmpty ? "브랜드 정보 없음" : search.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  search.productName.isEmpty ? "상품명 정보 없음" : search.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(search.createdAt),
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";

    final year = date.year.toString().padLeft(4, "0");
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");

    return "$year.$month.$day";
  }
}

class _HistoryImage extends StatelessWidget {
  final String imageUrl;

  const _HistoryImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.subText,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.network(imageUrl, width: 58, height: 58, fit: BoxFit.cover),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(icon, size: 52, color: AppColors.subText),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadMoreError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.subText, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              "다시 시도",
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
