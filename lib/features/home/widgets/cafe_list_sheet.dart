import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/cafe_providers.dart';
import '../../../core/widgets/cafe_card.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);
const Color _kPaperWhite = Color(0xFFF3F3EE);
const Color _kWarmBeige = Color(0xFFE5E3D4);

class CafeListSheet extends ConsumerWidget {
  final DraggableScrollableController sheetController;

  const CafeListSheet({super.key, required this.sheetController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.28,
      minChildSize: 0.12,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.12, 0.28, 0.55, 0.88],
      builder: (context, scrollController) {
        return _SheetContent(scrollController: scrollController);
      },
    );
  }
}

class _SheetContent extends ConsumerWidget {
  final ScrollController scrollController;

  const _SheetContent({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedAsync = ref.watch(sortedCafesProvider);
    final currentSort = ref.watch(cafeSortOrderProvider);

    return Container(
      decoration: BoxDecoration(
        color: _kOffWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _kWarmBeige, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Pinned header
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _kWarmBeige,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '근처 카페',
                              style: TextStyle(
                                color: _kNavy,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            sortedAsync.maybeWhen(
                              data: (cafes) => Text(
                                '${cafes.length}개 발견',
                                style: TextStyle(
                                  color: _kNavy.withOpacity(0.4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      // Filter icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kPaperWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kWarmBeige),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _kNavy.withOpacity(0.6),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Sort options
                _SortOptions(currentSort: currentSort),

                const SizedBox(height: 4),

                Divider(
                  color: _kWarmBeige,
                  height: 1,
                  thickness: 1,
                ),
              ],
            ),
          ),

          // Cafe list
          sortedAsync.when(
            data: (cafes) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= cafes.length) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CafeCard(cafe: cafes[index]),
                    );
                  },
                  childCount: cafes.length,
                ),
              ),
            ),
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kMutedTeal,
                  ),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    '카페 정보를 불러올 수 없어요',
                    style: TextStyle(
                      color: _kNavy.withOpacity(0.5),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
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

// ---------------------------------------------------------------------------
// Sort Options Row
// ---------------------------------------------------------------------------

class _SortOptions extends ConsumerWidget {
  final CafeSortOrder currentSort;

  const _SortOptions({required this.currentSort});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _SortChip(
            label: '거리순',
            isSelected: currentSort == CafeSortOrder.distance,
            onTap: () => ref.read(cafeSortOrderProvider.notifier).state =
                CafeSortOrder.distance,
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: '조용한순',
            isSelected: currentSort == CafeSortOrder.quiet,
            onTap: () => ref.read(cafeSortOrderProvider.notifier).state =
                CafeSortOrder.quiet,
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: '인기순',
            isSelected: currentSort == CafeSortOrder.popular,
            onTap: () => ref.read(cafeSortOrderProvider.notifier).state =
                CafeSortOrder.popular,
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _kDeepTeal : _kPaperWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kDeepTeal : _kWarmBeige,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _kNavy.withOpacity(0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}
