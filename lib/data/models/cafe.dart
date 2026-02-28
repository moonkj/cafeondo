import 'package:cloud_firestore/cloud_firestore.dart';

/// 소음 카테고리 (dB 기반)
enum NoiseCategory {
  /// 0–40 dB: 조용함
  quiet,

  /// 40–60 dB: 보통
  moderate,

  /// 60–75 dB: 시끄러움
  noisy,

  /// 75+ dB: 매우 시끄러움
  loud;

  String get label {
    switch (this) {
      case NoiseCategory.quiet:
        return '조용함';
      case NoiseCategory.moderate:
        return '보통';
      case NoiseCategory.noisy:
        return '시끄러움';
      case NoiseCategory.loud:
        return '매우 시끄러움';
    }
  }

  String get englishKey {
    switch (this) {
      case NoiseCategory.quiet:
        return 'quiet';
      case NoiseCategory.moderate:
        return 'moderate';
      case NoiseCategory.noisy:
        return 'noisy';
      case NoiseCategory.loud:
        return 'loud';
    }
  }

  static NoiseCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'quiet':
        return NoiseCategory.quiet;
      case 'moderate':
        return NoiseCategory.moderate;
      case 'noisy':
        return NoiseCategory.noisy;
      case 'loud':
        return NoiseCategory.loud;
      default:
        return NoiseCategory.moderate;
    }
  }

  static NoiseCategory fromDecibels(double db) {
    if (db < 40) return NoiseCategory.quiet;
    if (db < 60) return NoiseCategory.moderate;
    if (db < 75) return NoiseCategory.noisy;
    return NoiseCategory.loud;
  }
}

/// 최근 측정 요약 (Cafe 모델에 포함)
class RecentMeasurement {
  final String measurementId;
  final double decibelLevel;
  final NoiseCategory noiseCategory;
  final DateTime timestamp;

  const RecentMeasurement({
    required this.measurementId,
    required this.decibelLevel,
    required this.noiseCategory,
    required this.timestamp,
  });

  factory RecentMeasurement.fromJson(Map<String, dynamic> json) {
    return RecentMeasurement(
      measurementId: json['measurementId'] as String? ?? '',
      decibelLevel: (json['decibelLevel'] as num?)?.toDouble() ?? 0.0,
      noiseCategory: NoiseCategory.fromString(
          json['noiseCategory'] as String? ?? 'moderate'),
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'measurementId': measurementId,
        'decibelLevel': decibelLevel,
        'noiseCategory': noiseCategory.englishKey,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

/// 카페 모델
class Cafe {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double averageNoiseLevel;
  final NoiseCategory noiseCategory;
  final int totalMeasurements;
  final List<RecentMeasurement> recentMeasurements;
  final List<String> photos;
  final double rating;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Cafe({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.averageNoiseLevel = 0.0,
    this.noiseCategory = NoiseCategory.moderate,
    this.totalMeasurements = 0,
    this.recentMeasurements = const [],
    this.photos = const [],
    this.rating = 0.0,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Cafe.fromJson(Map<String, dynamic> json) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Cafe(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      averageNoiseLevel:
          (json['averageNoiseLevel'] as num?)?.toDouble() ?? 0.0,
      noiseCategory: NoiseCategory.fromString(
          json['noiseCategory'] as String? ?? 'moderate'),
      totalMeasurements: (json['totalMeasurements'] as num?)?.toInt() ?? 0,
      recentMeasurements: (json['recentMeasurements'] as List<dynamic>?)
              ?.map((e) =>
                  RecentMeasurement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      photos: List<String>.from(json['photos'] as List<dynamic>? ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? []),
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
    );
  }

  factory Cafe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Cafe.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'averageNoiseLevel': averageNoiseLevel,
        'noiseCategory': noiseCategory.englishKey,
        'totalMeasurements': totalMeasurements,
        'recentMeasurements':
            recentMeasurements.map((m) => m.toJson()).toList(),
        'photos': photos,
        'rating': rating,
        'tags': tags,
        'createdAt':
            createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses doc ID
    return json;
  }

  Cafe copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? averageNoiseLevel,
    NoiseCategory? noiseCategory,
    int? totalMeasurements,
    List<RecentMeasurement>? recentMeasurements,
    List<String>? photos,
    double? rating,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cafe(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      averageNoiseLevel: averageNoiseLevel ?? this.averageNoiseLevel,
      noiseCategory: noiseCategory ?? this.noiseCategory,
      totalMeasurements: totalMeasurements ?? this.totalMeasurements,
      recentMeasurements: recentMeasurements ?? this.recentMeasurements,
      photos: photos ?? this.photos,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 거리 표시 텍스트 (meters)
  String distanceText(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Cafe && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Cafe(id: $id, name: $name, noiseCategory: ${noiseCategory.label})';
}
