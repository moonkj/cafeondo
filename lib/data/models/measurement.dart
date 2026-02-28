import 'package:cloud_firestore/cloud_firestore.dart';
import 'cafe.dart';

/// 기기 정보 (측정 시 기록)
class DeviceInfo {
  final String platform;
  final String? model;
  final String? osVersion;

  const DeviceInfo({
    required this.platform,
    this.model,
    this.osVersion,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        platform: json['platform'] as String? ?? 'unknown',
        model: json['model'] as String?,
        osVersion: json['osVersion'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'platform': platform,
        if (model != null) 'model': model,
        if (osVersion != null) 'osVersion': osVersion,
      };
}

/// 소음 측정 모델
/// 사용자가 카페에서 직접 측정한 데이터
class Measurement {
  final String id;
  final String cafeId;
  final String userId;
  final double decibelLevel;
  final NoiseCategory noiseCategory;

  /// 측정 지속 시간 (초)
  final int duration;

  final DateTime timestamp;
  final DeviceInfo? deviceInfo;

  const Measurement({
    required this.id,
    required this.cafeId,
    required this.userId,
    required this.decibelLevel,
    required this.noiseCategory,
    required this.duration,
    required this.timestamp,
    this.deviceInfo,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Measurement(
      id: json['id'] as String? ?? '',
      cafeId: json['cafeId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      decibelLevel: (json['decibelLevel'] as num?)?.toDouble() ?? 0.0,
      noiseCategory: NoiseCategory.fromString(
          json['noiseCategory'] as String? ?? 'moderate'),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      timestamp: parseTimestamp(json['timestamp']),
      deviceInfo: json['deviceInfo'] != null
          ? DeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  factory Measurement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Measurement.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cafeId': cafeId,
        'userId': userId,
        'decibelLevel': decibelLevel,
        'noiseCategory': noiseCategory.englishKey,
        'duration': duration,
        'timestamp': Timestamp.fromDate(timestamp),
        if (deviceInfo != null) 'deviceInfo': deviceInfo!.toJson(),
      };

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  Measurement copyWith({
    String? id,
    String? cafeId,
    String? userId,
    double? decibelLevel,
    NoiseCategory? noiseCategory,
    int? duration,
    DateTime? timestamp,
    DeviceInfo? deviceInfo,
  }) {
    return Measurement(
      id: id ?? this.id,
      cafeId: cafeId ?? this.cafeId,
      userId: userId ?? this.userId,
      decibelLevel: decibelLevel ?? this.decibelLevel,
      noiseCategory: noiseCategory ?? this.noiseCategory,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  /// 측정 시간 텍스트 (예: "30초", "1분 30초")
  String get durationText {
    if (duration < 60) return '$duration초';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    if (seconds == 0) return '$minutes분';
    return '$minutes분 ${seconds}초';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Measurement && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Measurement(id: $id, cafeId: $cafeId, decibelLevel: $decibelLevel)';
}
