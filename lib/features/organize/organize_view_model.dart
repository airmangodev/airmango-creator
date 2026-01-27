import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/media.dart';
import '../../data/models/stop.dart';
import '../../data/models/day.dart';
import '../../data/models/trip.dart';
import '../../features/active_trip/active_trip_view_model.dart';
import '../../features/stop_detail/stop_detail_view_model.dart';
import '../../data/repositories/providers.dart';
import '../auth/auth_view_model.dart';

final organizeViewModelProvider = StateNotifierProvider.family<OrganizeViewModel, AsyncValue<OrganizeState?>, String>((ref, tripId) {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.valueOrNull?.id;
  return OrganizeViewModel(ref, tripId, userId);
});

class OrganizeState {
  final Trip trip;
  final List<Media> unassignedMedia;
  final List<Stop> stops;
  final List<TripDay> days;

  OrganizeState({
    required this.trip,
    required this.unassignedMedia,
    required this.stops,
    required this.days,
  });
}

class OrganizeViewModel extends StateNotifier<AsyncValue<OrganizeState?>> {
  final Ref _ref;
  final String _tripId;
  final String? _userId;

  OrganizeViewModel(this._ref, this._tripId, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadData();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadData() async {
    if (_userId == null) return;
    try {
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      final stopRepo = _ref.read(stopRepositoryProvider);
      final tripRepo = _ref.read(tripRepositoryProvider);

      final trip = await tripRepo.getTripById(_tripId, _userId!);
      if (trip == null) throw Exception("Trip not found");

      final media = await mediaRepo.getUnassignedMedia(_tripId, _userId!);
      final stops = await stopRepo.getStopsForTrip(_tripId, _userId!);
      final days = await tripRepo.getDaysForTrip(_tripId, _userId!);

      state = AsyncValue.data(OrganizeState(
        trip: trip,
        unassignedMedia: media,
        stops: stops,
        days: days,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> assignMediaToStop(String mediaId, String stopId) async {
    state = const AsyncValue.loading();
    if (_userId == null) return;
    try {
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      await mediaRepo.assignMediaToStop(mediaId, _tripId, stopId, _userId!);
      
      // Update UI in other screens too
      _ref.invalidate(activeTripViewModelProvider(_tripId));
      _ref.invalidate(stopDetailViewModelProvider(stopId));
      
      await loadData();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> createNewStopAndAssign(String mediaId, String name, StopType type, String? dayId) async {
    state = const AsyncValue.loading();
    try {
      final stopRepo = _ref.read(stopRepositoryProvider);
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      
      final stop = Stop.create(
        userId: _userId,
        tripId: _tripId,
        dayId: dayId,
        name: name,
        type: type,
      );
      
      final stopId = await stopRepo.createStop(stop);
      await mediaRepo.assignMediaToStop(mediaId, _tripId, stopId, _userId!);
      
      _ref.invalidate(activeTripViewModelProvider(_tripId));
      
      await loadData();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Stop? getSuggestedStop(Media media) {
    final currentStops = state.value?.stops ?? [];
    if (currentStops.isEmpty) return null;

    // 1. Proximity by Location (within 500m)
    if (media.lat != null && media.lng != null) {
      for (var stop in currentStops) {
        if (stop.lat != null && stop.lng != null) {
          // Simplistic distance check (approx 1deg = 111km)
          final latDiff = (media.lat! - stop.lat!).abs();
          final lngDiff = (media.lng! - stop.lng!).abs();
          if (latDiff < 0.005 && lngDiff < 0.005) {
            return stop;
          }
        }
      }
    }

    // 2. Proximity by Time (within 1 hour)
    for (var stop in currentStops) {
      final diff = media.capturedAt.difference(stop.visitTime).inMinutes.abs();
      if (diff < 60) {
        return stop;
      }
    }

    return null;
  }
}
