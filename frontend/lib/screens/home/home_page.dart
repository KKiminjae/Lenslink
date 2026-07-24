import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recent_search.dart';
import '../../services/api_service.dart';
import '../../services/image_picker_service.dart';
import '../../widgets/lens_bottom_navigation.dart';
import '../analysis/analysis_page.dart';
import '../history/history_page.dart';

class HomePage extends StatefulWidget {
  final bool loadRecentSearches;

  const HomePage({super.key, this.loadRecentSearches = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  List<RecentSearch> _recentSearches = [];
  bool _isHistoryLoading = false;
  String? _historyErrorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.loadRecentSearches) {
      _loadRecentSearches();
    }
  }

  Future<void> _loadRecentSearches() async {
    setState(() {
      _isHistoryLoading = true;
      _historyErrorMessage = null;
    });

    try {
      final searches = await _apiService.getRecentSearches();
      if (!mounted) return;

      setState(() {
        _recentSearches = searches;
        _isHistoryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _historyErrorMessage = "최근 검색을 불러오지 못했어요";
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePickerService.pickImage();

    if (image == null || !mounted) return;

    await _goToAnalysis(image);
  }

  Future<void> _goToAnalysis(File image) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalysisPage(image: image)),
    );

    if (!mounted || !widget.loadRecentSearches) return;

    await _loadRecentSearches();
  }

  void _goToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HomeHeader(),
              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              const SizedBox(height: 34),
              const Center(
                child: Text(
                  "사진 한 장으로\n원하는 상품을 찾아보세요",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    height: 1.45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _UploadBox(onTap: _pickImage),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    "최근 검색",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _goToHistory,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(46, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "더보기 >",
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _RecentSearchSection(
                searches: _recentSearches,
                isLoading: _isHistoryLoading,
                errorMessage: _historyErrorMessage,
                onRetry: _loadRecentSearches,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: LensBottomNavigation(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) _goToHistory();
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          "LensLink",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          width: double.infinity,
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/upload_cloud.png",
                width: 76,
                height: 76,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              const Text(
                "이미지를 업로드하거나\n여기에 드래그하세요",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "JPG, PNG, WEBP (최대 10MB)",
                style: TextStyle(color: AppColors.subText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSearchSection extends StatelessWidget {
  final List<RecentSearch> searches;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _RecentSearchSection({
    required this.searches,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
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

    if (errorMessage != null) {
      return _RecentSearchMessage(
        message: errorMessage!,
        actionText: "다시 시도",
        onAction: onRetry,
      );
    }

    if (searches.isEmpty) {
      return const _RecentSearchMessage(message: "최근 검색 내역이 없어요");
    }

    return Column(
      children: searches
          .map((search) => _RecentSearchTile(search: search))
          .toList(),
    );
  }
}

class _RecentSearchMessage extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _RecentSearchMessage({
    required this.message,
    this.actionText,
    this.onAction,
  });

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
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionText!,
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  final RecentSearch search;

  const _RecentSearchTile({required this.search});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: search.imageUrl.isEmpty
                ? const Icon(Icons.history, color: Colors.black, size: 22)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(search.imageUrl, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  search.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(search.createdAt),
                  style: const TextStyle(color: Colors.black, fontSize: 11),
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

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final radius = Radius.circular(8);
    final rect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + 8;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
