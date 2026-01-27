import '../../data/models/user.dart';
import '../../data/remote/appwrite_service.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/stop_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/repositories/media_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AsyncValue<AppUser?>>((ref) {
  return AuthViewModel(ref);
});

class AuthViewModel extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref _ref;
  late final AppwriteService _appwrite;

  AuthViewModel(this._ref) : super(const AsyncValue.loading()) {
    _appwrite = _ref.read(appwriteServiceProvider);
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    debugPrint('Auth: Checking status...');
    try {
      // Direct call to avoid Future.timeout issues
      final user = await _appwrite.getCurrentUser();
      debugPrint('Auth: Status checked. User: ${user?.email}');
      state = AsyncValue.data(user);
      if (user != null) {
        _syncUserData(user.id);
      }
    } catch (e, stack) {
      debugPrint('Auth: Check failed: $e');
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _appwrite.login(email: email, password: password);
      final user = await _appwrite.getCurrentUser();
      if (user != null) {
        // _migrateData(user.id); // Disabled for security/isolation
      }
      state = AsyncValue.data(user);
      if (user != null) {
        _syncUserData(user.id);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> _migrateData(String userId) async {
    try {
      await _ref.read(tripRepositoryProvider).migrateAnonymousData(userId);
      await _ref.read(stopRepositoryProvider).migrateAnonymousData(userId);
      await _ref.read(mediaRepositoryProvider).migrateAnonymousData(userId);
      debugPrint('Auth: Anonymous data migrated to user: $userId');
    } catch (e) {
      debugPrint('Auth: Data migration failed: $e');
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      await _appwrite.register(email: email, password: password, name: name);
      await login(email, password);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _appwrite.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      // Use native Google Sign-In (shows account picker)
      final user = await _appwrite.loginWithGoogleNative();
      
      if (user != null) {
        debugPrint('Auth: Login successful for ${user.email}');
        state = AsyncValue.data(user);
        _syncUserData(user.id);
      } else {
        // User cancelled the picker
        debugPrint('Auth: User cancelled Google Sign-In');
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      final errorMsg = e.toString().toLowerCase();
      // Handle cancellation gracefully
      if (errorMsg.contains('canceled') || errorMsg.contains('cancelled') || errorMsg.contains('sign_in_canceled')) {
        debugPrint("Auth: User canceled login flow.");
        state = const AsyncValue.data(null);
        return;
      }
      
      debugPrint("Auth: Login exception: $e");
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    try {
      await _appwrite.loginWithApple();
      final user = await _appwrite.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Dev mode login - bypasses OAuth for testing when browser is unavailable
  Future<void> devLogin() async {
    state = const AsyncValue.loading();
    try {
      // Create a local-only dev user
      final devUser = AppUser(
        id: 'dev_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'dev@airmango.local',
        name: 'Dev Tester',
        createdAt: DateTime.now(),
      );
      debugPrint('Auth: Dev login activated for ${devUser.email}');
      state = AsyncValue.data(devUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Called after in-app WebView OAuth completes successfully
  Future<void> completeOAuthLogin() async {
    state = const AsyncValue.loading();
    try {
      // Give the session a moment to be established
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Fetch the user from Appwrite
      final user = await _appwrite.getCurrentUser();
      
      if (user != null) {
        debugPrint('Auth: OAuth login completed for ${user.email}');
        state = AsyncValue.data(user);
        _syncUserData(user.id);
      } else {
        throw Exception('OAuth succeeded but no user session found');
      }
    } catch (e, stack) {
      debugPrint('Auth: OAuth completion failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _syncUserData(String userId) async {
    try {
      debugPrint('Auth: Starting data sync for user $userId');
      // Sync trips, days, stops, media from cloud to local DB
      await _ref.read(tripRepositoryProvider).fetchRemoteData(userId);
      // Migrate any anonymous data if needed
      await _migrateData(userId);
      debugPrint('Auth: Data sync completed');
    } catch (e) {
      debugPrint('Auth: Data sync failed: $e');
    }
  }

  /// Get appwrite service for WebView OAuth URL
  AppwriteService get appwrite => _appwrite;
}

