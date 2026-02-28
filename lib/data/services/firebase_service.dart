import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase 서비스 싱글턴
///
/// Firebase는 main.dart 에서 이미 초기화되었다고 가정합니다.
/// Firestore 인스턴스 및 컬렉션 레퍼런스에 대한 간편한 접근점을 제공합니다.
class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  // ---------------------------------------------------------------------------
  // Firestore instance
  // ---------------------------------------------------------------------------

  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Collection references
  // ---------------------------------------------------------------------------

  /// 카페 컬렉션
  CollectionReference<Map<String, dynamic>> get cafesCollection =>
      firestore.collection('cafes');

  /// 소음 측정 컬렉션
  CollectionReference<Map<String, dynamic>> get measurementsCollection =>
      firestore.collection('measurements');

  /// 사용자 프로필 컬렉션
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  // ---------------------------------------------------------------------------
  // Document references
  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> cafeDoc(String cafeId) =>
      cafesCollection.doc(cafeId);

  DocumentReference<Map<String, dynamic>> measurementDoc(
          String measurementId) =>
      measurementsCollection.doc(measurementId);

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      usersCollection.doc(uid);

  // ---------------------------------------------------------------------------
  // Batch helpers
  // ---------------------------------------------------------------------------

  /// 새 WriteBatch 반환
  WriteBatch get batch => firestore.batch();

  /// [operations]에 전달된 콜백을 트랜잭션 안에서 실행합니다.
  Future<T> runTransaction<T>(
    TransactionHandler<T> updateFunction, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    return firestore.runTransaction<T>(
      updateFunction,
      timeout: timeout,
    );
  }

  // ---------------------------------------------------------------------------
  // Server timestamp helper
  // ---------------------------------------------------------------------------

  /// Firestore 서버 타임스탬프 FieldValue
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  // ---------------------------------------------------------------------------
  // Pagination helpers
  // ---------------------------------------------------------------------------

  /// 쿼리에 페이지네이션 커서를 적용합니다.
  Query<Map<String, dynamic>> paginate(
    Query<Map<String, dynamic>> query, {
    required int pageSize,
    DocumentSnapshot? lastDocument,
  }) {
    Query<Map<String, dynamic>> paginated = query.limit(pageSize);
    if (lastDocument != null) {
      paginated = paginated.startAfterDocument(lastDocument);
    }
    return paginated;
  }
}
