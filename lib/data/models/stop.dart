import 'package:uuid/uuid.dart';

enum StopType { accommodation, activity, attraction, restaurant, other }

class Stop {
  final String id;
  final String? userId;
  final String tripId;
  final String? dayId;
  final String name;
  final StopType type;
  final double? lat;
  final double? lng;
  final DateTime visitTime;
  final String? notes;
  final String? placeId;
  final bool isAccommodation;
  final int stopOrder;
  // final bool isSynced;
  final DateTime updatedAt;

  Stop({
    required this.id,
    this.userId,
    required this.tripId,
    this.dayId,
    required this.name,
    this.type = StopType.other,
    this.lat,
    this.lng,
    required this.visitTime,
    this.notes,
    this.placeId,
    this.isAccommodation = false,
    this.stopOrder = 0,
    // this.isSynced = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory Stop.create({
    String? userId,
    required String tripId,
    String? dayId,
    required String name,
    required StopType type,
    double? lat,
    double? lng,
    String? notes,
    bool isAccommodation = false,
    int stopOrder = 0,
  }) {
    return Stop(
      id: const Uuid().v4(),
      userId: userId,
      tripId: tripId,
      dayId: dayId,
      name: name,
      type: type,
      lat: lat,
      lng: lng,
      visitTime: DateTime.now(),
      notes: notes,
      isAccommodation: isAccommodation,
      stopOrder: stopOrder,
      // isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'day_id': dayId,
      'name': name,
      'type': type.name,
      'lat': lat,
      'lng': lng,
      'visit_time': visitTime.toIso8601String(),
      'notes': notes,
      'place_id': placeId,
      'is_accommodation': isAccommodation, // Boolean for Appwrite
      'stop_order': stopOrder,
      // 'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      tripId: map['trip_id']?.toString() ?? '',
      dayId: map['day_id']?.toString(),
      name: map['name']?.toString() ?? 'New Stop',
      type: StopType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StopType.other,
      ),
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      visitTime: map['visit_time'] != null 
          ? DateTime.tryParse(map['visit_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes']?.toString(),
      placeId: map['place_id']?.toString(),
      isAccommodation: (map['is_accommodation'] == 1 || map['is_accommodation'] == true || map['is_accommodation'] == '1'),
      stopOrder: int.tryParse(map['stop_order']?.toString() ?? '0') ?? 0,
      // isSynced: (map['is_synced'] == 1 || map['is_synced'] == true || map['is_synced'] == '1'),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
