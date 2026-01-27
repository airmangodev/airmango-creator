import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/trip_creation/simple_trip_creation_screen.dart';
import '../../features/active_trip/active_trip_screen.dart';
import '../../features/active_trip/story_view_screen.dart';
import '../../features/story/story_player_screen.dart';
import '../../features/stop_detail/stop_detail_screen.dart';
import '../../features/organize/organize_screen.dart';
import '../../features/trip_summary/trip_summary_screen.dart';
import '../../features/home/past_trips_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/home/profile_screen.dart';
import '../../features/trip_creation/trip_edit_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main_shell.dart';

// Splash screen shown during auth loading
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.flight_takeoff,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Airmango',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Creator',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static final routerProvider = Provider<GoRouter>((ref) {
    final authState = ref.watch(authViewModelProvider);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: _AuthRefreshListenable(ref),
      redirect: (context, state) {
        final user = authState.valueOrNull;
        final isLogging = state.matchedLocation == '/login' || state.matchedLocation == '/register';
        final isSplash = state.matchedLocation == '/splash';
        
        debugPrint('Router: Path=${state.matchedLocation}, Loading=${authState.isLoading}, User=${user?.email}');

        // While auth is loading, stay on or go to splash
        if (authState.isLoading) {
          debugPrint('Router: Auth loading, showing splash...');
          return isSplash ? null : '/splash';
        }

        // Auth loaded - redirect from splash to appropriate screen
        if (isSplash) {
          if (user == null) {
            return '/login';
          }
          return '/';
        }

        if (user == null) {
          final redirect = isLogging ? null : '/login';
          debugPrint('Router: No user, redirect to: $redirect');
          return redirect;
        }

        if (isLogging) {
          debugPrint('Router: User logged in, redirect to home');
          return '/';
        }

        debugPrint('Router: No redirect needed');
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          pageBuilder: (context, state) => _customTransition(
            context,
            state,
            const _SplashScreen(),
          ),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => _customTransition(
            context,
            state,
            const LoginScreen(),
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => _customTransition(
            context,
            state,
            const RegisterScreen(),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => _customTransition(
                context,
                state,
                const HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/past-trips',
              pageBuilder: (context, state) => _customTransition(
                context,
                state,
                const PastTripsScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => _customTransition(
                context,
                state,
                const SettingsScreen(),
              ),
            ),
          ],
        ),
        // Full-screen routes (outside the shell)
        GoRoute(
          path: '/create-trip',
          pageBuilder: (context, state) => _customTransition(
            context,
            state,
            const SimpleTripCreationScreen(),
          ),
        ),
        GoRoute(
          path: '/trip/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _customTransition(
              context,
              state,
              ActiveTripScreen(tripId: id),
            );
          },
        ),
        GoRoute(
          path: '/stop/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _customTransition(
              context,
              state,
              StopDetailScreen(stopId: id),
            );
          },
        ),
        GoRoute(
          path: '/organize/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _customTransition(
              context,
              state,
              OrganizeScreen(tripId: id),
            );
          },
        ),
        GoRoute(
          path: '/summary/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _customTransition(
              context,
              state,
              TripSummaryScreen(tripId: id),
            );
          },
        ),
        GoRoute(
          path: '/story/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _customTransition(
              context,
              state,
              StoryViewScreen(tripId: id),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _customTransition(
            context,
            state,
            const ProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/edit-trip/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _customTransition(
              context,
              state,
              TripEditScreen(tripId: id),
            );
          },
        ),
        GoRoute(
          path: '/story-player/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _customTransition(
              context,
              state,
              StoryPlayerScreen(tripId: id),
            );
          },
        ),
      ],
    );
  });

  static CustomTransitionPage _customTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authViewModelProvider, (previous, next) => notifyListeners());
  }
}
