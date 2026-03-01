import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cafe_providers.dart';
import '../../core/widgets/cafe_card.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);
const Color _kPaperWhite = Color(0xFFF3F3EE);
const Color _kWarmBeige = Color(0xFFE5E3D4);

// ---------------------------------------------------------------------------
// Explore Filter Enum
// ---------------------------------------------------------------------------

enum _ExploreFilter {
  all,
  quiet,
  moderate,
  noisy,
  nearby,
  popular,
}

extension _ExploreFilterLabel on _ExploreFilter {
  String get label {
    switch (this) {
      case _ExploreFilter.all:
        return '전체';
      case _ExploreFilter.quiet:
        return '딥 포커스';
      case _ExploreFilter.moderate:
        return '소프트 바이브';
      case _ExploreFilter.noisy:
        return '소셜 버즈';
      case _ExploreFilter.nearby:
        return '가까운순';
      case _ExploreFilter.popular:
        return '인기순';
    }
  }
}

// ---------------------------------------------------------------------------
// Explore Screen
// ---------------------------------------------------------------------------

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ExploreFilter _activeFilter = _ExploreFilter.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CafeModel> _applyFilters(List<CafeModel> cafes) {
    List<CafeModel> filtered = List.from(cafes);

    // Apply search query (case-insensitive, whitespace-tolerant)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q) ||
              c.district.toLowerCase().contains(q) ||
              c.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }

    // Apply filter
    switch (_activeFilter) {
      case _ExploreFilter.all:
        break;
      case _ExploreFilter.quiet:
        filtered = filtered
            .where((c) => c.noiseLevel == NoiseLevel.quiet)
            .toList();
      case _ExploreFilter.moderate:
        filtered = filtered
            .where((c) => c.noiseLevel == NoiseLevel.moderate)
            .toList();
      case _ExploreFilter.noisy:
        filtered = filtered
            .where(
                (c) => c.noiseLevel == NoiseLevel.noisy || c.noiseLevel == NoiseLevel.loud)
            .toList();
      case _ExploreFilter.nearby:
        filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case _ExploreFilter.popular:
        filtered.sort(
            (a, b) => b.measurementCount.compareTo(a.measurementCount));
    }

    return filtered;
  }

  void _showRegisterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _RegisterCafeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cafesAsync = ref.watch(cafesProvider);

    return Scaffold(
      backgroundColor: _kOffWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + Search Bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Text(
                        '탐색',
                        style: TextStyle(
                          color: _kNavy,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          fontFamily: GoogleFonts.notoSansKr().fontFamily,
                        ),
                      ),
                      const Spacer(),
                      // Cafe count badge
                      cafesAsync.when(
                        data: (cafes) {
                          final filtered = _applyFilters(cafes);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kLightTeal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${filtered.length}개의 카페',
                              style: TextStyle(
                                color: _kDeepTeal,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily:
                                    GoogleFonts.notoSansKr().fontFamily,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Search Bar
                  _ExploreSearchBar(
                    controller: _searchController,
                    searchQuery: _searchQuery,
                    onChanged: (q) => setState(() => _searchQuery = q),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),

                  const SizedBox(height: 14),

                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _ExploreFilter.values.map((f) {
                        return _FilterChip(
                          label: f.label,
                          isActive: _activeFilter == f,
                          onTap: () => setState(() => _activeFilter = f),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Divider ───────────────────────────────────────────────────
            Container(height: 1, color: _kWarmBeige.withOpacity(0.6)),

            // ── Cafe List ─────────────────────────────────────────────────
            Expanded(
              child: cafesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_kMutedTeal),
                    strokeWidth: 2,
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: _kNavy.withOpacity(0.25)),
                        const SizedBox(height: 12),
                        Text(
                          '불러오는 중 오류가 발생했어요',
                          style: TextStyle(
                            color: _kNavy.withOpacity(0.5),
                            fontSize: 15,
                            fontFamily: GoogleFonts.notoSansKr().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (cafes) {
                  final filtered = _applyFilters(cafes);
                  if (filtered.isEmpty) {
                    return _EmptyState(query: _searchQuery);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => CafeCard(cafe: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FAB: 카페 등록 ─────────────────────────────────────────────────
      floatingActionButton: _RegisterFab(onTap: _showRegisterSheet),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Bar
// ---------------------------------------------------------------------------

class _ExploreSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String searchQuery;

  const _ExploreSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _kPaperWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kWarmBeige, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: _kMutedTeal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  color: _kNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                  fontFamily: GoogleFonts.notoSansKr().fontFamily,
                ),
                cursorHeight: 18,
                cursorColor: _kMutedTeal,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: '카페 이름 또는 지역 검색',
                  hintStyle: TextStyle(
                    color: _kNavy.withOpacity(0.35),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                    fontFamily: GoogleFonts.notoSansKr().fontFamily,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: _kNavy.withOpacity(0.3),
                ),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? _kDeepTeal : _kPaperWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _kDeepTeal : _kWarmBeige,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _kNavy.withOpacity(0.6),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontFamily: GoogleFonts.notoSansKr().fontFamily,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kLightTeal.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '☕',
                  style: TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              query.isEmpty ? '카페를 검색해보세요' : '검색 결과가 없어요',
              style: TextStyle(
                color: _kNavy,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFamily: GoogleFonts.notoSansKr().fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? '카페 이름, 지역명, 태그로 검색할 수 있어요'
                  : '다른 검색어나 필터를 사용해보세요',
              style: TextStyle(
                color: _kNavy.withOpacity(0.45),
                fontSize: 14,
                fontFamily: GoogleFonts.notoSansKr().fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Register FAB
// ---------------------------------------------------------------------------

class _RegisterFab extends StatelessWidget {
  final VoidCallback onTap;

  const _RegisterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kDeepTeal, _kMutedTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _kDeepTeal.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              '카페 등록',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: GoogleFonts.notoSansKr().fontFamily,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Register Cafe Bottom Sheet (placeholder)
// ---------------------------------------------------------------------------

class _RegisterCafeSheet extends StatelessWidget {
  const _RegisterCafeSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kOffWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kWarmBeige,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kLightTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.add_location_alt_outlined,
                color: _kDeepTeal,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            '새 카페 등록',
            style: TextStyle(
              color: _kNavy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontFamily: GoogleFonts.notoSansKr().fontFamily,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'Google Places API 연동 후 카페를 등록할 수 있어요.\n현재는 준비 중입니다.',
            style: TextStyle(
              color: _kNavy.withOpacity(0.5),
              fontSize: 14,
              height: 1.6,
              fontFamily: GoogleFonts.notoSansKr().fontFamily,
            ),
          ),

          const SizedBox(height: 8),

          // Coming soon badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kLightTeal.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kLightTeal),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction_rounded,
                    size: 14, color: _kDeepTeal),
                const SizedBox(width: 6),
                Text(
                  '준비 중 · Google Places API 연동 예정',
                  style: TextStyle(
                    color: _kDeepTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: GoogleFonts.notoSansKr().fontFamily,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Close button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: _kPaperWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kWarmBeige),
                ),
                child: Center(
                  child: Text(
                    '닫기',
                    style: TextStyle(
                      color: _kNavy.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.notoSansKr().fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
