import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cafe.dart';
import '../models/measurement.dart';
import '../services/firebase_service.dart';

/// 소음 측정 레포지토리
///
/// Firestore 'measurements' 컬렉션과 상호작용하며,
/// 새 측정이 저장될 때 해당 카페의 집계 통계도 원자적으로 업데이트합니다.
class MeasurementRepository {
  MeasurementRepository({FirebaseService? firebaseService})
      : _firebase = firebaseService ?? FirebaseService.instance;

  final FirebaseService _firebase;

  // ---------------------------------------------------------------------------
  // 측정 저장
  // ---------------------------------------------------------------------------

  /// 새 측정 결과를 Firestore에 저장하고, 카페 통계를 업데이트합니다.
  ///
  /// 반환값: 생성된 측정 문서 ID
  Future<String> saveMeasurement(Measurement measurement) async {
    try {
      // 1. 측정 문서 저장
      final data = measurement.toFirestore()
        ..['createdAt'] = _firebase.serverTimestamp;

      late final String measurementId;

      if (measurement.id.isEmpty) {
        final docRef =
            await _firebase.measurementsCollection.add(data);
        measurementId = docRef.id;
      } else {
        await _firebase.measurementDoc(measurement.id).set(data);
        measurementId = measurement.id;
      }

      // 2. 카페 집계 통계 업데이트 (트랜잭션)
      await _updateCafeAggregates(
        cafeId: measurement.cafeId,
        newMeasurementId: measurementId,
        newDecibels: measurement.decibelLevel,
        newCategory: measurement.noiseCategory,
        timestamp: measurement.timestamp,
      );

      return measurementId;
    } catch (e) {
      throw MeasurementRepositoryException(
        '측정 결과를 저장하는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 카페별 측정 조회
  // ---------------------------------------------------------------------------

  /// 특정 카페의 최근 측정 목록을 가져옵니다.
  Future<List<Measurement>> getMeasurementsForCafe(
    String cafeId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.measurementsCollection
          .where('cafeId', isEqualTo: cafeId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Measurement.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw MeasurementRepositoryException(
        '카페 측정 데이터를 불러오는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  /// 특정 카페의 측정 목록 실시간 스트림
  Stream<List<Measurement>> getMeasurementsStreamForCafe(
    String cafeId, {
    int limit = 10,
  }) {
    return _firebase.measurementsCollection
        .where('cafeId', isEqualTo: cafeId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Measurement.fromFirestore(doc))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // 사용자별 측정 조회
  // ---------------------------------------------------------------------------

  /// 특정 사용자의 측정 이력을 가져옵니다.
  Future<List<Measurement>> getUserMeasurements(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firebase.measurementsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Measurement.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw MeasurementRepositoryException(
        '사용자 측정 이력을 불러오는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 카페 평균 계산
  // ---------------------------------------------------------------------------

  /// 저장된 측정 데이터를 기반으로 카페 평균 소음을 계산합니다.
  Future<double> calculateCafeAverage(String cafeId) async {
    try {
      final snapshot = await _firebase.measurementsCollection
          .where('cafeId', isEqualTo: cafeId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['decibelLevel'] as num?)?.toDouble() ?? 0.0;
      }

      return total / snapshot.docs.length;
    } catch (e) {
      throw MeasurementRepositoryException(
        '카페 평균 소음을 계산하는 중 오류가 발생했습니다.',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 내부: 카페 집계 통계 원자적 업데이트
  // ---------------------------------------------------------------------------

  Future<void> _updateCafeAggregates({
    required String cafeId,
    required String newMeasurementId,
    required double newDecibels,
    required NoiseCategory newCategory,
    required DateTime timestamp,
  }) async {
    final cafeRef = _firebase.cafeDoc(cafeId);

    await _firebase.runTransaction((transaction) async {
      final cafeSnap = await transaction.get(cafeRef);

      if (!cafeSnap.exists) {
        // 카페가 없으면 통계만 업데이트할 수 없으므로 스킵
        return;
      }

      final data = cafeSnap.data() ?? {};
      final currentTotal = (data['totalMeasurements'] as num?)?.toInt() ?? 0;
      final currentAvg =
          (data['averageNoiseLevel'] as num?)?.toDouble() ?? 0.0;

      // 점진적 평균 계산: newAvg = (oldAvg * n + newVal) / (n + 1)
      final newTotal = currentTotal + 1;
      final newAvg =
          (currentAvg * currentTotal + newDecibels) / newTotal;
      final newNoiseCategoryStr =
          NoiseCategory.fromDecibels(newAvg).englishKey;

      // recentMeasurements 리스트 유지 (최대 5개)
      final recentList = List<Map<String, dynamic>>.from(
        (data['recentMeasurements'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>) ??
            [],
      );

      recentList.insert(0, {
        'measurementId': newMeasurementId,
        'decibelLevel': newDecibels,
        'noiseCategory': newCategory.englishKey,
        'timestamp': Timestamp.fromDate(timestamp),
      });

      if (recentList.length > 5) {
        recentList.removeRange(5, recentList.length);
      }

      transaction.update(cafeRef, {
        'totalMeasurements': newTotal,
        'averageNoiseLevel': newAvg,
        'noiseCategory': newNoiseCategoryStr,
        'recentMeasurements': recentList,
        'updatedAt': _firebase.serverTimestamp,
      });
    });
  }
}

// ---------------------------------------------------------------------------
// 예외 클래스
// ---------------------------------------------------------------------------

class MeasurementRepositoryException implements Exception {
  final String message;
  final Object? error;

  const MeasurementRepositoryException(this.message, {this.error});

  @override
  String toString() => 'MeasurementRepositoryException: $message';
}

// ---------------------------------------------------------------------------
// Riverpod 프로바이더
// ---------------------------------------------------------------------------

/// [MeasurementRepository] 프로바이더
final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepository();
});

/// 특정 카페의 최근 측정 목록 스트림 프로바이더
final cafeMeasurementsStreamProvider =
    StreamProvider.family<List<Measurement>, String>((ref, cafeId) {
  return ref
      .watch(measurementRepositoryProvider)
      .getMeasurementsStreamForCafe(cafeId);
});
