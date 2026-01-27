import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'home_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../../data/models/trip.dart';

class PastTripsScreen extends ConsumerStatefulWidget {
  const PastTripsScreen({super.key});

  @override
  ConsumerState<PastTripsScreen> createState() => _PastTripsScreenState();
}

class _PastTripsScreenState extends ConsumerState<PastTripsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text("Recent Journeys", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: tripsAsync.when(
        data: (_) {
          final allTrips = viewModel.pastTrips;
          final filteredTrips = _searchQuery.isEmpty 
              ? allTrips 
              : allTrips.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: "Search journeys...",
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: AppTheme.primary),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      ),
                    ),
                  ),
                ),
              ),

              // Results
              Expanded(
                child: filteredTrips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: AppTheme.textMuted.withAlpha(100)),
                            const Gap(16),
                            Text(
                              _searchQuery.isEmpty ? "No past journeys found" : "No results for \"$_searchQuery\"",
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredTrips.length,
                        itemBuilder: (context, index) => _TripCard(trip: filteredTrips[index]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/trip/${trip.id}'),
      child: Hero(
        tag: 'trip_card_${trip.id}',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    image: trip.heroImagePath != null 
                      ? DecorationImage(
                          image: FileImage(File(trip.heroImagePath!)),
                          fit: BoxFit.cover
                        )
                      : null,
                  ),
                  child: trip.heroImagePath == null 
                    ? const Center(child: Icon(Icons.image_outlined, color: AppTheme.textMuted))
                    : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: AppTheme.textMuted),
                        const Gap(4),
                        Text(
                          DateFormat('MMM yyyy').format(trip.startDate),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
