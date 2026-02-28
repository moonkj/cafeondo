import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// 알림 카테고리
// ---------------------------------------------------------------------------

/// 앱에서 사용하는 알림 카테고리.
enum NotificationCategory {
  /// 측정 리마인더
  measurementReminder,

  /// 랭킹 업데이트
  rankingUpdate,

  /// 새 카페 등록
  newCafe,

  /// 프로모션/이벤트
  promotion;

  String get displayName {
    switch (this) {
      case NotificationCategory.measurementReminder:
        return '측정 리마인더';
      case NotificationCategory.rankingUpdate:
        return '랭킹 업데이트';
      case NotificationCategory.newCafe:
        return '새 카페';
      case NotificationCategory.promotion:
        return '프로모션';
    }
  }
}

// ---------------------------------------------------------------------------
// FCM 토픽 상수
// ---------------------------------------------------------------------------

abstract class FcmTopics {
  FcmTopics._();

  /// 전체 사용자 대상 공지
  static const String allUsers = 'all_users';

  /// 프리미엄 사용자 전용
  static const String premiumUsers = 'premium_users';

  /// 주간 랭킹 알림
  static const String weeklyRanking = 'weekly_ranking';
}

// ---------------------------------------------------------------------------
// 수신된 알림 데이터 모델
// ---------------------------------------------------------------------------

class AppNotification {
  final String title;
  final String body;
  final NotificationCategory? category;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  AppNotification({
    required this.title,
    required this.body,
    this.category,
    required this.data,
    required this.receivedAt,
  });

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final categoryStr = message.data['category'] as String?;
    NotificationCategory? category;
    if (categoryStr != null) {
      try {
        category = NotificationCategory.values
            .firstWhere((e) => e.name == categoryStr);
      } catch (_) {
        category = null;
      }
    }

    return AppNotification(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      category: category,
      data: Map<String, dynamic>.from(message.data),
      receivedAt: DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// 백그라운드 메시지 핸들러 (최상위 함수 필수)
// ---------------------------------------------------------------------------

/// 앱이 백그라운드 또는 종료 상태일 때 FCM 메시지를 처리합니다.
/// 이 함수는 반드시 최상위(top-level) 함수여야 합니다.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM Background] 제목: ${message.notification?.title}, '
    '데이터: ${message.data}',
  );
  // 백그라운드에서는 UI 업데이트 불가. 필요시 local notification 라이브러리 추가 후 처리.
}

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------

/// Firebase Cloud Messaging(FCM) 기반 푸시 알림 서비스.
///
/// 초기화 흐름:
/// 1. [initialize] 호출
/// 2. iOS 권한 요청
/// 3. FCM 토큰 획득 → Firestore 저장
/// 4. 포그라운드/백그라운드/종료 상태 핸들러 등록
/// 5. 토픽 구독
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 포그라운드 알림 스트림 (UI에서 토스트/스낵바 표시용)
  final StreamController<AppNotification> _foregroundNotificationController =
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get foregroundNotifications =>
      _foregroundNotificationController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ── 초기화 ──────────────────────────────────────────────────────────────

  Future<void> initialize({String? userId}) async {
    // 백그라운드 핸들러 등록 (최상위 함수)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // iOS 권한 요청
    await _requestPermission();

    // FCM 토큰 획득 및 저장
    await _setupToken(userId: userId);

    // 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드에서 알림 탭하여 앱 열기 핸들러
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 앱 종료 상태에서 알림 탭하여 앱 실행 확인
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] 종료 상태에서 알림으로 앱 실행: ${initialMessage.data}');
      _handleNotificationTap(initialMessage);
    }

    // 기본 토픽 구독
    await subscribeToDefaultTopics();

    debugPrint('[NotificationService] 초기화 완료. 토큰: $_fcmToken');
  }

  // ── 권한 요청 (iOS) ─────────────────────────────────────────────────────

  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] 알림 권한 상태: ${settings.authorizationStatus.name}');
    return settings;
  }

  Future<NotificationSettings> getNotificationSettings() async {
    return await _messaging.getNotificationSettings();
  }

  // ── FCM 토큰 ────────────────────────────────────────────────────────────

  Future<void> _setupToken({String? userId}) async {
    _fcmToken = await _messaging.getToken();

    if (_fcmToken != null && userId != null) {
      await saveTokenToFirestore(userId: userId, token: _fcmToken!);
    }

    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      debugPrint('[FCM] 토큰 갱신: $newToken');
      if (userId != null) {
        await saveTokenToFirestore(userId: userId, token: newToken);
      }
    });
  }

  /// FCM 토큰을 Firestore 사용자 문서에 저장합니다.
  ///
  /// 문서 경로: users/{userId}
  /// 필드: fcmToken (문자열), fcmTokenUpdatedAt (타임스탬프)
  Future<void> saveTokenToFirestore({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('[FCM] 토큰 Firestore 저장 완료');
    } catch (e) {
      debugPrint('[FCM] 토큰 저장 실패: $e');
    }
  }

  // ── 포그라운드 알림 처리 ──────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      '[FCM Foreground] 제목: ${message.notification?.title}, '
      '내용: ${message.notification?.body}',
    );

    if (message.notification == null) return;

    final notification = AppNotification.fromRemoteMessage(message);
    _foregroundNotificationController.add(notification);
  }

  // ── 알림 탭 핸들러 ─────────────────────────────────────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] 알림 탭: ${message.data}');
    // TODO: 알림 데이터의 'route' 필드를 기반으로 GoRouter 네비게이션 추가.
    // 예: GoRouter.of(context).push(message.data['route']);
  }

  // ── 토픽 구독 ──────────────────────────────────────────────────────────

  /// 기본 토픽(all_users, weekly_ranking)을 구독합니다.
  Future<void> subscribeToDefaultTopics() async {
    await subscribeToTopic(FcmTopics.allUsers);
    await subscribeToTopic(FcmTopics.weeklyRanking);
  }

  /// 특정 토픽을 구독합니다.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCM] 토픽 구독: $topic');
    } catch (e) {
      debugPrint('[FCM] 토픽 구독 실패 ($topic): $e');
    }
  }

  /// 특정 토픽 구독을 해제합니다.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] 토픽 구독 해제: $topic');
    } catch (e) {
      debugPrint('[FCM] 토픽 구독 해제 실패 ($topic): $e');
    }
  }

  /// 프리미엄 토픽 구독 (구독 전환 시 호출)
  Future<void> subscribePremiumTopic() async {
    await subscribeToTopic(FcmTopics.premiumUsers);
  }

  /// 프리미엄 토픽 구독 해제 (구독 취소 시 호출)
  Future<void> unsubscribePremiumTopic() async {
    await unsubscribeFromTopic(FcmTopics.premiumUsers);
  }

  // ── 해제 ────────────────────────────────────────────────────────────────

  void dispose() {
    _foregroundNotificationController.close();
  }
}

// ---------------------------------------------------------------------------
// Riverpod 프로바이더
// ---------------------------------------------------------------------------

/// [NotificationService] 프로바이더.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService.instance;
  ref.onDispose(service.dispose);
  return service;
});

/// 포그라운드 알림 스트림 프로바이더.
/// UI 레이어에서 스낵바/토스트를 표시할 때 사용합니다.
final foregroundNotificationProvider =
    StreamProvider<AppNotification>((ref) {
  return ref.watch(notificationServiceProvider).foregroundNotifications;
});
