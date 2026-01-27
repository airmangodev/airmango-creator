import 'package:appwrite/appwrite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../remote/appwrite_service.dart';
import '../models/stop.dart';
import '../../core/config/app_config.dart';

class StopRepository {
  final DatabaseHelper _dbHelper;
  final AppwriteService? _appwriteService;

  StopRepository({
    required DatabaseHelper dbHelper,
    AppwriteService? appwriteService,
  })  : _dbHelper = dbHelper,
        _appwriteService = appwriteService;

  Future<Stop?> getStopById(String id, String userId) async {
    if (_appwriteService == null) return null;
    try {
      final remoteStops = await _appwriteService.listDocuments(
        collectionId: 'stops',
        queries: [Query.equal('\$id', id)],
      );
      if (remoteStops.documents.isNotEmpty) {
        final data = remoteStops.documents.first.data;
        data['id'] = remoteStops.documents.first.$id;
        return Stop.fromMap(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> createStop(Stop stop) async {
    if (_appwriteService != null) {
      final data = stop.toMap();
      data.remove('id'); // Appwrite uses $id, not 'id' attribute
      data['is_synced'] = true; // Satisfy legacy DB requirement
      await _appwriteService.upsertDocument(
        collectionId: 'stops',
        documentId: stop.id,
        data: data,
      );
    }
    return stop.id;
  }

  Future<List<Stop>> getStopsForTrip(String tripId, String userId) async {
    if (_appwriteService == null) return [];
    try {
      final remoteStops = await _appwriteService.listDocuments(
        collectionId: 'stops',
        queries: [
          Query.equal('trip_id', tripId),
          Query.equal('user_id', userId),
          Query.orderAsc('stop_order'),
          Query.orderAsc('visit_time'),
        ],
      );
      return remoteStops.documents.map((doc) {
        final data = doc.data;
        data['id'] = doc.$id;
        return Stop.fromMap(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Stop>> getStopsForDay(String dayId, String userId) async {
    if (_appwriteService == null) return [];
    try {
      final remoteStops = await _appwriteService.listDocuments(
        collectionId: 'stops',
        queries: [
          Query.equal('day_id', dayId),
          Query.equal('user_id', userId),
          Query.orderAsc('stop_order'),
          Query.orderAsc('visit_time'),
        ],
      );
      return remoteStops.documents.map((doc) {
        final data = doc.data;
        data['id'] = doc.$id;
        return Stop.fromMap(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get all stops across all trips
  Future<List<Stop>> getAllStops(String userId) async {
    if (_appwriteService == null) return [];
    try {
      final remoteStops = await _appwriteService.listDocuments(
        collectionId: 'stops',
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('visit_time'),
        ],
      );
       return remoteStops.documents.map((doc) {
        final data = doc.data;
        data['id'] = doc.$id;
        return Stop.fromMap(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get count of all stops
  Future<int> getStopsCount(String userId) async {
    if (_appwriteService == null) return 0;
    try {
      final remoteStops = await _appwriteService.listDocuments(
        collectionId: 'stops',
        queries: [Query.equal('user_id', userId)],
      );
      return remoteStops.total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> updateStop(Stop stop) async {
    if (_appwriteService != null) {
      final data = stop.toMap();
      data.remove('id'); // Appwrite uses $id, not 'id' attribute
      data['is_synced'] = true; // Satisfy legacy DB requirement
      await _appwriteService.upsertDocument(
        collectionId: 'stops',
        documentId: stop.id,
        data: data,
      );
    }
  }

  Future<void> deleteStop(String id, String userId) async {
     if (_appwriteService != null) {
       await _deleteStopFromRemote(id);
     }
  }

  Future<void> migrateAnonymousData(String userId) async {
     // No-op for cloud only
  }

  // --- Sync Helpers ---

  Future<void> _syncStopToRemote(Stop stop) async {
     // No-op
  }

  Future<void> _deleteStopFromRemote(String id) async {
    if (_appwriteService == null) return;
    try {
      await _appwriteService.databases.deleteDocument(
        databaseId: AppConfig.databaseId,
        collectionId: 'stops',
        documentId: id,
      );
    } catch (_) {}
  }
}

final stopRepositoryProvider = Provider<StopRepository>((ref) {
  return StopRepository(
    dbHelper: DatabaseHelper.instance,
    appwriteService: ref.watch(appwriteServiceProvider),
  );
});
