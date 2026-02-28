import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/cafe_providers.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);
const Color _kWarmBeige = Color(0xFFE5E3D4);
const Color _kTerra = Color(0xFFA84B2F);

// Mauve for loud noise
const Color _kMauve = Color(0xFF9C6B8A);

/// Color per noise level for map markers
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
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5448, 127.0557), // Seoul Seongsu-dong
    zoom: 14.5,
  );

  @override
  void initState() {
    super.initState();
  }

  Future<void> _buildMarkers(List<CafeModel> cafes) async {
    final newMarkers = <Marker>{};
    for (final cafe in cafes) {
      final bitmap = await _createMarkerBitmap(cafe);
      final marker = Marker(
        markerId: MarkerId(cafe.id),
        position: cafe.location,
        icon: bitmap,
        onTap: () {
          ref.read(selectedCafeProvider.notifier).state = cafe;
          context.push('/cafe/${cafe.id}');
        },
      );
      newMarkers.add(marker);
    }
    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
      });
    }
  }

  Future<BitmapDescriptor> _createMarkerBitmap(CafeModel cafe) async {
    final color = _markerColor(cafe.noiseLevel);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 44.0;

    // Background circle
    final bgPaint = Paint()..color = color;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 2,
      bgPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 2,
      borderPaint,
    );

    // dB text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${cafe.averageDb.round()}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _applyMapStyle(controller);
  }

  Future<void> _applyMapStyle(GoogleMapController controller) async {
    // Minimal map style — muted colors, no POI clutter
    const style = '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#cce8ed"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f3f3ee"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#6a6a6a"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#091717"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels.text.fill","stylers":[{"color":"#555555"}]}
]
''';
    await controller.setMapStyle(style);
  }

  void _goToMyLocation() {
    // In a real app, use geolocator to get current position
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(_initialPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cafesAsync = ref.watch(cafesProvider);

    cafesAsync.whenData((cafes) {
      if (_markers.isEmpty) {
        _buildMarkers(cafes);
      }
    });

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: _initialPosition,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          padding: const EdgeInsets.only(
            top: 80,
            bottom: 260,
          ),
        ),

        // Custom My Location button
        Positioned(
          right: 16,
          bottom: 280,
          child: _LocationButton(onTap: _goToMyLocation),
        ),

        // Noise level legend
        Positioned(
          left: 16,
          bottom: 280,
          child: _NoiseLegend(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// My Location Button
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
        child: Icon(
          Icons.my_location_rounded,
          color: _kDeepTeal,
          size: 20,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Noise Legend
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
          _LegendItem(color: _kMutedTeal, label: '조용함'),
          const SizedBox(height: 4),
          _LegendItem(color: _kWarmBeige, label: '보통'),
          const SizedBox(height: 4),
          _LegendItem(color: _kTerra, label: '시끄러움'),
          const SizedBox(height: 4),
          _LegendItem(color: _kMauve, label: '매우 시끄러움'),
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
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }
}
