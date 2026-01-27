import 'package:uuid/uuid.dart';

enum MediaType { photo, video, voice, text }

class Media {
  final String id;
  final String? userId;
  final String? tripId; // Null if unassigned (inbox)
  final String? stopId; // Null if unassigned (inbox)
  final MediaType type;
  final String filePath; // Local path or text content
  final double? lat;
  final double? lng;
  final DateTime capturedAt;
  final String? note;
  final int? durationSeconds;
  // final bool isSynced;
  final DateTime updatedAt;
  final String? remoteUrl;

  Media({
    required this.id,
    this.userId,
    this.tripId,
    this.stopId,
    required this.type,
    required this.filePath,
    this.lat,
    this.lng,
    required this.capturedAt,
    this.note,
    this.durationSeconds,
    // this.isSynced = false,
    DateTime? updatedAt,
    this.remoteUrl,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory Media.create({
    String? userId,
    String? tripId,
    String? stopId,
    required MediaType type,
    required String filePath,
    double? lat,
    double? lng,
    String? note,
    int? durationSeconds,
  }) {
    return Media(
      id: const Uuid().v4(),
      userId: userId,
      tripId: tripId,
      stopId: stopId,
      type: type,
      filePath: filePath,
      lat: lat,
      lng: lng,
      capturedAt: DateTime.now(),
      note: note,
      durationSeconds: durationSeconds,
      // isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'stop_id': stopId,
      'type': type.name,
      'file_path': filePath,
      'lat': lat,
      'lng': lng,
      'captured_at': capturedAt.toIso8601String(),
      'note': note,
      'duration_seconds': durationSeconds,
      // 'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
      'remote_url': remoteUrl,
    };
  }

  factory Media.fromMap(Map<String, dynamic> map) {
    return Media(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      tripId: map['trip_id']?.toString(), // Nullable
      stopId: map['stop_id']?.toString(),
      type: MediaType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MediaType.photo,
      ),
      filePath: map['file_path']?.toString() ?? '',
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      capturedAt: map['captured_at'] != null 
          ? DateTime.tryParse(map['captured_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: map['note']?.toString(),
      durationSeconds: int.tryParse(map['duration_seconds']?.toString() ?? ''),
      // isSynced: (map['is_synced'] == 1 || map['is_synced'] == true || map['is_synced'] == '1'),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      remoteUrl: map['remote_url']?.toString(),
    );
  }
}
