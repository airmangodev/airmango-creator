import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip.dart';
import '../../data/models/media.dart';
import '../../data/repositories/providers.dart';
import '../auth/auth_view_model.dart';

final tripSummaryViewModelProvider = StateNotifierProvider.family<TripSummaryViewModel, AsyncValue<TripSummaryState?>, String>((ref, tripId) {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.valueOrNull?.id;
  return TripSummaryViewModel(ref, tripId, userId);
});

class TripSummaryState {
  final Trip trip;
  final int daysCount;
  final int stopsCount;
  final int mediaCount;
  final int videoCount;

  TripSummaryState({
    required this.trip, 
    required this.daysCount, 
    required this.stopsCount, 
    required this.mediaCount,
    required this.videoCount,
  });
}

class TripSummaryViewModel extends StateNotifier<AsyncValue<TripSummaryState?>> {
  final Ref _ref;
  final String _tripId;
  final String? _userId;

  TripSummaryViewModel(this._ref, this._tripId, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadStats();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadStats() async {
    if (_userId == null) return;
    try {
      final tripRepo = _ref.read(tripRepositoryProvider);
      final stopRepo = _ref.read(stopRepositoryProvider);
      final mediaRepo = _ref.read(mediaRepositoryProvider);

      final trip = await tripRepo.getTripById(_tripId, _userId);
      if (trip == null) throw Exception("Trip not found");

      final days = await tripRepo.getDaysForTrip(_tripId, _userId);
      final stops = await stopRepo.getStopsForTrip(_tripId, _userId);
      final media = await mediaRepo.getMediaForTrip(_tripId, _userId);

      final videos = media.where((m) => m.type == MediaType.video).length;

      state = AsyncValue.data(TripSummaryState(
        trip: trip,
        daysCount: days.length,
        stopsCount: stops.length,
        mediaCount: media.length,
        videoCount: videos,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> submitTrip() async {
    final currentState = state.value;
    if (currentState == null || _userId == null) return;

    state = const AsyncValue.loading();
    try {
      final tripRepo = _ref.read(tripRepositoryProvider);
      
      // 1. Mark as completed in DB (Cloud)
      final updatedTrip = Trip(
        id: currentState.trip.id,
        userId: currentState.trip.userId,
        name: currentState.trip.name,
        startDate: currentState.trip.startDate,
        endDate: currentState.trip.endDate,
        travelers: currentState.trip.travelers,
        status: TripStatus.completed,
        heroImagePath: currentState.trip.heroImagePath,
        updatedAt: DateTime.now(),
        createdAt: currentState.trip.createdAt,
      );

      await tripRepo.updateTrip(updatedTrip);
      
      // 2. Submit to Webhook
      await tripRepo.submitTripToWebhook(_tripId, _userId);
      
      // 3. Refresh State
      await loadStats();
      
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
