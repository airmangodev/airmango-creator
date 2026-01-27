import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'trip_summary_view_model.dart';
import '../../core/theme/app_theme.dart';

class TripSummaryScreen extends ConsumerWidget {
  final String tripId;

  const TripSummaryScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(tripSummaryViewModelProvider(tripId));

    return Scaffold(
      body: stateAsync.when(
        data: (state) {
          if (state == null) {
            return const Center(child: Text("Trip summary unavailable"));
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text("Trip Complete! 🎉", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  Text(state.trip.name, style: const TextStyle(fontSize: 20, color: Colors.grey)),
                  const SizedBox(height: 40),
                  
                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3, // Taller cards to prevent overflow
                    children: [
                      _StatCard(label: "Days", value: "${state.daysCount}", icon: Icons.calendar_today),
                      _StatCard(label: "Stops", value: "${state.stopsCount}", icon: Icons.location_on),
                      _StatCard(label: "Captures", value: "${state.mediaCount}", icon: Icons.camera_alt),
                      _StatCard(label: "Videos", value: "${state.videoCount}", icon: Icons.videocam),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryBg,
                          borderRadius: BorderRadius.circular(16)
                      ),
                      child: const Column(
                          children: [
                              Text("Ready to share?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              SizedBox(height: 8),
                              Text("Submit your trip to AirMango Creator.", textAlign: TextAlign.center),
                          ],
                      ),
                  ),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                          onPressed: () async {
                              await ref.read(tripSummaryViewModelProvider(tripId).notifier).submitTrip();
                              if (context.mounted) context.go('/');
                          },
                          child: const Text("Finish & Submit"),
                      ),
                  )
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
    final String label;
    final String value;
    final IconData icon;

    const _StatCard({required this.label, required this.value, required this.icon});

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(icon, color: AppTheme.primary, size: 24),
                        const SizedBox(height: 4),
                        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                ),
            ),
        );
    }
}
