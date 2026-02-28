import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// 위치 서비스 결과 래퍼
sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  final Position position;
  const LocationSuccess(this.position);
}

class LocationError extends LocationResult {
  final String message;
  final LocationErrorType type;
  const LocationError(this.message, this.type);
}

enum LocationErrorType {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unknown,
}

/// 위치 서비스
///
/// geolocator 패키지를 사용하여 현재 위치 조회, 권한 관리,
/// 두 지점 사이 거리 계산, 위치 스트림을 제공합니다.
class LocationService {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // 최소 10m 이동 시 업데이트
  );

  // ---------------------------------------------------------------------------
  // 권한 확인 및 요청
  // ---------------------------------------------------------------------------

  /// 현재 위치 권한 상태를 반환합니다.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// 위치 권한을 요청하고 결과를 반환합니다.
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// 위치 서비스가 활성화되어 있는지 확인합니다.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  // ---------------------------------------------------------------------------
  // 현재 위치 조회
  // ---------------------------------------------------------------------------

  /// 현재 위치를 한 번 조회합니다.
  ///
  /// 권한이 없거나 서비스가 비활성화된 경우 [LocationError]를 반환합니다.
  Future<LocationResult> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationError(
          '위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 켜주세요.',
          LocationErrorType.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationError(
            '위치 권한이 거부되었습니다.',
            LocationErrorType.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationError(
          '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.',
          LocationErrorType.permissionDeniedForever,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationSuccess(position);
    } catch (e) {
      return LocationError(
        '위치를 가져오는 중 오류가 발생했습니다: $e',
        LocationErrorType.unknown,
      );
    }
  }

  /// 마지막으로 알려진 위치를 반환합니다. 캐시된 값이 없으면 null.
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 위치 스트림
  // ---------------------------------------------------------------------------

  /// 위치 업데이트 스트림을 반환합니다.
  ///
  /// 권한 확인 후 스트림을 시작합니다. 권한이 없으면 빈 스트림.
  Stream<Position> getPositionStream() async* {
    final result = await getCurrentPosition();
    if (result is LocationError) return;

    yield* Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    );
  }

  // ---------------------------------------------------------------------------
  // 거리 계산
  // ---------------------------------------------------------------------------

  /// 두 위경도 좌표 사이의 거리(미터)를 반환합니다.
  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 거리(미터)를 사람이 읽기 좋은 텍스트로 변환합니다.
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  // ---------------------------------------------------------------------------
  // 앱 설정 열기
  // ---------------------------------------------------------------------------

  /// 앱 위치 권한 설정 화면을 엽니다.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// 기기 위치 설정 화면을 엽니다.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }
}
