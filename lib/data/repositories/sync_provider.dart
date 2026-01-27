import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class SyncStatus {
  final int unsyncedTrips;
  final int unsyncedDays;
  final int unsyncedStops;
  final int unsyncedMedia;
  final bool hasError;
  final String? errorMessage;

  SyncStatus({
    this.unsyncedTrips = 0,
    this.unsyncedDays = 0,
    this.unsyncedStops = 0,
    this.unsyncedMedia = 0,
    this.hasError = false,
    this.errorMessage,
  });

  bool get isSyncing => unsyncedTrips > 0 || unsyncedDays > 0 || unsyncedStops > 0 || unsyncedMedia > 0;
  int get totalPending => unsyncedTrips + unsyncedDays + unsyncedStops + unsyncedMedia;
}

final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  // Cloud Only: No local pending state. Always yield 0 pending.
  yield SyncStatus(
    unsyncedTrips: 0,
    unsyncedDays: 0,
    unsyncedStops: 0,
    unsyncedMedia: 0,
  );
  // Keep stream alive to avoid issues if listeners expect a stream
  await Future.delayed(const Duration(days: 365)); 
});
