import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../providers/cafe_providers.dart';

// ---------------------------------------------------------------------------
// dB-based marker color (mirrors Noise Spot's DbClassifier.colorFromDb)
// ---------------------------------------------------------------------------

Color _dbColor(double db) {
  if (db < 40) return const Color(0xFF5BC8AC); // very quiet – mint
  if (db < 55) return const Color(0xFF78C5E8); // quiet      – sky blue
  if (db < 70) return const Color(0xFFF5C842); // moderate   – yellow
  if (db < 85) return const Color(0xFFFF9A3C); // loud       – orange
  return const Color(0xFFE05C5C); //              very loud  – red
}

// ---------------------------------------------------------------------------
// Google Maps style (copied from Noise Spot assets/map_style.json)
// ---------------------------------------------------------------------------

const _kMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},
  {"featureType":"poi","elementType":"labels.text","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e8f5e9"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#e0e0e0"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9e8f5"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}
]
''';

// ---------------------------------------------------------------------------
// MapView
// ---------------------------------------------------------------------------

class MapView extends ConsumerStatefulWidget {
  final NoiseLevel? filterLevel;
  final double bottomOffset;

  const MapView({
    super.key,
    this.filterLevel,
    this.bottomOffset = 140,
  });

  @override
  ConsumerState<MapView> createState() => MapViewState();
}

class MapViewState extends ConsumerState<MapView> {
  gm.GoogleMapController? _ctrl;
  gm.LatLng? _myLocation;

  // icon cache: key = "quiet" / "moderate" / "noisy" / "loud"
  final Map<String, gm.BitmapDescriptor> _iconCache = {};
  bool _iconsReady = false;
  bool _didInit = false;

  static const _initial = gm.LatLng(37.5448, 127.0557); // 성수동

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      final pr = MediaQuery.of(context).devicePixelRatio;
      _loadIcons(pr);
      _fetchLocation();
    }
  }

  // ── 마커 아이콘 생성 (Noise Spot SpotMarkerWidget.toBitmapDescriptor) ──────

  Future<void> _loadIcons(double pixelRatio) async {
    final cafesAsync = ref.read(cafesProvider);
    final cafes = cafesAsync.when(
      data: (d) => d,
      loading: () => <CafeModel>[],
      error: (_, __) => <CafeModel>[],
    );

    // Pre-generate one icon per unique (noiseLevel, averageDb) pair
    final seen = <String>{};
    for (final cafe in cafes) {
      final key = cafe.noiseLevel.name;
      if (!seen.contains(key)) {
        seen.add(key);
        _iconCache[key] =
            await _makeMarker(cafe.averageDb, pixelRatio);
      }
    }

    // Fallback icons for each level in case no cafe data yet
    for (final entry in {
      'quiet': 45.0,
      'moderate': 58.0,
      'noisy': 70.0,
      'loud': 80.0,
    }.entries) {
      _iconCache.putIfAbsent(
          entry.key, () => gm.BitmapDescriptor.defaultMarker);
      // Replace with proper icon
      _iconCache[entry.key] =
          await _makeMarker(entry.value, pixelRatio);
    }

    if (mounted) setState(() => _iconsReady = true);
  }

  /// Noise Spot–style 32 dp circle with dB text.
  /// Uses BitmapDescriptor.bytes + imagePixelRatio (exact Noise Spot API).
  Future<gm.BitmapDescriptor> _makeMarker(
    double db,
    double pixelRatio,
  ) async {
    const logicalSize = 32.0;
    final ps = logicalSize * pixelRatio; // physical pixels
    const borderWidth = 2.5;
    final bwScaled = borderWidth * pixelRatio;
    final innerRadius = ps / 2 - bwScaled / 2;
    final center = Offset(ps / 2, ps / 2);
    final color = _dbColor(db);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Drop shadow
    canvas.drawCircle(
      center + Offset(0, pixelRatio),
      innerRadius,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter =
            ui.MaskFilter.blur(ui.BlurStyle.normal, 3 * pixelRatio),
    );

    // Filled circle
    canvas.drawCircle(center, innerRadius, Paint()..color = color);

    // White border
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = bwScaled,
    );

    // dB number (white, 9pt × pixelRatio)
    final tp = TextPainter(
      text: TextSpan(
        text: db.toStringAsFixed(0),
        style: TextStyle(
          color: Colors.white,
          fontSize: 9 * pixelRatio,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(ps.ceil(), ps.ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return gm.BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  // ── Location ─────────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() => _myLocation = gm.LatLng(pos.latitude, pos.longitude));
        _ctrl?.animateCamera(
          gm.CameraUpdate.newLatLngZoom(_myLocation!, 14.5),
        );
      }
    } catch (_) {}
  }

  void goToMyLocation() {
    if (_myLocation != null) {
      _ctrl?.animateCamera(
        gm.CameraUpdate.newLatLngZoom(_myLocation!, 15.0),
      );
    } else {
      _fetchLocation();
    }
  }

  // ── Marker set ────────────────────────────────────────────────────────────

  Set<gm.Marker> _buildMarkers(BuildContext context) {
    if (!_iconsReady) return {};

    final cafesAsync = ref.read(cafesProvider);
    final cafes = cafesAsync.when(
      data: (d) => d,
      loading: () => <CafeModel>[],
      error: (_, __) => <CafeModel>[],
    );

    final visible = widget.filterLevel == null
        ? cafes
        : cafes.where((c) => c.noiseLevel == widget.filterLevel).toList();

    return visible.map((cafe) {
      return gm.Marker(
        markerId: gm.MarkerId(cafe.id),
        position: gm.LatLng(cafe.location.latitude, cafe.location.longitude),
        icon: _iconCache[cafe.noiseLevel.name] ??
            gm.BitmapDescriptor.defaultMarker,
        onTap: () {
          ref.read(selectedCafeProvider.notifier).set(cafe);
          context.push('/cafe/${cafe.id}');
        },
      );
    }).toSet();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(cafesProvider); // rebuild when cafes load

    return Stack(
      children: [
        gm.GoogleMap(
          initialCameraPosition: const gm.CameraPosition(
            target: _initial,
            zoom: 14.5,
          ),
          onMapCreated: (ctrl) {
            _ctrl = ctrl;
            ctrl.setMapStyle(_kMapStyle);
          },
          markers: _buildMarkers(context),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          minMaxZoomPreference: const gm.MinMaxZoomPreference(10, 18),
        ),

        // My location FAB (Noise Spot position: right 16, bottom 94)
        Positioned(
          right: 16,
          bottom: widget.bottomOffset + 12,
          child: _LocationButton(onTap: goToMyLocation),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Location FAB (white circle, mint icon — Noise Spot style)
// ---------------------------------------------------------------------------

class _LocationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: onTap,
      backgroundColor: Colors.white,
      elevation: 4,
      child: const Icon(
        Icons.my_location_rounded,
        color: Color(0xFF5BC8AC), // AppColors.mintGreen
        size: 20,
      ),
    );
  }
}
