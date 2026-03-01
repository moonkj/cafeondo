import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../providers/cafe_providers.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);
const Color _kWarmBeige = Color(0xFFE5E3D4);
const Color _kTerra = Color(0xFFA84B2F);
const Color _kMauve = Color(0xFF9C6B8A);

Color _markerColor(NoiseLevel level) {
  switch (level) {
    case NoiseLevel.quiet:
      return _kMutedTeal;
    case NoiseLevel.moderate:
      return _kWarmBeige;
    case NoiseLevel.noisy:
      return _kTerra;
    case NoiseLevel.loud:
      return _kMauve;
  }
}

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final MapController _mapController = MapController();
  LatLng? _myLocation;

  static const _initial = LatLng(37.5448, 127.0557); // 성수동

  @override
  void initState() {
    super.initState();
    _fetchMyLocation();
  }

  Future<void> _fetchMyLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) {
        setState(() {
          _myLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_myLocation!, 14.5);
      }
    } catch (_) {
      // 권한 없거나 실패 시 초기 위치 유지
    }
  }

  void _goToMyLocation() {
    if (_myLocation != null) {
      _mapController.move(_myLocation!, 15.0);
    } else {
      _mapController.move(_initial, 14.5);
      _fetchMyLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cafesAsync = ref.watch(cafesProvider);

    return Stack(
      children: [
        // ── 지도 ──────────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initial,
            initialZoom: 14.5,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            // OpenStreetMap 타일 (API키 불필요)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.cafeondo.app',
              tileBuilder: _mintTileBuilder,
            ),

            // 내 위치 마커
            if (_myLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _myLocation!,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _kDeepTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: _kDeepTeal.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // 카페 마커
            cafesAsync.when(
              data: (cafes) => MarkerLayer(
                markers: cafes.map((cafe) {
                  final color = _markerColor(cafe.noiseLevel);
                  return Marker(
                    point: cafe.location,
                    width: 56,
                    height: 56,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedCafeProvider.notifier).set(cafe);
                        context.push('/cafe/${cafe.id}');
                      },
                      child: _CafeMarker(cafe: cafe, color: color),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const MarkerLayer(markers: []),
              error: (_, __) => const MarkerLayer(markers: []),
            ),
          ],
        ),

        // ── 내 위치 버튼 ────────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 280,
          child: _LocationButton(onTap: _goToMyLocation),
        ),

        // ── 범례 ────────────────────────────────────────────────────────
        Positioned(
          left: 16,
          bottom: 280,
          child: _NoiseLegend(),
        ),
      ],
    );
  }
}

/// OSM 타일에 민트 틴트를 적용해 앱 컬러와 조화롭게 만듦
Widget _mintTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tile,
) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      // 채도 낮추고 민트 틴트 적용
      0.85, 0.05, 0.10, 0, 8,
      0.05, 0.88, 0.07, 0, 8,
      0.05, 0.08, 0.90, 0, 10,
      0,    0,    0,    1, 0,
    ]),
    child: tileWidget,
  );
}

// ---------------------------------------------------------------------------
// 카페 마커 위젯
// ---------------------------------------------------------------------------

class _CafeMarker extends StatelessWidget {
  final CafeModel cafe;
  final Color color;

  const _CafeMarker({required this.cafe, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${cafe.averageDb.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ),
        // 말풍선 꼬리
        CustomPaint(
          size: const Size(8, 5),
          painter: _MarkerTailPainter(color),
        ),
      ],
    );
  }
}

class _MarkerTailPainter extends CustomPainter {
  final Color color;
  _MarkerTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MarkerTailPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// 내 위치 버튼
// ---------------------------------------------------------------------------

class _LocationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _kOffWhite,
          shape: BoxShape.circle,
          border: Border.all(color: _kWarmBeige, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: _kNavy.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: _kDeepTeal,
          size: 20,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 범례
// ---------------------------------------------------------------------------

class _NoiseLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kOffWhite.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kWarmBeige, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: _kMutedTeal, label: '딥 포커스'),
          const SizedBox(height: 4),
          _LegendItem(color: _kWarmBeige, label: '소프트 바이브'),
          const SizedBox(height: 4),
          _LegendItem(color: _kTerra, label: '소셜 버즈'),
          const SizedBox(height: 4),
          _LegendItem(color: _kMauve, label: '라이브 에너지'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: _kNavy.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: GoogleFonts.notoSansKr().fontFamily,
          ),
        ),
      ],
    );
  }
}
