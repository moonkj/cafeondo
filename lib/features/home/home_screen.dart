import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cafe_providers.dart';
import 'widgets/map_view.dart';

// ---------------------------------------------------------------------------
// Noise Spot AppColors (replicated)
// ---------------------------------------------------------------------------

const _kMintGreen = Color(0xFF5BC8AC);
const _kSkyBlue = Color(0xFF78C5E8);
const _kRelaxGreen = Color(0xFF9CC5A1);
const _kDivider = Color(0xFFE8F2F0);
const _kTextSecondary = Color(0xFF6B8E8A);
const _kBgWhite = Color(0xFFFAFCFB);

// ---------------------------------------------------------------------------
// Home Screen
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // null = show all, otherwise filter by noise level
  NoiseLevel? _filter;

  static const double _filterBarH = 44;
  static const double _navH = 70;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final totalBottom = _filterBarH + _navH + bottomPad;

    return Scaffold(
      backgroundColor: _kBgWhite,
      extendBody: true,
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          Positioned.fill(
            child: MapView(
              filterLevel: _filter,
              bottomOffset: totalBottom,
            ),
          ),

          // ── Search bar (top) ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SearchBar(),
              ),
            ),
          ),

          // ── Filter chips (bottom, above nav) ─────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: _navH + bottomPad,
            child: _FilterBar(
              activeFilter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar (Noise Spot style — white, 48 dp, 24 dp radius)
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _kTextSecondary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '카페, 도서관, 공원 검색...',
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar — Noise Spot FilterBar (STUDY / MEETING / RELAX style)
// ---------------------------------------------------------------------------

class _FilterChipData {
  final NoiseLevel? level;
  final String label;
  final String emoji;
  final Color color;
  const _FilterChipData(this.level, this.label, this.emoji, this.color);
}

const _kChips = [
  _FilterChipData(NoiseLevel.quiet, 'STUDY', '📚', _kMintGreen),
  _FilterChipData(NoiseLevel.moderate, 'RELAX', '🌿', _kRelaxGreen),
  _FilterChipData(NoiseLevel.noisy, 'MEETING', '💬', _kSkyBlue),
];

class _FilterBar extends StatelessWidget {
  final NoiseLevel? activeFilter;
  final ValueChanged<NoiseLevel?> onFilterChanged;

  const _FilterBar({required this.activeFilter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _kChips.map((chip) {
          final isActive = activeFilter == chip.level;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onFilterChanged(isActive ? null : chip.level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? chip.color : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isActive ? chip.color : _kDivider,
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: chip.color.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(chip.emoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      chip.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : _kTextSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
