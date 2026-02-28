import 'dart:async';
import 'dart:math' as math;

import 'package:noise_meter/noise_meter.dart';

import '../models/cafe.dart';

// ---------------------------------------------------------------------------
// 소음 측정 결과
// ---------------------------------------------------------------------------

/// 개별 소음 샘플
class NoiseSample {
  final double decibels;
  final DateTime timestamp;

  const NoiseSample({
    required this.decibels,
    required this.timestamp,
  });
}

/// 집계된 소음 측정 결과
class NoiseMeasurementResult {
  final double averageDecibels;
  final double peakDecibels;
  final double minDecibels;
  final NoiseCategory noiseCategory;
  final int sampleCount;
  final Duration duration;
  final DateTime completedAt;

  const NoiseMeasurementResult({
    required this.averageDecibels,
    required this.peakDecibels,
    required this.minDecibels,
    required this.noiseCategory,
    required this.sampleCount,
    required this.duration,
    required this.completedAt,
  });

  @override
  String toString() =>
      'NoiseMeasurementResult(avg: ${averageDecibels.toStringAsFixed(1)} dB, '
      'category: ${noiseCategory.label}, samples: $sampleCount)';
}

// ---------------------------------------------------------------------------
// 노이즈 서비스 추상 인터페이스
// ---------------------------------------------------------------------------

/// 소음 서비스 추상 클래스
///
/// [MockNoiseService]는 개발/테스트용 구현이며,
/// 실제 마이크 기반 구현으로 교체 가능합니다.
abstract class NoiseService {
  /// 원시 dB 값 스트림 (100ms 간격)
  Stream<double> get decibelStream;

  /// 소음 측정을 시작합니다.
  void startMeasurement();

  /// 소음 측정을 중지하고 집계 결과를 반환합니다.
  NoiseMeasurementResult? stopMeasurement();

  /// 현재 측정 중인지 여부
  bool get isMeasuring;

  /// 수집된 샘플 수
  int get sampleCount;

  /// 리소스를 해제합니다.
  void dispose();
}

// ---------------------------------------------------------------------------
// Mock 구현 (실제 noise_meter 대체용)
// ---------------------------------------------------------------------------

/// Mock 소음 서비스
///
/// 실제 마이크 접근 없이 현실감 있는 dB 값(35–78 dB)을 생성합니다.
/// 100ms 간격으로 샘플을 방출하며, noise_meter 연동 준비가 완료되면
/// 이 클래스를 실제 구현으로 교체하세요.
class MockNoiseService implements NoiseService {
  static const double _minDb = 35.0;
  static const double _maxDb = 78.0;
  static const Duration _sampleInterval = Duration(milliseconds: 100);

  final math.Random _random = math.Random();
  final StreamController<double> _controller =
      StreamController<double>.broadcast();

  Timer? _sampleTimer;
  double _currentBase = 50.0;
  final List<double> _samples = [];
  DateTime? _startTime;
  bool _measuring = false;

  @override
  bool get isMeasuring => _measuring;

  @override
  int get sampleCount => _samples.length;

  @override
  Stream<double> get decibelStream => _controller.stream;

  @override
  void startMeasurement() {
    if (_measuring) return;

    _measuring = true;
    _samples.clear();
    _startTime = DateTime.now();
    _currentBase = 45.0 + _random.nextDouble() * 20.0; // 45–65 범위에서 시작

    _sampleTimer = Timer.periodic(_sampleInterval, (_) {
      if (!_measuring) return;

      final sample = _generateSample();
      _samples.add(sample);
      if (!_controller.isClosed) {
        _controller.add(sample);
      }
    });
  }

