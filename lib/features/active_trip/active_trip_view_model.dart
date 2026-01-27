import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip.dart';
import '../../data/models/day.dart';
import '../../data/models/stop.dart';
import '../../data/models/media.dart';
import '../../data/repositories/providers.dart';
import '../../shared/services/notification_service.dart';
import '../auth/auth_view_model.dart';

final activeTripViewModelProvider = StateNotifierProvider.family<ActiveTripViewModel, AsyncValue<ActiveTripState?>, String>((ref, tripId) {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.valueOrNull?.id;
  return ActiveTripViewModel(ref, tripId, userId);
});

class ActiveTripState {
  final Trip trip;
  final List<TripDay> days;
  final List<Stop> stopsForDay;
  final List<Media> unassignedMedia;
  final Map<String, int> stopMediaCounts; // stopId -> count
  final Map<String, List<Media>> dayMedia; // dayId -> media list
  final TripDay? selectedDay;

  ActiveTripState({
    required this.trip,
    required this.days,
    required this.stopsForDay,
    required this.unassignedMedia,
    this.stopMediaCounts = const {},
    this.dayMedia = const {},
    this.selectedDay,
  });

  ActiveTripState copyWith({
    Trip? trip,
    List<TripDay>? days,
    List<Stop>? stopsForDay,
    List<Media>? unassignedMedia,
    Map<String, int>? stopMediaCounts,
    Map<String, List<Media>>? dayMedia,
    TripDay? selectedDay,
  }) {
    return ActiveTripState(
      trip: trip ?? this.trip,
      days: days ?? this.days,
      stopsForDay: stopsForDay ?? this.stopsForDay,
      unassignedMedia: unassignedMedia ?? this.unassignedMedia,
      stopMediaCounts: stopMediaCounts ?? this.stopMediaCounts,
      dayMedia: dayMedia ?? this.dayMedia,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }
}

class ActiveTripViewModel extends StateNotifier<AsyncValue<ActiveTripState?>> {
  final Ref _ref;
  final String _tripId;
  final String? _userId;

