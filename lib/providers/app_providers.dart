import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/services/firebase_service.dart';
import '../data/services/location_service.dart';
import '../data/services/noise_service.dart';

// ---------------------------------------------------------------------------
// 서비스 프로바이더
// ---------------------------------------------------------------------------

/// [FirebaseService] 싱글턴 프로바이더
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

/// [LocationService] 프로바이더
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// [MockNoiseService] 프로바이더
///
/// 실제 noise_meter 구현으로 교체할 때는 이 프로바이더를 수정하세요.
final noiseServiceProvider = Provider<NoiseService>((ref) {
  final service = MockNoiseService();
  // ref가 dispose될 때 서비스 리소스 해제
  ref.onDispose(service.dispose);
  return service;
});

// ---------------------------------------------------------------------------
// 현재 위치 프로바이더
// ---------------------------------------------------------------------------

/// 앱 시작 시 현재 위치를 한 번 가져옵니다.
///
/// [LocationResult]를 반환합니다:
/// - [LocationSuccess]: 위치 조회 성공
/// - [LocationError]: 권한 거부, 서비스 비활성화 등
final currentLocationProvider = FutureProvider<LocationResult>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentPosition();
});

/// 현재 위치의 [Position]만 추출하는 편의 프로바이더.
/// 위치 조회에 실패하면 null.
final currentPositionProvider = Provider<Position?>((ref) {
  final locationAsync = ref.watch(currentLocationProvider);
  return locationAsync.whenData((result) {
    if (result is LocationSuccess) return result.position;
    return null;
  }).valueOrNull;
});

// ---------------------------------------------------------------------------
// 앱 초기화 프로바이더
// ---------------------------------------------------------------------------

/// 앱 초기화 상태를 추적합니다.
///
/// Firebase는 main.dart에서 초기화되므로,
/// 이 프로바이더는 위치 권한 사전 확인 등 추가 초기화를 수행합니다.
final appInitializationProvider = FutureProvider<AppInitializationResult>((ref) async {
  // 위치 서비스 상태 확인 (권한 요청 없이)
  final locationService = ref.watch(locationServiceProvider);

  final serviceEnabled = await locationService.isLocationServiceEnabled();
  final permission = await locationService.checkPermission();

  final locationReady = serviceEnabled &&
      (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse);

  return AppInitializationResult(
    locationServiceEnabled: serviceEnabled,
    locationPermission: permission,
    locationReady: locationReady,
  );
});

// ---------------------------------------------------------------------------
// 앱 초기화 결과
// ---------------------------------------------------------------------------

/// 앱 초기화 완료 후 상태 정보
class AppInitializationResult {
  final bool locationServiceEnabled;
  final LocationPermission locationPermission;
  final bool locationReady;

  const AppInitializationResult({
    required this.locationServiceEnabled,
    required this.locationPermission,
    required this.locationReady,
  });

  /// 위치 권한이 영구적으로 거부된 경우
  bool get isLocationPermanentlyDenied =>
      locationPermission == LocationPermission.deniedForever;

  /// 위치 권한 요청이 필요한 경우
  bool get needsLocationPermission =>
      !locationReady && !isLocationPermanentlyDenied;

  @override
  String toString() =>
      'AppInitializationResult('
      'locationServiceEnabled: $locationServiceEnabled, '
      'locationPermission: $locationPermission, '
      'locationReady: $locationReady)';
}
