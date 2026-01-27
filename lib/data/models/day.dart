import 'package:uuid/uuid.dart';

class TripDay {
  final String id;
  final String? userId;
  final String tripId;
  final DateTime date;
  final int dayNumber;
  final String? storyNarrative;
  // final bool isSynced;
  final DateTime updatedAt;

  TripDay({
    required this.id,
    this.userId,
    required this.tripId,
    required this.date,
    required this.dayNumber,
    this.storyNarrative,
    // this.isSynced = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory TripDay.create({
    String? userId,
    required String tripId,
    required DateTime date,
    required int dayNumber,
    String? storyNarrative,
  }) {
    return TripDay(
      id: const Uuid().v4(),
      userId: userId,
      tripId: tripId,
      date: date,
      dayNumber: dayNumber,
      storyNarrative: storyNarrative,
      // isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'date': date.toIso8601String(),
      'day_number': dayNumber,
      'story_narrative': storyNarrative,
      // 'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TripDay.fromMap(Map<String, dynamic> map) {
    return TripDay(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      tripId: map['trip_id']?.toString() ?? '',
      date: map['date'] != null 
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dayNumber: int.tryParse(map['day_number']?.toString() ?? '1') ?? 1,
      storyNarrative: map['story_narrative']?.toString(),
      // isSynced: (map['is_synced'] == 1 || map['is_synced'] == true || map['is_synced'] == '1'),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
