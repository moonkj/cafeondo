import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/ad_service.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // 화면 방향 고정 (세로)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase 초기화 (필수 - UI 표시 전 완료 필요)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[main] Firebase 초기화 실패: $e');
  }

  // 앱 실행 - UI를 먼저 표시 (흰 화면 방지)
  runApp(
    const ProviderScope(
      child: CafeOndoApp(),
    ),
  );

  // 비필수 서비스는 UI 표시 후 백그라운드에서 초기화
  // (runApp 이후이므로 알림 권한 다이얼로그가 앱 위에 표시됨)
  AdService.instance.initialize().catchError((e) {
    debugPrint('[main] AdService 초기화 실패 (무시): $e');
  });
  NotificationService.instance.initialize().catchError((e) {
    debugPrint('[main] NotificationService 초기화 실패 (무시): $e');
  });
}
