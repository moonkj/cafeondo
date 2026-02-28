import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cafe_providers.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);
const Color _kPaperWhite = Color(0xFFF3F3EE);
const Color _kWarmBeige = Color(0xFFE5E3D4);
const Color _kTerra = Color(0xFFA84B2F);
const Color _kMauve = Color(0xFF9C6B8A);

class CafeCard extends StatelessWidget {
  final CafeModel cafe;

  const CafeCard({super.key, required this.cafe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/cafe/${cafe.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kOffWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kWarmBeige, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cafe photo / placeholder
            _CafePhoto(
              imageUrl: cafe.imageUrl,
              cafeName: cafe.name,
              noiseLevel: cafe.noiseLevel,
            ),

            const SizedBox(width: 14),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + distance row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cafe.name,
                          style: TextStyle(
                            color: _kNavy,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            fontFamily: 'Pretendard',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDistance(cafe.distanceKm),
                        style: TextStyle(
                          color: _kNavy.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Address
                  Text(
                    cafe.address,
                    style: TextStyle(
                      color: _kNavy.withOpacity(0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Bottom row: noise badge + measurement count
                  Row(
                    children: [
                      _NoiseBadge(
                        noiseLevel: cafe.noiseLevel,
                        db: cafe.averageDb,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 12,
                        color: _kNavy.withOpacity(0.3),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${cafe.measurementCount}회 측정',
                        style: TextStyle(
                          color: _kNavy.withOpacity(0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: _kNavy.withOpacity(0.25),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()}m';
    }
    return '${km.toStringAsFixed(1)}km';
  }
}

// ---------------------------------------------------------------------------
// Cafe Photo
// ---------------------------------------------------------------------------

class _CafePhoto extends StatelessWidget {
  final String? imageUrl;
  final String cafeName;
  final NoiseLevel noiseLevel;

  const _CafePhoto({
    required this.imageUrl,
    required this.cafeName,
    required this.noiseLevel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Placeholder(
                  cafeName: cafeName,
                  noiseLevel: noiseLevel,
                ),
              )
            : _Placeholder(cafeName: cafeName, noiseLevel: noiseLevel),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String cafeName;
  final NoiseLevel noiseLevel;

  const _Placeholder({required this.cafeName, required this.noiseLevel});

  Color get _bgColor {
    switch (noiseLevel) {
      case NoiseLevel.quiet:
        return _kLightTeal;
      case NoiseLevel.moderate:
        return _kWarmBeige;
      case NoiseLevel.noisy:
        return const Color(0xFFFFDDD6);
      case NoiseLevel.loud:
        return const Color(0xFFEDD6E8);
    }
  }

  Color get _textColor {
    switch (noiseLevel) {
      case NoiseLevel.quiet:
        return _kDeepTeal;
      case NoiseLevel.moderate:
        return const Color(0xFF6B6350);
      case NoiseLevel.noisy:
        return _kTerra;
      case NoiseLevel.loud:
        return _kMauve;
    }
  }

  static const _kMauve = Color(0xFF9C6B8A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: Center(
        child: Text(
          cafeName.isNotEmpty ? cafeName[0] : '☕',
          style: TextStyle(
            color: _textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Noise Badge
// ---------------------------------------------------------------------------

class _NoiseBadge extends StatelessWidget {
  final NoiseLevel noiseLevel;
  final double db;

  const _NoiseBadge({required this.noiseLevel, required this.db});

  Color get _bgColor {
    switch (noiseLevel) {
      case NoiseLevel.quiet:
        return _kLightTeal;
      case NoiseLevel.moderate:
        return _kWarmBeige;
      case NoiseLevel.noisy:
        return const Color(0xFFFFDDD6);
      case NoiseLevel.loud:
        return const Color(0xFFEDD6E8);
    }
  }

  Color get _textColor {
    switch (noiseLevel) {
      case NoiseLevel.quiet:
        return _kDeepTeal;
      case NoiseLevel.moderate:
        return const Color(0xFF6B6350);
      case NoiseLevel.noisy:
        return _kTerra;
      case NoiseLevel.loud:
        return _kMauve;
    }
  }

  static const _kMauve = Color(0xFF9C6B8A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${noiseLevel.label} ${db.round()}dB',
            style: TextStyle(
              color: _textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}
