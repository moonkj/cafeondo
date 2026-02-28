import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cafeondo/data/models/user_profile.dart';

// ── Measurement Record (local model) ─────────────────────────────────────────

class MeasurementRecord {
  final String id;
  final String cafeName;
  final String cafeAddress;
  final double db;
  final DateTime timestamp;

  const MeasurementRecord({
    required this.id,
    required this.cafeName,
    required this.cafeAddress,
    required this.db,
    required this.timestamp,
  });
}

// ── Badge Model ───────────────────────────────────────────────────────────────

class UserBadge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final bool isEarned;

  const UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.isEarned,
  });
}

// ── Profile State ─────────────────────────────────────────────────────────────

class ProfileState {
  final UserProfile? userProfile;
  final List<MeasurementRecord> recentMeasurements;
  final List<UserBadge> badges;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.userProfile,
    this.recentMeasurements = const [],
    this.badges = const [],
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => userProfile != null;

  ProfileState copyWith({
    UserProfile? userProfile,
    List<MeasurementRecord>? recentMeasurements,
    List<UserBadge>? badges,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      userProfile: userProfile ?? this.userProfile,
      recentMeasurements: recentMeasurements ?? this.recentMeasurements,
      badges: badges ?? this.badges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Mock Data ─────────────────────────────────────────────────────────────────

final _mockMeasurements = [
  MeasurementRecord(
    id: 'm_001',
    cafeName: '블루보틀 성수',
    cafeAddress: '서울 성동구 성수동',
    db: 46.2,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  MeasurementRecord(
    id: 'm_002',
    cafeName: '트리하우스 카페',
    cafeAddress: '서울 마포구 연남동',
    db: 42.5,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
  ),
  MeasurementRecord(
    id: 'm_003',
    cafeName: '어니언 성수',
    cafeAddress: '서울 성동구 성수동',
    db: 63.1,
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
  ),
  MeasurementRecord(
    id: 'm_004',
    cafeName: '북한산 뷰 카페',
    cafeAddress: '서울 강북구 우이동',
    db: 39.8,
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
  ),
  MeasurementRecord(
    id: 'm_005',
    cafeName: '스타벅스 광화문점',
    cafeAddress: '서울 종로구 광화문',
    db: 70.1,
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

final _mockBadges = const [
  UserBadge(
    id: 'b_001',
    name: '첫 측정',
    description: '처음으로 소음을 측정했어요',
    emoji: '🎤',
    isEarned: true,
  ),
  UserBadge(
    id: 'b_002',
    name: '조용한 발견자',
    description: '조용한 카페 3곳을 측정했어요',
    emoji: '🔇',
    isEarned: true,
  ),
  UserBadge(
    id: 'b_003',
    name: '측정 5회',
    description: '총 5회 소음을 측정했어요',
    emoji: '⭐',
    isEarned: true,
  ),
  UserBadge(
    id: 'b_004',
    name: '카페 탐험가',
    description: '서로 다른 카페 5곳을 측정했어요',
    emoji: '🗺️',
    isEarned: false,
  ),
  UserBadge(
    id: 'b_005',
    name: '소음 감지사',
    description: '총 10회 소음을 측정했어요',
    emoji: '🎧',
    isEarned: false,
  ),
  UserBadge(
    id: 'b_006',
    name: '지역 전문가',
    description: '같은 지역에서 10회 측정했어요',
    emoji: '📍',
    isEarned: false,
  ),
];

// ── Profile ViewModel ─────────────────────────────────────────────────────────

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    _loadProfile();
    return const ProfileState(isLoading: true);
  }

  Future<void> _loadProfile() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!ref.mounted) return;

    // 목 유저 프로필 (실제 구현에서는 FirebaseAuth + Firestore 연동)
    final mockProfile = UserProfile(
      uid: 'user_mock_001',
      displayName: '카페 탐험가',
      email: 'user@example.com',
      totalMeasurements: 5,
      level: UserLevel.beginner,
      points: 320,
      joinedAt: DateTime.now().subtract(const Duration(days: 14)),
    );

    state = state.copyWith(
      isLoading: false,
      userProfile: mockProfile,
      recentMeasurements: _mockMeasurements,
      badges: _mockBadges,
    );
  }

  Future<void> refresh() => _loadProfile();

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));
    // 실제 구현: FirebaseAuth.instance.signOut()
    state = const ProfileState();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final profileProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(
  ProfileViewModel.new,
);

/// 등록 카페 수 (mock)
final registeredCafesCountProvider = Provider<int>((ref) => 2);
