import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/stop.dart';
import '../../data/models/media.dart';
import '../../data/repositories/providers.dart';
import '../auth/auth_view_model.dart';

final stopDetailViewModelProvider = StateNotifierProvider.family<StopDetailViewModel, AsyncValue<StopDetailState?>, String>((ref, stopId) {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.valueOrNull?.id;
  return StopDetailViewModel(ref, stopId, userId);
});

class StopDetailState {
  final Stop stop;
  final List<Media> media;

  StopDetailState({required this.stop, required this.media});
}

class StopDetailViewModel extends StateNotifier<AsyncValue<StopDetailState?>> {
  final Ref _ref;
  final String _stopId;
  final String? _userId;

  StopDetailViewModel(this._ref, this._stopId, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadStopData();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadStopData() async {
    if (_userId == null) return;
    try {
      final stopRepo = _ref.read(stopRepositoryProvider);
      final mediaRepo = _ref.read(mediaRepositoryProvider);

      final stop = await stopRepo.getStopById(_stopId, _userId!);
      if (stop == null) throw Exception("Stop not found");

      final media = await mediaRepo.getMediaForStop(_stopId, _userId!);
      
      state = AsyncValue.data(StopDetailState(stop: stop, media: media));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateNotes(String notes) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final stopRepo = _ref.read(stopRepositoryProvider);
      final updatedStop = Stop(
        id: currentState.stop.id,
        userId: currentState.stop.userId,
        tripId: currentState.stop.tripId,
        dayId: currentState.stop.dayId,
        name: currentState.stop.name,
        type: currentState.stop.type,
        lat: currentState.stop.lat,
        lng: currentState.stop.lng,
        visitTime: currentState.stop.visitTime,
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await stopRepo.updateStop(updatedStop);
      state = AsyncValue.data(StopDetailState(stop: updatedStop, media: currentState.media));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> removeMedia(String mediaId) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      // Unassign from stop but keep in the trip
      await mediaRepo.assignMediaToStop(mediaId, currentState.stop.tripId, null, _userId!); 
      
      // Reload media
      final media = await mediaRepo.getMediaForStop(_stopId, _userId!);
      state = AsyncValue.data(StopDetailState(stop: currentState.stop, media: media));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
