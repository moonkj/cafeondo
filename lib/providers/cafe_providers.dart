import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum NoiseLevel {
  quiet,    // 조용함 (~50dB)
  moderate, // 보통 (51–65dB)
  noisy,    // 시끄러움 (66–75dB)
  loud,     // 매우 시끄러움 (76dB+)
}

extension NoiseLevelExtension on NoiseLevel {
  String get label {
    switch (this) {
      case NoiseLevel.quiet:
        return '딥 포커스';
      case NoiseLevel.moderate:
        return '소프트 바이브';
      case NoiseLevel.noisy:
        return '소셜 버즈';
      case NoiseLevel.loud:
        return '라이브 에너지';
    }
  }

  String get subtitle {
    switch (this) {
      case NoiseLevel.quiet:
        return '몰입 온도';
      case NoiseLevel.moderate:
        return '여유 온도';
      case NoiseLevel.noisy:
        return '활기 온도';
      case NoiseLevel.loud:
        return '열정 온도';
    }
  }

  double get maxDb {
    switch (this) {
      case NoiseLevel.quiet:
        return 50.0;
      case NoiseLevel.moderate:
        return 65.0;
      case NoiseLevel.noisy:
        return 75.0;
      case NoiseLevel.loud:
        return 100.0;
    }
  }
}

NoiseLevel noiseLevelFromDb(double db) {
  if (db <= 50) return NoiseLevel.quiet;
  if (db <= 65) return NoiseLevel.moderate;
  if (db <= 75) return NoiseLevel.noisy;
  return NoiseLevel.loud;
}

class CafeModel {
  final String id;
  final String name;
  final String address;
  final String district;
  final LatLng location;
  final double averageDb;
  final NoiseLevel noiseLevel;
  final int measurementCount;
  final double distanceKm;
  final String? imageUrl;
  final List<String> tags;
  final List<HourlyNoise> hourlyNoise;
  final List<RecentMeasurement> recentMeasurements;

  const CafeModel({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.location,
    required this.averageDb,
    required this.noiseLevel,
    required this.measurementCount,
    required this.distanceKm,
    this.imageUrl,
    required this.tags,
    required this.hourlyNoise,
    required this.recentMeasurements,
  });
}

class HourlyNoise {
  final int hour; // 8–22
  final double db;

  const HourlyNoise({required this.hour, required this.db});
}

class RecentMeasurement {
  final String userName;
  final double db;
  final NoiseLevel noiseLevel;
  final DateTime timestamp;
  final String? comment;

  const RecentMeasurement({
    required this.userName,
    required this.db,
    required this.noiseLevel,
    required this.timestamp,
    this.comment,
  });
}

// ---------------------------------------------------------------------------
// Mock Data
// ---------------------------------------------------------------------------

List<HourlyNoise> _generateHourlyNoise(List<double> values) {
  final hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];
  return List.generate(
    hours.length,
    (i) => HourlyNoise(hour: hours[i], db: values[i]),
  );
}

