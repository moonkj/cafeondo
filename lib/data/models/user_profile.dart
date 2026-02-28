import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 레벨 (측정 횟수 기반 게이미피케이션)
enum UserLevel {
  /// 0–9 회
  beginner,

  /// 10–49 회
  intermediate,

  /// 50–199 회
  advanced,

  /// 200–999 회
  expert,

  /// 1000+ 회
  grandmaster;

  String get label {
    switch (this) {
      case UserLevel.beginner:
        return '카페 탐험가';
      case UserLevel.intermediate:
        return '소음 감지사';
      case UserLevel.advanced:
        return '카페 고수';
      case UserLevel.expert:
        return '카페 마스터';
      case UserLevel.grandmaster:
        return '카페온도 레전드';
    }
  }

  String get emoji {
    switch (this) {
      case UserLevel.beginner:
        return '☕';
      case UserLevel.intermediate:
        return '🎧';
      case UserLevel.advanced:
        return '🏆';
      case UserLevel.expert:
        return '⭐';
      case UserLevel.grandmaster:
        return '👑';
    }
  }

  int get minMeasurements {
    switch (this) {
      case UserLevel.beginner:
        return 0;
      case UserLevel.intermediate:
        return 10;
      case UserLevel.advanced:
        return 50;
      case UserLevel.expert:
        return 200;
      case UserLevel.grandmaster:
        return 1000;
    }
  }

  int get maxMeasurements {
    switch (this) {
      case UserLevel.beginner:
        return 9;
      case UserLevel.intermediate:
        return 49;
      case UserLevel.advanced:
        return 199;
      case UserLevel.expert:
        return 999;
      case UserLevel.grandmaster:
        return 999999;
    }
  }

  static UserLevel fromMeasurementCount(int count) {
    if (count >= 1000) return UserLevel.grandmaster;
    if (count >= 200) return UserLevel.expert;
    if (count >= 50) return UserLevel.advanced;
    if (count >= 10) return UserLevel.intermediate;
    return UserLevel.beginner;
  }

  static UserLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'intermediate':
        return UserLevel.intermediate;
      case 'advanced':
        return UserLevel.advanced;
      case 'expert':
        return UserLevel.expert;
      case 'grandmaster':
        return UserLevel.grandmaster;
      default:
        return UserLevel.beginner;
    }
  }

  String get key {
    switch (this) {
      case UserLevel.beginner:
        return 'beginner';
      case UserLevel.intermediate:
        return 'intermediate';
      case UserLevel.advanced:
        return 'advanced';
      case UserLevel.expert:
        return 'expert';
      case UserLevel.grandmaster:
        return 'grandmaster';
    }
  }
}

/// 사용자 프로필 모델
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int totalMeasurements;
  final UserLevel level;
  final int points;
  final DateTime? joinedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.totalMeasurements = 0,
    this.level = UserLevel.beginner,
    this.points = 0,
    this.joinedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final measurements =
        (json['totalMeasurements'] as num?)?.toInt() ?? 0;

    return UserProfile(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '카페 탐험가',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      totalMeasurements: measurements,
      level: json['level'] != null
          ? UserLevel.fromString(json['level'] as String)
          : UserLevel.fromMeasurementCount(measurements),
      points: (json['points'] as num?)?.toInt() ?? 0,
      joinedAt: parseTimestamp(json['joinedAt']),
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile.fromJson({...data, 'uid': doc.id});
  }

  /// 신규 사용자 초기 프로필 생성
  factory UserProfile.newUser({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      totalMeasurements: 0,
      level: UserLevel.beginner,
      points: 0,
      joinedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'totalMeasurements': totalMeasurements,
        'level': level.key,
        'points': points,
        'joinedAt':
            joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      };

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('uid'); // Firestore uses doc ID
    return json;
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    int? totalMeasurements,
    UserLevel? level,
    int? points,
    DateTime? joinedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      totalMeasurements: totalMeasurements ?? this.totalMeasurements,
      level: level ?? this.level,
      points: points ?? this.points,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  /// 다음 레벨까지 측정 횟수
  int get measurementsToNextLevel {
    if (level == UserLevel.grandmaster) return 0;
    final allLevels = UserLevel.values;
    final nextLevelIndex = allLevels.indexOf(level) + 1;
    return allLevels[nextLevelIndex].minMeasurements - totalMeasurements;
  }

  /// 현재 레벨 진행도 (0.0 ~ 1.0)
  double get levelProgress {
    if (level == UserLevel.grandmaster) return 1.0;
    final allLevels = UserLevel.values;
    final nextLevelIndex = allLevels.indexOf(level) + 1;
    final nextMin = allLevels[nextLevelIndex].minMeasurements;
    final currentMin = level.minMeasurements;
    final range = nextMin - currentMin;
    if (range <= 0) return 1.0;
    return ((totalMeasurements - currentMin) / range).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserProfile && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'UserProfile(uid: $uid, displayName: $displayName, level: ${level.label})';
}
