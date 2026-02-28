import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Data Models ───────────────────────────────────────────────────────────────

class QuietCafeRankItem {
  final int rank;
  final String cafeId;
  final String cafeName;
  final String address;
  final String district;
  final double averageDb;
  final int measurementCount;
  final String noiseLabel;

  const QuietCafeRankItem({
    required this.rank,
    required this.cafeId,
    required this.cafeName,
    required this.address,
    required this.district,
    required this.averageDb,
    required this.measurementCount,
    required this.noiseLabel,
  });
}

class TopMeasurerItem {
  final int rank;
  final String userId;
  final String displayName;
  final int levelIndex;
  final String levelLabel;
  final String levelEmoji;
  final int totalMeasurements;
  final bool isCurrentUser;

  const TopMeasurerItem({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.levelIndex,
    required this.levelLabel,
    required this.levelEmoji,
    required this.totalMeasurements,
    this.isCurrentUser = false,
  });
}

class ActiveCafeRankItem {
  final int rank;
  final String cafeId;
  final String cafeName;
  final String district;
  final int weeklyMeasurements;
  final bool isTrending;

  const ActiveCafeRankItem({
    required this.rank,
    required this.cafeId,
    required this.cafeName,
    required this.district,
    required this.weeklyMeasurements,
    required this.isTrending,
  });
}

// ── Mock Data ─────────────────────────────────────────────────────────────────

final _mockQuietCafes = [
  const QuietCafeRankItem(
    rank: 1, cafeId: 'c01', cafeName: '북한산 뷰 카페', address: '서울 강북구 우이동',
    district: '우이동', averageDb: 38.4, measurementCount: 34, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 2, cafeId: 'c02', cafeName: '트리하우스 카페', address: '서울 마포구 연남동',
    district: '연남동', averageDb: 41.2, measurementCount: 89, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 3, cafeId: 'c03', cafeName: '블루보틀 성수', address: '서울 성동구 성수동',
    district: '성수동', averageDb: 44.7, measurementCount: 127, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 4, cafeId: 'c04', cafeName: '하루 서재', address: '서울 종로구 통인동',
    district: '통인동', averageDb: 45.1, measurementCount: 61, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 5, cafeId: 'c05', cafeName: '숲속 라운지', address: '경기 고양시 일산서구',
    district: '일산', averageDb: 46.8, measurementCount: 42, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 6, cafeId: 'c06', cafeName: '클래식 도서관 카페', address: '서울 서대문구 연희동',
    district: '연희동', averageDb: 47.3, measurementCount: 55, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 7, cafeId: 'c07', cafeName: '나무 그늘', address: '서울 마포구 합정동',
    district: '합정동', averageDb: 48.0, measurementCount: 73, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 8, cafeId: 'c08', cafeName: '달빛 서재', address: '서울 용산구 해방촌',
    district: '해방촌', averageDb: 48.9, measurementCount: 30, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 9, cafeId: 'c09', cafeName: '모퉁이 커피', address: '서울 동작구 상도동',
    district: '상도동', averageDb: 49.2, measurementCount: 21, noiseLabel: '조용함',
  ),
  const QuietCafeRankItem(
    rank: 10, cafeId: 'c10', cafeName: '온기 커피', address: '서울 은평구 불광동',
    district: '불광동', averageDb: 49.7, measurementCount: 18, noiseLabel: '조용함',
  ),
];