  @override
  NoiseMeasurementResult? stopMeasurement() {
    if (!_measuring) return null;

    _measuring = false;
    _sampleTimer?.cancel();
    _sampleTimer = null;

    if (_samples.isEmpty) return null;

    final avg = _samples.reduce((a, b) => a + b) / _samples.length;
    final peak = _samples.reduce(math.max);
    final min = _samples.reduce(math.min);
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;

    return NoiseMeasurementResult(
      averageDecibels: avg,
      peakDecibels: peak,
      minDecibels: min,
      noiseCategory: NoiseCategory.fromDecibels(avg),
      sampleCount: _samples.length,
      duration: duration,
      completedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _measuring = false;
    _sampleTimer?.cancel();
    _controller.close();
  }

  // ---------------------------------------------------------------------------
  // 내부: 현실감 있는 dB 샘플 생성
  // ---------------------------------------------------------------------------

  double _generateSample() {
    // 랜덤 워크로 기준 소음 이동
    _currentBase += (_random.nextDouble() - 0.5) * 3.0;
    _currentBase = _currentBase.clamp(_minDb, _maxDb);

    // 5% 확률로 일시적 스파이크 (말소리, 접시 소리 등)
    final spike =
        _random.nextDouble() < 0.05 ? _random.nextDouble() * 12.0 : 0.0;

    // 약간의 고주파 변동 추가
    final jitter = (_random.nextDouble() - 0.5) * 2.0;

    return (_currentBase + spike + jitter).clamp(_minDb, _maxDb + 5.0);
  }

  // ---------------------------------------------------------------------------
  // 정적 유틸리티
  // ---------------------------------------------------------------------------

  /// dB 값으로 소음 카테고리를 결정합니다.
  static NoiseCategory categoryFromDecibels(double db) {
    return NoiseCategory.fromDecibels(db);
  }

  /// 지정된 시간 동안 샘플을 스트리밍하고 평균 dB을 반환합니다.
  static Future<double> measureAverage({
    Duration duration = const Duration(seconds: 10),
  }) async {
    final service = MockNoiseService();
    service.startMeasurement();
    await Future.delayed(duration);
    final result = service.stopMeasurement();
    service.dispose();
    return result?.averageDecibels ?? 50.0;
  }
}

// ---------------------------------------------------------------------------
// 실제 마이크 구현 (noise_meter 패키지 기반)
// ---------------------------------------------------------------------------

/// 실제 마이크 소음 서비스
///
/// [noise_meter](https://pub.dev/packages/noise_meter) 패키지를 사용해
/// 기기 마이크에서 실시간 dB 값을 측정합니다.
///
/// ## 플랫폼 설정
///
/// ### Android
/// `android/app/src/main/AndroidManifest.xml`에 추가:
/// ```xml
/// <uses-permission android:name="android.permission.RECORD_AUDIO" />
/// ```
///
/// ### iOS
/// `ios/Runner/Info.plist`에 추가:
/// ```xml
/// <key>NSMicrophoneUsageDescription</key>
/// <string>소음 측정을 위해 마이크 접근이 필요합니다.</string>
/// ```
/// Xcode > Capabilities > Background Modes > Audio, AirPlay and Picture in Picture 활성화
///
/// ## 권한 요청
/// 이 서비스를 사용하기 전에 반드시 마이크 권한을 요청하세요.
/// `permission_handler` 패키지 또는 직접 권한 요청을 사용할 수 있습니다.
class MicNoiseService implements NoiseService {
  final StreamController<double> _controller =
      StreamController<double>.broadcast();

  StreamSubscription<NoiseReading>? _noiseSubscription;
  NoiseMeter? _noiseMeter;

  final List<double> _samples = [];
  DateTime? _startTime;
  bool _measuring = false;

  @override
  bool get isMeasuring => _measuring;

  @override
  int get sampleCount => _samples.length;

  @override
  Stream<double> get decibelStream => _controller.stream;

  @override
  void startMeasurement() {
    if (_measuring) return;

    _measuring = true;
    _samples.clear();
    _startTime = DateTime.now();

    _noiseMeter = NoiseMeter();
    _noiseSubscription = _noiseMeter!.noise.listen(
      (NoiseReading reading) {
        if (!_measuring) return;
        final db = reading.meanDecibel;
        _samples.add(db);
        if (!_controller.isClosed) {
          _controller.add(db);
        }
      },
      onError: (Object error) {
        // 권한 오류 또는 하드웨어 오류 시 스트림에 에러 전달
        if (!_controller.isClosed) {
          _controller.addError(error);
        }
        _measuring = false;
      },
      cancelOnError: true,
    );
  }

  @override
  NoiseMeasurementResult? stopMeasurement() {
    if (!_measuring) return null;

    _measuring = false;
    _noiseSubscription?.cancel();
    _noiseSubscription = null;
    _noiseMeter = null;

    if (_samples.isEmpty) return null;

    final avg = _samples.reduce((a, b) => a + b) / _samples.length;
    final peak = _samples.reduce(math.max);
    final min = _samples.reduce(math.min);
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;

    return NoiseMeasurementResult(
      averageDecibels: avg,
      peakDecibels: peak,
      minDecibels: min,
      noiseCategory: NoiseCategory.fromDecibels(avg),
      sampleCount: _samples.length,
      duration: duration,
      completedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _measuring = false;
    _noiseSubscription?.cancel();
    _controller.close();
  }
}
