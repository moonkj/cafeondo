import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/firebase_service.dart';

/// 사용자 레포지토리
///
/// Firestore 'users' 컬렉션에서 사용자 프로필을 관리합니다.
/// 측정 횟수 기반의 레벨 및 포인트 시스템을 처리합니다.
class UserRepository {
  UserRepository({FirebaseService? firebaseService})
      : _firebase = firebaseService ?? FirebaseService.instance;

  final FirebaseService _firebase;

  // ---------------------------------------------------------------------------
  // 프로필 조회
  // ---------------------------------------------------------------------------

  /// UID로 사용자 프로필을 가져옵니다. 문서가 없으면 null.
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firebase.userDoc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      throw UserRepositoryException(
        '사용자 프로필을 불러오는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  /// 사용자 프로필 실시간 스트림
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firebase.userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  // ---------------------------------------------------------------------------
  // 프로필 생성 / 업데이트
  // ---------------------------------------------------------------------------

  /// Firebase Auth 사용자로부터 Firestore 프로필을 생성하거나 업데이트합니다.
  ///
  /// 이미 존재하는 경우 표시 이름과 사진 URL만 업데이트합니다 (점수 유지).
  Future<UserProfile> createOrUpdateProfile(User firebaseUser) async {
    try {
      final docRef = _firebase.userDoc(firebaseUser.uid);
      final existing = await docRef.get();

      if (existing.exists) {
        // 기존 사용자: 인증 정보만 갱신
        await docRef.update({
          'displayName': firebaseUser.displayName ?? '카페 탐험가',
          if (firebaseUser.photoURL != null)
            'photoUrl': firebaseUser.photoURL,
          'updatedAt': _firebase.serverTimestamp,
        });

        final updated = await docRef.get();
        return UserProfile.fromFirestore(updated);
      } else {
        // 신규 사용자: 초기 프로필 생성
        final newProfile = UserProfile.newUser(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? '카페 탐험가',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL,
        );

        final data = newProfile.toFirestore()
          ..['createdAt'] = _firebase.serverTimestamp
          ..['updatedAt'] = _firebase.serverTimestamp;

        await docRef.set(data);
        return newProfile;
      }
    } catch (e) {
      throw UserRepositoryException(
        '사용자 프로필을 생성/업데이트하는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  /// 사용자 프로필 필드를 부분적으로 업데이트합니다.
  Future<void> updateProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firebase.userDoc(uid).update({
        ...updates,
        'updatedAt': _firebase.serverTimestamp,
      });
    } catch (e) {
      throw UserRepositoryException(
        '사용자 프로필을 업데이트하는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 측정 횟수 및 레벨 업데이트
  // ---------------------------------------------------------------------------

  /// 새 측정 완료 시 사용자의 측정 횟수, 포인트, 레벨을 원자적으로 업데이트합니다.
  ///
  /// 반환값: 레벨업 여부
  Future<LevelUpResult> incrementMeasurementCount(String uid) async {
    try {
      final docRef = _firebase.userDoc(uid);

      return await _firebase.runTransaction((transaction) async {
        final snap = await transaction.get(docRef);

        if (!snap.exists) {
          // 프로필이 없으면 업데이트 스킵
          return LevelUpResult(leveledUp: false, newLevel: UserLevel.beginner);
        }

        final data = snap.data() ?? {};
        final currentCount =
            (data['totalMeasurements'] as num?)?.toInt() ?? 0;
        final currentLevelStr = data['level'] as String? ?? 'beginner';
        final currentLevel = UserLevel.fromString(currentLevelStr);
        final currentPoints = (data['points'] as num?)?.toInt() ?? 0;

        final newCount = currentCount + 1;
        final newLevel = UserLevel.fromMeasurementCount(newCount);
        final pointsEarned = _calculatePointsForMeasurement(newCount);
        final newPoints = currentPoints + pointsEarned;
        final didLevelUp = newLevel != currentLevel;

        transaction.update(docRef, {
          'totalMeasurements': newCount,
          'level': newLevel.key,
          'points': newPoints,
          'updatedAt': _firebase.serverTimestamp,
        });

        return LevelUpResult(
          leveledUp: didLevelUp,
          newLevel: newLevel,
          previousLevel: didLevelUp ? currentLevel : null,
          pointsEarned: pointsEarned,
        );
      });
    } catch (e) {
      throw UserRepositoryException(
        '측정 횟수를 업데이트하는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 레벨 진행도 계산
  // ---------------------------------------------------------------------------

  /// 사용자의 현재 레벨 진행도 정보를 반환합니다.
  Future<LevelProgressInfo?> getLevelProgress(String uid) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile == null) return null;

      return LevelProgressInfo.fromProfile(profile);
    } catch (e) {
      throw UserRepositoryException(
        '레벨 진행도를 불러오는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 계정 삭제
  // ---------------------------------------------------------------------------

  /// Firestore에서 사용자 프로필 문서를 삭제합니다.
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firebase.userDoc(uid).delete();
    } catch (e) {
      throw UserRepositoryException(
        '사용자 프로필을 삭제하는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 내부: 포인트 계산
  // ---------------------------------------------------------------------------

  int _calculatePointsForMeasurement(int measurementCount) {
    // 레벨이 높을수록 더 많은 포인트 획득
    if (measurementCount >= 1000) return 50; // grandmaster
    if (measurementCount >= 200) return 30;  // expert
    if (measurementCount >= 50) return 20;   // advanced
    if (measurementCount >= 10) return 15;   // intermediate
    return 10;                                // beginner
  }
}

// ---------------------------------------------------------------------------
// 보조 데이터 클래스
// ---------------------------------------------------------------------------

/// 레벨업 결과
class LevelUpResult {
  final bool leveledUp;
  final UserLevel newLevel;
  final UserLevel? previousLevel;
  final int pointsEarned;

  const LevelUpResult({
    required this.leveledUp,
    required this.newLevel,
    this.previousLevel,
    this.pointsEarned = 0,
  });
}

/// 레벨 진행도 정보
class LevelProgressInfo {
  final UserLevel currentLevel;
  final int totalMeasurements;
  final double progress; // 0.0 ~ 1.0
  final int measurementsToNextLevel;
  final int points;

  const LevelProgressInfo({
    required this.currentLevel,
    required this.totalMeasurements,
    required this.progress,
    required this.measurementsToNextLevel,
    required this.points,
  });

  factory LevelProgressInfo.fromProfile(UserProfile profile) {
    return LevelProgressInfo(
      currentLevel: profile.level,
      totalMeasurements: profile.totalMeasurements,
      progress: profile.levelProgress,
      measurementsToNextLevel: profile.measurementsToNextLevel,
      points: profile.points,
    );
  }
}

// ---------------------------------------------------------------------------
// 예외 클래스
// ---------------------------------------------------------------------------

class UserRepositoryException implements Exception {
  final String message;
  final Object? error;

  const UserRepositoryException(this.message, {this.error});

  @override
  String toString() => 'UserRepositoryException: $message';
}

// ---------------------------------------------------------------------------
// Riverpod 프로바이더
// ---------------------------------------------------------------------------

/// [UserRepository] 프로바이더
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// 현재 사용자 프로필 실시간 스트림 (uid 필요)
final userProfileStreamProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).getUserProfileStream(uid);
});