final _mockTopMeasurers = [
  const TopMeasurerItem(
    rank: 1, userId: 'u01', displayName: '이정민',
    levelIndex: 4, levelLabel: '카페온도 레전드', levelEmoji: '👑',
    totalMeasurements: 1247,
  ),
  const TopMeasurerItem(
    rank: 2, userId: 'u02', displayName: '박현우',
    levelIndex: 3, levelLabel: '카페 마스터', levelEmoji: '⭐',
    totalMeasurements: 532,
  ),
  const TopMeasurerItem(
    rank: 3, userId: 'u03', displayName: '김소연',
    levelIndex: 3, levelLabel: '카페 마스터', levelEmoji: '⭐',
    totalMeasurements: 401,
  ),
  const TopMeasurerItem(
    rank: 4, userId: 'u04', displayName: '최준혁',
    levelIndex: 2, levelLabel: '카페 고수', levelEmoji: '🏆',
    totalMeasurements: 178,
  ),
  const TopMeasurerItem(
    rank: 5, userId: 'u05', displayName: '정유나',
    levelIndex: 2, levelLabel: '카페 고수', levelEmoji: '🏆',
    totalMeasurements: 142,
  ),
  const TopMeasurerItem(
    rank: 6, userId: 'u06', displayName: '한도윤',
    levelIndex: 2, levelLabel: '카페 고수', levelEmoji: '🏆',
    totalMeasurements: 98,
  ),
  const TopMeasurerItem(
    rank: 7, userId: 'u07', displayName: '오채원',
    levelIndex: 1, levelLabel: '소음 감지사', levelEmoji: '🎧',
    totalMeasurements: 47,
  ),
  const TopMeasurerItem(
    rank: 8, userId: 'u08', displayName: '임지훈',
    levelIndex: 1, levelLabel: '소음 감지사', levelEmoji: '🎧',
    totalMeasurements: 32,
  ),
  const TopMeasurerItem(
    rank: 9, userId: 'u09', displayName: '카페 탐험가',
    levelIndex: 0, levelLabel: '카페 탐험가', levelEmoji: '☕',
    totalMeasurements: 5,
    isCurrentUser: true,
  ),
  const TopMeasurerItem(
    rank: 10, userId: 'u10', displayName: '강민서',
    levelIndex: 0, levelLabel: '카페 탐험가', levelEmoji: '☕',
    totalMeasurements: 3,
  ),
];

final _mockActiveCafes = [
  const ActiveCafeRankItem(
    rank: 1, cafeId: 'c06', cafeName: '스타벅스 광화문점', district: '광화문',
    weeklyMeasurements: 48, isTrending: true,
  ),
  const ActiveCafeRankItem(
    rank: 2, cafeId: 'c02', cafeName: '어니언 성수', district: '성수동',
    weeklyMeasurements: 35, isTrending: true,
  ),
  const ActiveCafeRankItem(
    rank: 3, cafeId: 'c03', cafeName: '블루보틀 성수', district: '성수동',
    weeklyMeasurements: 27, isTrending: false,
  ),
  const ActiveCafeRankItem(
    rank: 4, cafeId: 'c04', cafeName: '알베르 카페', district: '청담동',
    weeklyMeasurements: 22, isTrending: true,
  ),
  const ActiveCafeRankItem(
    rank: 5, cafeId: 'c05', cafeName: '트리하우스 카페', district: '연남동',
    weeklyMeasurements: 18, isTrending: false,
  ),
  const ActiveCafeRankItem(
    rank: 6, cafeId: 'c07', cafeName: '폴바셋 강남점', district: '강남구',
    weeklyMeasurements: 16, isTrending: true,
  ),
  const ActiveCafeRankItem(
    rank: 7, cafeId: 'c08', cafeName: '하루 서재', district: '통인동',
    weeklyMeasurements: 13, isTrending: false,
  ),
  const ActiveCafeRankItem(
    rank: 8, cafeId: 'c09', cafeName: '나무 그늘', district: '합정동',
    weeklyMeasurements: 10, isTrending: false,
  ),
  const ActiveCafeRankItem(
    rank: 9, cafeId: 'c10', cafeName: '달빛 서재', district: '해방촌',
    weeklyMeasurements: 9, isTrending: true,
  ),
  const ActiveCafeRankItem(
    rank: 10, cafeId: 'c11', cafeName: '클래식 도서관 카페', district: '연희동',
    weeklyMeasurements: 7, isTrending: false,
  ),
];

// ── Selected Tab Provider ─────────────────────────────────────────────────────

final rankingSelectedTabProvider = StateProvider<int>((ref) => 0);

// ── FutureProviders ───────────────────────────────────────────────────────────

final quietCafesRankingProvider =
    FutureProvider<List<QuietCafeRankItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return _mockQuietCafes;
});

final topMeasurersRankingProvider =
    FutureProvider<List<TopMeasurerItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return _mockTopMeasurers;
});

final activeCafesRankingProvider =
    FutureProvider<List<ActiveCafeRankItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return _mockActiveCafes;
});
