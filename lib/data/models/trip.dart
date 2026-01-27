import 'package:uuid/uuid.dart';

enum TripStatus { active, completed, draft }

class Trip {
  final String id;
  final String? userId; // Link to Appwrite User
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final TripStatus status;
  final String? heroImagePath;
  // final bool isSynced; // Removed as part of cloud-only refactor
  final DateTime updatedAt;
  final DateTime createdAt;

  Trip({
    required this.id,
    this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    this.status = TripStatus.draft,
    this.heroImagePath,
    // this.isSynced = false,
    DateTime? updatedAt,
    DateTime? createdAt,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory Trip.create({
    String? userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required int travelers,
  }) {
    final now = DateTime.now();
    return Trip(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      travelers: travelers,
      status: TripStatus.active,
      // isSynced: false,
      updatedAt: now,
      createdAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'travelers': travelers,
      'status': status.name,
      'hero_image_path': heroImagePath,
      // 'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      name: map['name']?.toString() ?? 'Untitled Trip',
      startDate: map['start_date'] != null 
          ? DateTime.tryParse(map['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['end_date'] != null 
          ? DateTime.tryParse(map['end_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      travelers: int.tryParse(map['travelers']?.toString() ?? '1') ?? 1,
      status: TripStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TripStatus.draft,
      ),
      heroImagePath: map['hero_image_path']?.toString(),
      // isSynced: (map['is_synced'] == 1 || map['is_synced'] == true || map['is_synced'] == '1'),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
