import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cafe.dart';
import '../services/firebase_service.dart';

/// 카페 데이터 레포지토리
///
/// Firestore 'cafes' 컬렉션과 상호작용합니다.
class CafeRepository {
  CafeRepository({FirebaseService? firebaseService})
      : _firebase = firebaseService ?? FirebaseService.instance;

  final FirebaseService _firebase;

  // ---------------------------------------------------------------------------
  // 근처 카페 조회 (Bounding Box)
  // ---------------------------------------------------------------------------

  /// 주어진 위경도 반경 내 카페를 가져옵니다.
  ///
  /// Firestore는 GeoPoint 범위 쿼리를 한 축만 지원하므로,
  /// 위도 범위로 1차 필터링 후 클라이언트에서 경도 범위를 적용합니다.
  ///
  /// [radiusKm] 기본 반경: 2km
  Future<List<Cafe>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 2.0,
  }) async {
    try {
      // 위도 1도 ≈ 111km
      final latDelta = radiusKm / 111.0;
      // 경도 1도의 km는 위도에 따라 다름
      final lngDelta = radiusKm / (111.0 * _cosLatitude(latitude));

      final minLat = latitude - latDelta;
      final maxLat = latitude + latDelta;
      final minLng = longitude - lngDelta;
      final maxLng = longitude + lngDelta;

      final snapshot = await _firebase.cafesCollection
          .where('latitude', isGreaterThanOrEqualTo: minLat)
          .where('latitude', isLessThanOrEqualTo: maxLat)
          .orderBy('latitude')
          .get();

      return snapshot.docs
          .map((doc) => Cafe.fromFirestore(doc))
          .where((cafe) =>
              cafe.longitude >= minLng && cafe.longitude <= maxLng)
          .toList();
    } catch (e) {
      throw CafeRepositoryException('근처 카페를 불러오는 중 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 단일 카페 조회
  // ---------------------------------------------------------------------------

  /// ID로 카페를 가져옵니다.
  Future<Cafe?> getCafeById(String cafeId) async {
    try {
      final doc = await _firebase.cafeDoc(cafeId).get();
      if (!doc.exists) return null;
      return Cafe.fromFirestore(doc);
    } catch (e) {
      throw CafeRepositoryException('카페 정보를 불러오는 중 오류가 발생했습니다.', error: e);
    }
  }

  /// ID로 카페 실시간 스트림을 반환합니다.
  Stream<Cafe?> getCafeStream(String cafeId) {
    return _firebase.cafeDoc(cafeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Cafe.fromFirestore(doc);
    });
  }

  // ---------------------------------------------------------------------------
  // 검색
  // ---------------------------------------------------------------------------

  /// 이름으로 카페를 검색합니다 (prefix match).
  ///
  /// Firestore는 전문 검색(full-text search)을 지원하지 않으므로
  /// 이름의 시작 문자열을 기준으로 필터링합니다.
  Future<List<Cafe>> searchCafesByName(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final normalizedQuery = query.trim();
      // Firestore prefix match 기법: 마지막 문자를 유니코드 최대값으로 치환
      final endQuery =
          normalizedQuery.substring(0, normalizedQuery.length - 1) +
              String.fromCharCode(
                  normalizedQuery.codeUnitAt(normalizedQuery.length - 1) + 1);

      final snapshot = await _firebase.cafesCollection
          .where('name', isGreaterThanOrEqualTo: normalizedQuery)
          .where('name', isLessThan: endQuery)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => Cafe.fromFirestore(doc)).toList();
    } catch (e) {
      throw CafeRepositoryException('카페를 검색하는 중 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 인기 카페 (측정 횟수 기준)
  // ---------------------------------------------------------------------------

  /// 측정 횟수가 많은 상위 카페를 가져옵니다.
  Future<List<Cafe>> getTopRatedCafes({int limit = 10}) async {
    try {
      final snapshot = await _firebase.cafesCollection
          .orderBy('totalMeasurements', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Cafe.fromFirestore(doc)).toList();
    } catch (e) {
      throw CafeRepositoryException('인기 카페를 불러오는 중 오류가 발생했습니다.', error: e);
    }
  }

  /// 가장 조용한 카페를 가져옵니다.
  Future<List<Cafe>> getQuietestCafes({int limit = 10}) async {
    try {
      final snapshot = await _firebase.cafesCollection
          .where('totalMeasurements', isGreaterThan: 0)
          .orderBy('totalMeasurements')
          .orderBy('averageNoiseLevel')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Cafe.fromFirestore(doc)).toList();
    } catch (e) {
      throw CafeRepositoryException('조용한 카페를 불러오는 중 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 카페 추가 / 수정
  // ---------------------------------------------------------------------------

  /// 새 카페를 Firestore에 추가합니다.
  /// 성공 시 생성된 카페 ID를 반환합니다.
  Future<String> addCafe(Cafe cafe) async {
    try {
      final data = cafe.toFirestore()
        ..['createdAt'] = _firebase.serverTimestamp
        ..['updatedAt'] = _firebase.serverTimestamp;

      // ID가 비어 있으면 자동 생성
      if (cafe.id.isEmpty) {
        final docRef = await _firebase.cafesCollection.add(data);
        return docRef.id;
      } else {
        await _firebase.cafeDoc(cafe.id).set(data);
        return cafe.id;
      }
    } catch (e) {
      throw CafeRepositoryException('카페를 추가하는 중 오류가 발생했습니다.', error: e);
    }
  }

  /// 카페 정보를 업데이트합니다. (부분 업데이트)
  Future<void> updateCafe(String cafeId, Map<String, dynamic> updates) async {
    try {
      await _firebase.cafeDoc(cafeId).update({
        ...updates,
        'updatedAt': _firebase.serverTimestamp,
      });
    } catch (e) {
      throw CafeRepositoryException('카페 정보를 업데이트하는 중 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 내부 유틸리티
  // ---------------------------------------------------------------------------

  double _cosLatitude(double latitude) {
    // cos(latitude in radians) 근사
    const piOver180 = 3.141592653589793 / 180.0;
    final rad = latitude * piOver180;
    return _cos(rad);
  }

  double _cos(double x) {
    // dart:math 사용 없이 간단히 처리 (import 최소화)
    // 실제로는 dart:math의 cos를 사용해도 무방
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// 예외 클래스
// ---------------------------------------------------------------------------

class CafeRepositoryException implements Exception {
  final String message;
  final Object? error;

  const CafeRepositoryException(this.message, {this.error});

  @override
  String toString() => 'CafeRepositoryException: $message';
}

// ---------------------------------------------------------------------------
// Riverpod 프로바이더
// ---------------------------------------------------------------------------

/// [CafeRepository] 프로바이더
final cafeRepositoryProvider = Provider<CafeRepository>((ref) {
  return CafeRepository();
});

/// ID로 카페 상세 정보를 가져오는 FutureProvider.family
final cafeByIdProvider =
    FutureProvider.family<Cafe?, String>((ref, cafeId) async {
  return ref.watch(cafeRepositoryProvider).getCafeById(cafeId);
});

/// 인기 카페 목록 프로바이더
final topCafesProvider = FutureProvider<List<Cafe>>((ref) async {
  return ref.watch(cafeRepositoryProvider).getTopRatedCafes();
});
