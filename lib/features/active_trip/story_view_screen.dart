import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trip.dart';
import '../../data/models/day.dart';
import '../../data/models/media.dart';
import '../../data/repositories/providers.dart';
import '../auth/auth_view_model.dart';
import 'dart:io';

/// Story view - shows the complete trip as a chronological timeline
class StoryViewScreen extends ConsumerWidget {
  final String tripId;

  const StoryViewScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final userId = authState.valueOrNull?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("Please log in to view stories", style: TextStyle(color: Colors.white))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadStoryData(ref, userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final data = snapshot.data!;
          final trip = data['trip'] as Trip;
          final days = data['days'] as List<TripDay>;
          final dayMedia = data['dayMedia'] as Map<String, List<Media>>;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  title: Text(
                    trip.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Story Timeline
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final day = days[index];
                    final media = dayMedia[day.id] ?? [];
                    
                    if (media.isEmpty) return const SizedBox.shrink();

                    return _StoryDaySection(
                      day: day,
                      media: media,
                      isFirst: index == 0,
                      isLast: index == days.length - 1,
                    );
                  },
                  childCount: days.length,
                ),
              ),

              // End spacer
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadStoryData(WidgetRef ref, String userId) async {
    final tripRepo = ref.read(tripRepositoryProvider);
    final mediaRepo = ref.read(mediaRepositoryProvider);

    final trip = await tripRepo.getTripById(tripId, userId);
    final days = await tripRepo.getDaysForTrip(tripId, userId);

    final Map<String, List<Media>> dayMedia = {};
    for (var day in days) {
      final media = await mediaRepo.getMediaForDay(day.id, userId);
      if (media.isNotEmpty) {
        dayMedia[day.id] = media;
      }
    }

    return {
      'trip': trip,
      'days': days,
      'dayMedia': dayMedia,
    };
  }
}

class _StoryDaySection extends StatelessWidget {
  final TripDay day;
  final List<Media> media;
  final bool isFirst;
  final bool isLast;

  const _StoryDaySection({
    required this.day,
    required this.media,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day ${day.dayNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d').format(day.date),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Photos in story format
          ...media.map((mediaItem) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      File(mediaItem.filePath),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Timestamp overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('h:mm a').format(mediaItem.capturedAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Note overlay if exists
                    if (mediaItem.note != null && mediaItem.note!.isNotEmpty)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withAlpha(200)],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            mediaItem.note!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
