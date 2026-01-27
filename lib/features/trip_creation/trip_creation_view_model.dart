import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip.dart';
import '../../data/models/day.dart';
import '../../data/repositories/trip_repository.dart';
import '../auth/auth_view_model.dart';

class TripCreationState {
  final int currentStep;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final int travelers;
  final String? heroImagePath;
  final bool isLoading;
  final String? error;
  final String? editingTripId; // Null for create mode, set for edit mode

  TripCreationState({
    this.currentStep = 0,
    this.name = '',
    this.startDate,
    this.endDate,
    this.travelers = 1,
    this.heroImagePath,
    this.isLoading = false,
    this.error,
    this.editingTripId,
  });

  bool get isEditing => editingTripId != null;

  TripCreationState copyWith({
    int? currentStep,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    int? travelers,
    String? heroImagePath,
    bool? isLoading,
    String? error,
    String? editingTripId,
  }) {
    return TripCreationState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelers: travelers ?? this.travelers,
      heroImagePath: heroImagePath ?? this.heroImagePath,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      editingTripId: editingTripId ?? this.editingTripId,
    );
  }
}

class TripCreationNotifier extends StateNotifier<TripCreationState> {
  final TripRepository _repository;
  final String? _userId;

  TripCreationNotifier(this._repository, this._userId) : super(TripCreationState());

  void setStep(int step) => state = state.copyWith(currentStep: step);
  void setName(String name) => state = state.copyWith(name: name);
  void setTravelers(int travelers) => state = state.copyWith(travelers: travelers);
  
  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setHeroImage(String path) => state = state.copyWith(heroImagePath: path);

  /// Load an existing trip for editing
  Future<void> loadTripForEditing(String tripId) async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final trip = await _repository.getTripById(tripId, _userId!);
      if (trip != null) {
        state = TripCreationState(
          editingTripId: tripId,
          name: trip.name,
          startDate: trip.startDate,
          endDate: trip.endDate,
          travelers: trip.travelers,
          heroImagePath: trip.heroImagePath,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reset state for creating a new trip
  void resetForNewTrip() {
    state = TripCreationState();
  }

  Future<String?> finalizetrip() async {
    if (state.name.isEmpty || state.startDate == null || state.endDate == null || _userId == null) {
      state = state.copyWith(error: 'Please fill all fields');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      if (state.isEditing) {
        // Update existing trip
        final existingTrip = await _repository.getTripById(state.editingTripId!, _userId!);
        if (existingTrip == null) throw Exception('Trip not found');
        
        final updatedTrip = Trip(
          id: existingTrip.id,
          userId: _userId, // CRITICAL: Must ensure userId is preserved during update
          name: state.name,
          startDate: state.startDate!,
          endDate: state.endDate!,
          travelers: state.travelers,
          status: existingTrip.status,
          heroImagePath: state.heroImagePath ?? existingTrip.heroImagePath,
          updatedAt: DateTime.now(),
          createdAt: existingTrip.createdAt,
        );
        await _repository.updateTrip(updatedTrip);
        state = state.copyWith(isLoading: false);
        return updatedTrip.id;
      } else {
        // Create new trip
        final trip = Trip.create(
          userId: _userId,
          name: state.name,
          startDate: state.startDate!,
          endDate: state.endDate!,
          travelers: state.travelers,
        );
        
        await _repository.createTrip(trip);

        // Generate Days
        List<TripDay> days = [];
        final totalDays = trip.endDate.difference(trip.startDate).inDays + 1;
        for (int i = 0; i < totalDays; i++) {
          days.add(TripDay.create(
            userId: _userId,
            tripId: trip.id,
            date: trip.startDate.add(Duration(days: i)),
            dayNumber: i + 1,
          ));
        }
        await _repository.createDays(days);

        state = state.copyWith(isLoading: false);
        return trip.id;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final tripCreationProvider = StateNotifierProvider<TripCreationNotifier, TripCreationState>((ref) {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.valueOrNull?.id;
  return TripCreationNotifier(ref.watch(tripRepositoryProvider), userId);
});
