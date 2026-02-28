import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class MeasurementResult {
  final double averageDb;
  final double peakDb;
  final double minDb;
  final Duration duration;
  final DateTime measuredAt;
  final String cafeId;

  const MeasurementResult({
    required this.averageDb,
    required this.peakDb,
    required this.minDb,
    required this.duration,
    required this.measuredAt,
    required this.cafeId,
  });
}

// ---------------------------------------------------------------------------
// Mock decibel stream
// ---------------------------------------------------------------------------

/// Simulates a microphone decibel reading stream.
/// Produces values every 100ms with realistic noise-level fluctuations.
Stream<double> _mockDecibelStream() async* {
  final rng = math.Random();
  double base = 45.0;
  while (true) {
    await Future.delayed(const Duration(milliseconds: 100));
    // Smooth random walk
    base += (rng.nextDouble() - 0.5) * 4.0;
    base = base.clamp(30.0, 90.0);
    // Add some instantaneous spikes
    final spike = rng.nextDouble() < 0.05 ? rng.nextDouble() * 12.0 : 0.0;
    yield base + spike;
  }
}

// ---------------------------------------------------------------------------
// Simple boolean notifier for isMeasuring
// ---------------------------------------------------------------------------

class _BoolNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;
}

// ---------------------------------------------------------------------------
// Simple nullable result notifier
// ---------------------------------------------------------------------------

class _ResultNotifier extends Notifier<MeasurementResult?> {
  @override
  MeasurementResult? build() => null;

  // ignore: use_setters_to_change_properties
  void set(MeasurementResult? value) => state = value;
}

// ---------------------------------------------------------------------------
// Simple duration notifier
// ---------------------------------------------------------------------------

class _DurationNotifier extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;

  // ignore: use_setters_to_change_properties
  void set(Duration value) => state = value;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Whether measurement is currently active
final isMeasuringProvider =
    NotifierProvider<_BoolNotifier, bool>(_BoolNotifier.new);

/// Current dB level from the microphone (mock stream)
final currentDecibelProvider = StreamProvider<double>((ref) {
  final isMeasuring = ref.watch(isMeasuringProvider);
  if (!isMeasuring) {
    return const Stream.empty();
  }
  return _mockDecibelStream();
});

/// Stores the result of the last completed measurement
final measurementResultProvider =
    NotifierProvider<_ResultNotifier, MeasurementResult?>(
  _ResultNotifier.new,
);

/// Elapsed duration since measurement started
final measurementDurationProvider =
    NotifierProvider<_DurationNotifier, Duration>(_DurationNotifier.new);

/// Notifier that manages the full measurement lifecycle:
/// start → stream dB → stop → produce result
class MeasurementNotifier extends Notifier<MeasurementResult?> {
  Timer? _durationTimer;
  Timer? _measurementTimer;
  StreamSubscription<double>? _dbSubscription;
  final List<double> _readings = [];
  Duration _elapsed = Duration.zero;

  @override
  MeasurementResult? build() => null;

  void startMeasurement({
    String cafeId = '',
    Duration maxDuration = const Duration(seconds: 30),
  }) {
    _readings.clear();
    _elapsed = Duration.zero;
    ref.read(measurementDurationProvider.notifier).set(Duration.zero);
    ref.read(isMeasuringProvider.notifier).set(true);

    // Duration ticker
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      ref.read(measurementDurationProvider.notifier).set(_elapsed);
    });

    // Subscribe to dB stream
    _dbSubscription = _mockDecibelStream().listen((db) {
      _readings.add(db);
    });

    // Auto-stop after maxDuration
    _measurementTimer = Timer(maxDuration, () {
      stopMeasurement(cafeId: cafeId);
    });
  }

  void stopMeasurement({String cafeId = ''}) {
    _durationTimer?.cancel();
    _measurementTimer?.cancel();
    _dbSubscription?.cancel();
    ref.read(isMeasuringProvider.notifier).set(false);

    if (_readings.isEmpty) return;

    final avg = _readings.reduce((a, b) => a + b) / _readings.length;
    final peak = _readings.reduce(math.max);
    final min = _readings.reduce(math.min);

    final result = MeasurementResult(
      averageDb: avg,
      peakDb: peak,
      minDb: min,
      duration: _elapsed,
      measuredAt: DateTime.now(),
      cafeId: cafeId,
    );

    state = result;
    ref.read(measurementResultProvider.notifier).set(result);
  }

  void reset() {
    _readings.clear();
    _elapsed = Duration.zero;
    ref.read(measurementDurationProvider.notifier).set(Duration.zero);
    ref.read(measurementResultProvider.notifier).set(null);
    state = null;
  }
}

final measurementNotifierProvider =
    NotifierProvider<MeasurementNotifier, MeasurementResult?>(
  MeasurementNotifier.new,
);