  ActiveTripViewModel(this._ref, this._tripId, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadTripData();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadTripData() async {
    if (_userId == null) return;
    try {
      final tripRepo = _ref.read(tripRepositoryProvider);
      final stopRepo = _ref.read(stopRepositoryProvider);
      final mediaRepo = _ref.read(mediaRepositoryProvider);

      final results = await Future.wait([
        tripRepo.getTripById(_tripId, _userId),
        tripRepo.getDaysForTrip(_tripId, _userId),
        mediaRepo.getUnassignedMedia(_tripId, _userId),
      ]);

      final trip = results[0] as Trip?;
      if (trip == null) throw Exception('Trip not found');

      final days = results[1] as List<TripDay>;
      final unassignedMedia = results[2] as List<Media>;
      
      // Select active day by date, or first day
      TripDay? activeDay;
      final now = DateTime.now();
      try {
           activeDay = days.firstWhere((d) => 
                d.date.year == now.year && 
                d.date.month == now.month && 
                d.date.day == now.day
            );
      } catch (_) {
          activeDay = days.isNotEmpty ? days.first : null;
      }

      List<Stop> stops = [];
      Map<String, int> stopMediaCounts = {};
      Map<String, List<Media>> dayMedia = {};
      
      // Load media for all days in parallel
      final mediaResults = await Future.wait(
        days.map((day) => mediaRepo.getMediaForDay(day.id, _userId))
      );
      
      for (var i = 0; i < days.length; i++) {
        dayMedia[days[i].id] = mediaResults[i];
      }
      
      if (activeDay != null) {
        stops = await stopRepo.getStopsForDay(activeDay.id, _userId!);
        
        // Load stop media counts in parallel
        final stopMediaResults = await Future.wait(
          stops.map((stop) => mediaRepo.getMediaForStop(stop.id, _userId!))
        );
        
        for (var i = 0; i < stops.length; i++) {
          stopMediaCounts[stops[i].id] = stopMediaResults[i].length;
        }

        // Phase 6: Schedule Daily Reminder (8:00 PM)
        _scheduleReminder(trip.name);
      }

      state = AsyncValue.data(ActiveTripState(
        trip: trip,
        days: days,
        stopsForDay: stops,
        unassignedMedia: unassignedMedia,
        stopMediaCounts: stopMediaCounts,
        dayMedia: dayMedia,
        selectedDay: activeDay,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _scheduleReminder(String tripName) {
    _ref.read(notificationServiceProvider).scheduleDailyTripReminder(
      id: _tripId.hashCode, // Unique ID based on trip
      title: "Today's Journey in $tripName",
      body: "Don't forget to add your story and photos for today! ✨",
      hour: 20, // 8 PM
      minute: 0,
    );
  }

  Future<void> selectDay(TripDay day) async {
    final currentState = state.value;
    if (currentState == null) return;

    // We don't set state to loading here to avoid the "shimmer flash"
    // Fetching from local DB is almost instant
    try {
        final stopRepo = _ref.read(stopRepositoryProvider);
        final mediaRepo = _ref.read(mediaRepositoryProvider);
        
        final stops = await stopRepo.getStopsForDay(day.id, _userId!);
        
        Map<String, int> stopMediaCounts = {};
        for (var stop in stops) {
          final media = await mediaRepo.getMediaForStop(stop.id, _userId!);
          stopMediaCounts[stop.id] = media.length;
        }
        
        state = AsyncValue.data(currentState.copyWith(
            stopsForDay: stops,
            stopMediaCounts: stopMediaCounts,
            selectedDay: day,
        ));
    } catch (e, s) {
        state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() async {
    final currentState = state.value;
    if (currentState == null || _userId == null) return;
    
    // If we have a selected day, we want to keep it selected after refresh
    final previouslySelectedDayId = currentState.selectedDay?.id;

    await loadTripData();

    if (previouslySelectedDayId != null) {
      final newState = state.value;
      if (newState != null) {
        try {
          final preservedDay = newState.days.firstWhere((d) => d.id == previouslySelectedDayId);
          await selectDay(preservedDay);
        } catch (_) {
          // If the day no longer exists (e.g. date changed?), default behavior (already done in loadTripData) applies
        }
      }
    }
  }

  Future<void> deleteStop(String stopId) async {
    final currentState = state.value;
    if (currentState == null || _userId == null) return;

    try {
      final stopRepo = _ref.read(stopRepositoryProvider);
      await stopRepo.deleteStop(stopId, _userId!);
      await refresh(); // Refresh to update UI
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> reorderStops(int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null || currentState.selectedDay == null || _userId == null) return;

    final stops = [...currentState.stopsForDay];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Stop item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);

    // Optimistic update
    state = AsyncValue.data(currentState.copyWith(stopsForDay: stops));

    try {
      final stopRepo = _ref.read(stopRepositoryProvider);
      // Update order in DB
      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
         // Only update if order changed to avoid unnecessary DB writes
        if (stop.stopOrder != i) {
           final updatedStop = Stop(
             id: stop.id,
             userId: stop.userId,
             tripId: stop.tripId,
             dayId: stop.dayId,
             name: stop.name,
             type: stop.type,
             lat: stop.lat,
             lng: stop.lng,
             visitTime: stop.visitTime,
             notes: stop.notes,
             placeId: stop.placeId,
             isAccommodation: stop.isAccommodation,
             stopOrder: i, // Update order
             updatedAt: DateTime.now(),
           );
           await stopRepo.updateStop(updatedStop);
        }
      }
    } catch (e, s) {
       // Revert on error? For now just show error
       // state = AsyncValue.error(e, s); 
       // Ideally we would revert, but a full refresh is safer
       await refresh();
    }
  }

  Future<void> updateDayNarrative(String narrative) async {
    final currentState = state.value;
    if (currentState == null || currentState.selectedDay == null) return;

    try {
      final tripRepo = _ref.read(tripRepositoryProvider);
      final updatedDay = TripDay(
        id: currentState.selectedDay!.id,
        tripId: _tripId,
        dayNumber: currentState.selectedDay!.dayNumber,
        date: currentState.selectedDay!.date,
        storyNarrative: narrative,
      );
      await tripRepo.updateDay(updatedDay);

      final updatedDays = currentState.days.map((d) {
        if (d.id == updatedDay.id) return updatedDay;
        return d;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(
        days: updatedDays,
        selectedDay: updatedDay,
      ));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
