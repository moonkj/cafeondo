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

  // Firebase 초기화
  await Firebase.initializeApp();

  // Google Mobile Ads SDK 초기화
  await AdService.instance.initialize();

  // FCM 푸시 알림 초기화
  await NotificationService.instance.initialize();

  // 앱 실행 (ProviderScope으로 Riverpod 활성화)
  runApp(
    const ProviderScope(
      child: CafeOndoApp(),
    ),
  );
}
