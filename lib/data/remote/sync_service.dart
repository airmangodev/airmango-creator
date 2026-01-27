import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/trip_repository.dart';
import '../repositories/media_repository.dart';

class SyncService {
  final Ref _ref;
  bool _isSyncing = false;

  SyncService(this._ref);

  bool get isSyncing => _isSyncing;

  Future<void> syncAll(String userId) async {
    if (_isSyncing) return;
    _isSyncing = true;
    debugPrint('Sync: Starting full synchronization for user: $userId');

    try {
      final tripRepo = _ref.read(tripRepositoryProvider);
      final mediaRepo = _ref.read(mediaRepositoryProvider);

      // Sequence matters: Trips -> Days -> Media
      await tripRepo.syncPending(userId);
      await mediaRepo.syncPending(userId);
      
      debugPrint('Sync: Full synchronization completed successfully.');
    } catch (e) {
      if (e.toString().contains("Invalid Origin")) {
         debugPrint('Sync: Skipped (Appwrite Platform not registered for com.example.airmango_creator)');
      } else {
         debugPrint('Sync: Background synchronization failed: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});
