import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/cafe_providers.dart';
import 'widgets/cafe_list_sheet.dart';
import 'widgets/map_view.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);
const Color _kPaperWhite = Color(0xFFF3F3EE);
const Color _kWarmBeige = Color(0xFFE5E3D4);
const Color _kTerra = Color(0xFFA84B2F);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == 1) {
      context.push('/measure');
      return;
    }
    if (index == 2) {
      context.push('/ranking');
      return;
    }
    if (index == 3) {
      context.push('/profile');
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kOffWhite,
      extendBody: true,
      body: Stack(
        children: [
          // Map takes the full screen
          const MapView(),

          // Top search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SearchBar(),
            ),
          ),

          // Bottom draggable sheet
          CafeListSheet(sheetController: _sheetController),
        ],
      ),

      // Bottom navigation bar
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),

      // FAB for quick measurement
      floatingActionButton: _MeasureFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ---------------------------------------------------------------------------
// Search Bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: open search screen
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _kOffWhite,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _kWarmBeige, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kNavy.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: _kMutedTeal, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '카페 이름 또는 지역 검색',
                style: TextStyle(
                  color: _kNavy.withOpacity(0.35),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kLightTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '지금 근처',
                style: TextStyle(
                  color: _kDeepTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Measure FAB
// ---------------------------------------------------------------------------

class _MeasureFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/measure'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kDeepTeal, _kMutedTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kDeepTeal.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
            SizedBox(height: 1),
            Text(
              '측정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Navigation Bar
// ---------------------------------------------------------------------------

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: '홈'),
      const _NavItem(
        icon: Icons.graphic_eq_outlined,
        activeIcon: Icons.graphic_eq,
        label: '측정',
      ),
      const _NavItem(
        icon: Icons.emoji_events_outlined,
        activeIcon: Icons.emoji_events,
        label: '랭킹',
      ),
      const _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: '프로필',
      ),
    ];

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: _kOffWhite,
        border: Border(top: BorderSide(color: _kWarmBeige, width: 1.0)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isSelected = i == selectedIndex;
            return Expanded(
              child: _buildNavItem(item, isSelected, i),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? _kDeepTeal : _kNavy.withOpacity(0.35),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? _kDeepTeal : _kNavy.withOpacity(0.35),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