final _mockCafes = <CafeModel>[
  CafeModel(
    id: 'cafe_001',
    name: '블루보틀 성수',
    address: '서울 성동구 아차산로 17길 48',
    district: '성수동',
    location: const LatLng(37.5448, 127.0557),
    averageDb: 48.3,
    noiseLevel: NoiseLevel.quiet,
    measurementCount: 127,
    distanceKm: 0.3,
    tags: ['조용한', '집중하기 좋은', '콘센트 있음', '넓은 공간'],
    hourlyNoise: _generateHourlyNoise([
      42, 44, 47, 51, 58, 62, 60, 56, 54, 58, 62, 60, 55, 50, 46,
    ]),
    recentMeasurements: [
      RecentMeasurement(
        userName: '김민준',
        db: 46.2,
        noiseLevel: NoiseLevel.quiet,
        timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
        comment: '오전에 정말 조용하고 좋아요',
      ),
      RecentMeasurement(
        userName: '이서연',
        db: 51.8,
        noiseLevel: NoiseLevel.moderate,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RecentMeasurement(
        userName: '박지훈',
        db: 44.5,
        noiseLevel: NoiseLevel.quiet,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        comment: '노트북 작업하기 완벽한 환경',
      ),
    ],
  ),
  CafeModel(
    id: 'cafe_002',
    name: '어니언 성수',
    address: '서울 성동구 아차산로11길 4',
    district: '성수동',
    location: const LatLng(37.5441, 127.0567),
    averageDb: 62.1,
    noiseLevel: NoiseLevel.moderate,
    measurementCount: 203,
    distanceKm: 0.5,
    tags: ['대화하기 좋은', '힙한 분위기', '인스타 명소', '주말 혼잡'],
    hourlyNoise: _generateHourlyNoise([
      48, 52, 56, 60, 66, 68, 67, 65, 63, 66, 70, 68, 64, 60, 55,
    ]),
    recentMeasurements: [
      RecentMeasurement(
        userName: '최수아',
        db: 65.0,
        noiseLevel: NoiseLevel.moderate,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        comment: '점심시간엔 좀 시끄럽네요',
      ),
      RecentMeasurement(
        userName: '정도현',
        db: 58.3,
        noiseLevel: NoiseLevel.moderate,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  ),
  CafeModel(
    id: 'cafe_003',
    name: '트리하우스 카페',
    address: '서울 마포구 연남동 384-12',
    district: '연남동',
    location: const LatLng(37.5626, 126.9236),
    averageDb: 44.7,
    noiseLevel: NoiseLevel.quiet,
    measurementCount: 89,
    distanceKm: 1.2,
    tags: ['조용한', '아늑한', '집중하기 좋은', '반려동물 가능'],
    hourlyNoise: _generateHourlyNoise([
      38, 40, 43, 45, 50, 52, 51, 49, 47, 50, 54, 52, 48, 44, 40,
    ]),
    recentMeasurements: [
      RecentMeasurement(
        userName: '한예린',
        db: 42.1,
        noiseLevel: NoiseLevel.quiet,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        comment: '오늘도 완전 조용해요. 단골입니다',
      ),
    ],
  ),
  CafeModel(
    id: 'cafe_004',
    name: '알베르 카페',
    address: '서울 강남구 청담동 125-12',
    district: '청담동',
    location: const LatLng(37.5264, 127.0503),
    averageDb: 70.4,
    noiseLevel: NoiseLevel.noisy,
    measurementCount: 56,
    distanceKm: 2.1,
    tags: ['활기찬', '대화하기 좋은', '브런치', '주말 인기'],
    hourlyNoise: _generateHourlyNoise([
      52, 55, 58, 64, 72, 76, 74, 71, 68, 72, 75, 73, 69, 65, 60,
    ]),
    recentMeasurements: [
      RecentMeasurement(
        userName: '오성민',
        db: 72.3,
        noiseLevel: NoiseLevel.noisy,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        comment: '브런치 타임엔 꽤 시끄러워요',
      ),
    ],
  ),
  CafeModel(
    id: 'cafe_005',
    name: '북한산 뷰 카페',
    address: '서울 강북구 우이동 255-3',
    district: '우이동',
    location: const LatLng(37.6583, 127.0130),
    averageDb: 41.2,
    noiseLevel: NoiseLevel.quiet,
    measurementCount: 34,
    distanceKm: 3.7,
    tags: ['자연 뷰', '조용한', '힐링', '테라스'],
    hourlyNoise: _generateHourlyNoise([
      36, 38, 40, 42, 46, 48, 47, 46, 44, 47, 50, 48, 44, 40, 37,
    ]),
    recentMeasurements: [
      RecentMeasurement(
        userName: '임나영',
        db: 39.8,
        noiseLevel: NoiseLevel.quiet,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        comment: '산 뷰 보면서 조용히 독서하기 완벽',
      ),
    ],
  ),
  CafeModel(
    id: 'cafe_006',
    name: '스타벅스 광화문점',
    address: '서울 종로구 세종대로 175',
    district: '광화문',
    location: const LatLng(37.5716, 126.9769),
    averageDb: 67.8,
    noiseLevel: NoiseLevel.noisy,
    measurementCount: 312,
    distanceKm: 4.5,
    tags: ['넓은 공간', '콘센트 있음', '주말 혼잡', '활기찬'],
    hourlyNoise: _generateHourlyNoise([
      55, 60, 65, 68, 74, 78, 76, 73, 70, 74, 77, 75, 70, 65, 60,
    ]),
    recentMeasurements: [
      RecentMeasurement(
        userName: '강태양',
        db: 70.1,
        noiseLevel: NoiseLevel.noisy,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        comment: '점심 시간엔 너무 붐벼요',
      ),
      RecentMeasurement(
        userName: '윤소희',
        db: 65.5,
        noiseLevel: NoiseLevel.moderate,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// All nearby cafes (mock: returns full list)
final cafesProvider = FutureProvider<List<CafeModel>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 600));
  return _mockCafes;
});

/// Currently selected cafe on the map
class _SelectedCafeNotifier extends Notifier<CafeModel?> {
  @override
  CafeModel? build() => null;

  // ignore: use_setters_to_change_properties
  void set(CafeModel? cafe) => state = cafe;
}

final selectedCafeProvider =
    NotifierProvider<_SelectedCafeNotifier, CafeModel?>(
  _SelectedCafeNotifier.new,
);

/// Cafe detail by ID
final cafeDetailProvider =
    FutureProvider.family<CafeModel?, String>((ref, cafeId) async {
  await Future.delayed(const Duration(milliseconds: 300));
  try {
    return _mockCafes.firstWhere((c) => c.id == cafeId);
  } catch (_) {
    return null;
  }
});

/// Sort order for cafe list
enum CafeSortOrder { distance, quiet, popular }

class _SortOrderNotifier extends Notifier<CafeSortOrder> {
  @override
  CafeSortOrder build() => CafeSortOrder.distance;

  // ignore: use_setters_to_change_properties
  void set(CafeSortOrder order) => state = order;
}

final cafeSortOrderProvider =
    NotifierProvider<_SortOrderNotifier, CafeSortOrder>(
  _SortOrderNotifier.new,
);

/// Sorted cafe list
final sortedCafesProvider = Provider<AsyncValue<List<CafeModel>>>((ref) {
  final cafesAsync = ref.watch(cafesProvider);
  final sortOrder = ref.watch(cafeSortOrderProvider);

  return cafesAsync.whenData((cafes) {
    final sorted = List<CafeModel>.from(cafes);
    switch (sortOrder) {
      case CafeSortOrder.distance:
        sorted.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case CafeSortOrder.quiet:
        sorted.sort((a, b) => a.averageDb.compareTo(b.averageDb));
      case CafeSortOrder.popular:
        sorted.sort(
          (a, b) => b.measurementCount.compareTo(a.measurementCount),
        );
    }
    return sorted;
  });
});
