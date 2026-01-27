import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip.dart';
import '../../data/models/media.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/remote/sync_service.dart';
import '../auth/auth_view_model.dart';

class HomeState {
  final List<Trip> trips;
  final List<Media> inboxMedia;
  final bool isLoading;

  HomeState({
    required this.trips,
    required this.inboxMedia,
    this.isLoading = false,
  });

  List<Trip> get activeTrips => trips.where((t) => t.status == TripStatus.active).toList();
  List<Trip> get pastTrips => trips.where((t) => t.status == TripStatus.completed).toList();
}

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, AsyncValue<HomeState?>>((ref) {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.valueOrNull?.id;
  return HomeViewModel(ref, userId);
});

class HomeViewModel extends StateNotifier<AsyncValue<HomeState?>> {
  final Ref _ref;
  final String? _userId;

  HomeViewModel(this._ref, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadData();
    } else {
      state = const AsyncValue.data(null); // Or some empty state
    }
  }

  Future<void> loadData() async {
    if (_userId == null) return;
    try {
      final tripRepo = _ref.read(tripRepositoryProvider);
      final mediaRepo = _ref.read(mediaRepositoryProvider);
      
      final trips = await tripRepo.getAllTrips(_userId!);
      final inbox = await mediaRepo.getAllUnassignedMedia(_userId!);
      
      state = AsyncValue.data(HomeState(
        trips: trips,
        inboxMedia: inbox,
      ));

      // Trigger background sync (non-blocking)
      _ref.read(syncServiceProvider).syncAll(_userId!).then((_) => loadDataQuietly());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadDataQuietly() async {
     if (_userId == null) return;
     try {
      final trips = await _ref.read(tripRepositoryProvider).getAllTrips(_userId!);
      final inbox = await _ref.read(mediaRepositoryProvider).getAllUnassignedMedia(_userId!);
      state = AsyncValue.data(HomeState(trips: trips, inboxMedia: inbox));
    } catch (_) {}
  }

  List<Trip> get activeTrips => state.valueOrNull?.activeTrips ?? [];
  List<Trip> get pastTrips => state.valueOrNull?.pastTrips ?? [];
  List<Media> get inboxMedia => state.valueOrNull?.inboxMedia ?? [];

  Future<void> deleteTrip(String id) async {
    if (_userId == null) return;
    await _ref.read(tripRepositoryProvider).deleteTrip(id, _userId!);
    loadData();
  }
}
