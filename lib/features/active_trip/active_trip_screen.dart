import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'active_trip_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../../data/models/stop.dart';
import '../../data/repositories/sync_provider.dart';
import '../../shared/widgets/shimmer_loader.dart';
import 'package:gap/gap.dart';
import 'dart:io';
import '../../data/models/media.dart';
import '../../data/models/day.dart';
import '../story/add_stop_dialog.dart';

class ActiveTripScreen extends ConsumerWidget {
  final String tripId;

  const ActiveTripScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripStateAsync = ref.watch(activeTripViewModelProvider(tripId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
      body: tripStateAsync.when(
        data: (state) {
          if (state == null) {
            return const Center(child: Text("Trip data unavailable"));
          }
          final trip = state.trip;
          final days = state.days;
          final selectedDay = state.selectedDay;
          final stops = state.stopsForDay;
          final unassigned = state.unassignedMedia;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Hero Header
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.surface,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => context.go('/'),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    ),
                    onPressed: () => _showTripMenu(context, tripId),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final syncStatus = ref.watch(syncStatusProvider);
                      return syncStatus.when(
                        data: (status) => status.isSyncing
                            ? Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Center(child: _SyncIndicator(pendingCount: status.totalPending)),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  title: Text(
                    trip.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (trip.heroImagePath != null && trip.heroImagePath!.isNotEmpty)
                        Image.file(File(trip.heroImagePath!), fit: BoxFit.cover)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.primary, AppTheme.accent],
                            ),
                          ),
                        ),
                      // Gradient Overlay for text readability
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Day Selection & Mini-Map Context
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "YOUR JOURNEY",
                                style: TextStyle(
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedDay != null 
                                  ? "Day ${selectedDay.dayNumber}: ${DateFormat('EEEE, MMM d').format(selectedDay.date)}"
                                  : "Overview",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          // Stylized Mini-map
                          Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppTheme.accent.withAlpha(25),
                              border: Border.all(color: AppTheme.accent.withAlpha(50)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  // Grid lines
                                  ...List.generate(4, (i) => Positioned(left: i * 20.0, top: 0, bottom: 0, child: Container(width: 1, color: AppTheme.accent.withAlpha(10)))),
                                  ...List.generate(3, (i) => Positioned(top: i * 20.0, left: 0, right: 0, child: Container(height: 1, color: AppTheme.accent.withAlpha(10)))),
                                  // Route line
                                  Center(
                                    child: CustomPaint(
                                      size: const Size(60, 40),
                                      painter: _MapRoutePainter(AppTheme.accent),
                                    ),
                                  ),
                                  const Center(child: Icon(Icons.location_on, color: AppTheme.accent, size: 16)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Day Pills
                      SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: days.length,
                          itemBuilder: (context, index) {
                            final day = days[index];
                            final isSelected = day.id == selectedDay?.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text("Day ${day.dayNumber}"),
                                selected: isSelected,
                                onSelected: (_) => ref
                                    .read(activeTripViewModelProvider(tripId).notifier)
                                    .selectDay(day),
                                selectedColor: AppTheme.primary,
                                backgroundColor: AppTheme.surface,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.primary : AppTheme.textSecondary.withAlpha(25),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Unassigned Content Banner
              if (unassigned.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: _UnassignedInboxCard(count: unassigned.length, tripId: trip.id),
                  ),
                ),

              // Day Content Section (The Story)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: days.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note_outlined, size: 64, color: AppTheme.textSecondary.withAlpha(50)),
                              const SizedBox(height: 16),
                              const Text(
                                "No days in this trip yet.",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    : selectedDay == null
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Text(
                                "Select a day to see your story",
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        : _buildStorySliver(context, ref, state, selectedDay, stops),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
        loading: () => Container(
          color: AppTheme.primaryBg,
          child: Column(
            children: [
              // Skeleton Header
              Container(
                width: double.infinity,
                height: 140,
                color: Colors.black.withAlpha(50),
              ),
              const SizedBox(height: 16),
              // Skeleton Day Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShimmerLoader(width: 80, height: 36, borderRadius: 20),
                  )),
                ),
              ),
              const SizedBox(height: 16),
              // Skeleton Story Items
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  separatorBuilder: (_, index) => const Gap(24),
                  itemBuilder: (_, index) => ShimmerLoader(
                    width: MediaQuery.of(context).size.width - 32, 
                    height: 140, 
                    borderRadius: 24
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final state = tripStateAsync.value;
          if (state == null) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddStopDialog(
              tripId: tripId,
              days: state.days,
            ),
          );
        },
        label: const Text("Add Stop", style: TextStyle(fontWeight: FontWeight.bold, inherit: true)),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: AppTheme.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ),
    );
  }

  Widget _buildStorySliver(BuildContext context, WidgetRef ref, ActiveTripState state, TripDay selectedDay, List<Stop> stops) {
    if (stops.isEmpty) {
      final dayPhotos = state.dayMedia[selectedDay.id] ?? [];
      if (dayPhotos.isNotEmpty) {
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("MOMENTS"),
              _MomentsGrid(media: dayPhotos),
            ],
          ),
        );
      }
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 48, color: AppTheme.primary.withAlpha(50)),
              const SizedBox(height: 16),
              const Text(
                "No story items for this day yet.",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Add stops or photos to start your story.",
                style: TextStyle(color: AppTheme.textSecondary.withAlpha(150), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // We use a regular SliverList but with drag handles in the items
    // Note: ReorderableListView within CustomScrollView usually requires SliverReorderableList
    return SliverReorderableList(
      itemCount: stops.length + 1, // +1 for Narrative
      onReorder: (oldIndex, newIndex) {
        if (oldIndex == 0 || newIndex == 0) return; // Narrative is fixed
        // Adjust indices because of Narrative at 0
        final realOldIndex = oldIndex - 1;
        final realNewIndex = newIndex - 1;
        ref.read(activeTripViewModelProvider(state.trip.id).notifier)
           .reorderStops(realOldIndex, realNewIndex);
      },
      itemBuilder: (context, index) {
         if (index == 0) {
            // Narrative Card (Not reorderable, but part of the list to scroll)
            // We wrap it in a ReorderableDragStartListener with enabled: false to prevent dragging
            return ReorderableDragStartListener(
              key: ValueKey('narrative-${selectedDay.id}'),
              index: index,
              enabled: false,
              child: _DayNarrativeCard(
                narrative: selectedDay.storyNarrative,
                onSave: (val) => ref
                    .read(activeTripViewModelProvider(state.trip.id).notifier)
                    .updateDayNarrative(val),
              ),
            );
          }

          final stopIndex = index - 1;
          final stop = stops[stopIndex];
          final stopMedia = (state.dayMedia[selectedDay.id] ?? []).where((m) => m.stopId == stop.id).toList();
          
          return ReorderableDragStartListener(
            key: ValueKey(stop.id),
            index: index,
            child: _StopStoryItem(
              stop: stop,
              media: stopMedia,
              isFirst: stopIndex == 0,
              isLast: stopIndex == stops.length - 1,
              tripId: state.trip.id,
              days: state.days,
            ),
          );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          letterSpacing: 1.5,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary.withAlpha(150),
        ),
      ),
    );
  }


  void _showTripMenu(BuildContext context, String tripId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withAlpha(50),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
             const SizedBox(height: 16),
             ListTile(
              leading: const Icon(Icons.play_circle_fill, color: Colors.orange, size: 32),
              title: const Text("View Trip", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text("Watch your journey highlights"),
              onTap: () {
                Navigator.pop(context);
                context.push('/story-player/$tripId');
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              title: const Text("Edit Trip", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Change name, dates, or travelers"),
              onTap: () {
                Navigator.pop(context);
                context.push('/edit-trip/$tripId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text("Complete Trip", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Mark this journey as finished"),
              onTap: () {
                Navigator.pop(context);
                context.push('/summary/$tripId');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


class _StopStoryItem extends ConsumerWidget {
  final Stop stop;
  final List<Media> media;
  final bool isFirst;
  final bool isLast;
  final String tripId;
  final List<TripDay> days;

  const _StopStoryItem({
    required this.stop,
    required this.media,
    required this.isFirst,
    required this.isLast,
    required this.tripId,
    required this.days,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAccommodation = stop.type == StopType.accommodation;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst) Container(width: 2, height: 16, color: AppTheme.textSecondary.withAlpha(25)),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isAccommodation ? Colors.indigo : AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: (isAccommodation ? Colors.indigo : AppTheme.primary).withAlpha(50), blurRadius: 6),
                    ],
                  ),
                  child: Icon(
                    _getStopIcon(stop.type),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : AppTheme.textSecondary.withAlpha(25))),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0, left: 12),
              child: GestureDetector(
                onTap: () => context.push('/stop/${stop.id}'),
                onLongPress: () {
                    // Trigger drag on long press (handled by parent ReorderableDragStartListener automatically)
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Title & Time
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    stop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppTheme.textPrimary,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                ),
                                // Context Menu
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz, color: AppTheme.textSecondary),
                                  onSelected: (value) {
                                      if (value == 'edit') {
                                           showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => AddStopDialog(
                                              tripId: tripId,
                                              days: days, // Corrected from snapshot.data!.days
                                              existingStop: stop,
                                            ),
                                          );
                                      } else if (value == 'delete') {
                                         ref.read(activeTripViewModelProvider(tripId).notifier).deleteStop(stop.id);
                                         ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Moment deleted')),
                                         );
                                      }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Unpublish', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                  Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isAccommodation ? Colors.indigo : AppTheme.primary).withAlpha(15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAccommodation ? "🏨 STAY" : stop.type.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAccommodation ? Colors.indigo : AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('h:mm a').format(stop.visitTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            
                            if (stop.notes != null && stop.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                stop.notes!,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Media Gallery
                      if (media.isNotEmpty)
                        Container(
                          height: 120,
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: media.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.file(
                                  File(media[idx].filePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Footer indicators
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            if (media.isNotEmpty) ...[
                              const Icon(Icons.photo_library_outlined, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text("${media.length}", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(width: 16),
                            ],
                            const Icon(Icons.cloud_done_outlined, size: 14, color: AppTheme.primary),
                            const Spacer(),
                            const Icon(Icons.drag_indicator, size: 20, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStopIcon(StopType type) {
    switch (type) {
      case StopType.accommodation: return Icons.hotel;
      case StopType.restaurant: return Icons.restaurant;
      case StopType.activity: return Icons.directions_run;
      case StopType.attraction: return Icons.camera_alt;
      case StopType.other: return Icons.place;
    }
  }
}

class _MomentsGrid extends StatelessWidget {
  final List<Media> media;
  const _MomentsGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(media[index].filePath), fit: BoxFit.cover),
            if (media[index].type == MediaType.video)
              const Center(child: Icon(Icons.play_circle_outline, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _UnassignedInboxCard extends StatelessWidget {
  final int count;
  final String tripId;
  const _UnassignedInboxCard({required this.count, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: () => context.push('/organize/$tripId'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$count New Captures",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      "Ready to be organized",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapRoutePainter extends CustomPainter {
  final Color color;
  _MapRoutePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(50)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.8, size.width, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SyncIndicator extends StatefulWidget {
  final int pendingCount;
  const _SyncIndicator({required this.pendingCount});

  @override
  State<_SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<_SyncIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${widget.pendingCount} items syncing...',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.sync, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.pendingCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayNarrativeCard extends StatefulWidget {
  final String? narrative;
  final Function(String) onSave;

  const _DayNarrativeCard({this.narrative, required this.onSave});

  @override
  State<_DayNarrativeCard> createState() => _DayNarrativeCardState();
}

class _DayNarrativeCardState extends State<_DayNarrativeCard> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.narrative);
  }

  @override
  void didUpdateWidget(covariant _DayNarrativeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.narrative != widget.narrative && !_isEditing) {
      _controller.text = widget.narrative ?? "";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "DAY NARRATIVE",
                  style: TextStyle(
                    letterSpacing: 1.5,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    inherit: true,
                  ),
                ),
              ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_note, size: 20, color: AppTheme.primary),
                  onPressed: () => setState(() => _isEditing = true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.red),
                      onPressed: () => setState(() {
                        _isEditing = false;
                        _controller.text = widget.narrative ?? "";
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.check, size: 20, color: Colors.green),
                      onPressed: () {
                        widget.onSave(_controller.text);
                        setState(() => _isEditing = false);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing)
            TextField(
              controller: _controller,
              maxLines: null,
              autofocus: true,
              style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Sum up your day's journey here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.primary.withAlpha(50))),
                filled: true,
                fillColor: AppTheme.primary.withAlpha(5),
              ),
            )
          else if (widget.narrative != null && widget.narrative!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                widget.narrative!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Outfit',
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories_outlined, color: AppTheme.textMuted.withAlpha(100), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      "Write today's narrative",
                      style: TextStyle(color: AppTheme.textMuted.withAlpha(150), fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
