import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../data/models/media.dart';
import '../../features/auth/auth_view_model.dart';
import '../../data/models/user.dart';

/// Provider to fetch profile statistics
final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.valueOrNull?.id;
  
  if (userId == null) {
     return ProfileStats(tripCount: 0, stopsCount: 0, photoCount: 0, recentMedia: []);
  }

  final tripRepo = ref.read(tripRepositoryProvider);
  final stopRepo = ref.read(stopRepositoryProvider);
  final mediaRepo = ref.read(mediaRepositoryProvider);

  try {
    final trips = await tripRepo.getAllTrips(userId);
    final stopsCount = await stopRepo.getStopsCount(userId);
    final photoCount = await mediaRepo.getPhotoCount(userId);
    final recentMedia = await mediaRepo.getRecentMedia(userId, limit: 5);

    return ProfileStats(
      tripCount: trips.length,
      stopsCount: stopsCount,
      photoCount: photoCount,
      recentMedia: recentMedia,
    );
  } catch (e) {
    return ProfileStats(
      tripCount: 0,
      stopsCount: 0,
      photoCount: 0,
      recentMedia: [],
    );
  }
});

class ProfileStats {
  final int tripCount;
  final int stopsCount;
  final int photoCount;
  final List<Media> recentMedia;

  ProfileStats({
    required this.tripCount,
    required this.stopsCount,
    required this.photoCount,
    required this.recentMedia,
  });
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);
    final userState = ref.watch(authViewModelProvider);
    final user = userState.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgSecondary : AppTheme.bgSecondary,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            _buildHeroHeader(context, ref, user),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statsAsync.when(
                      data: (stats) => _buildStatsRow(stats, isDark),
                      loading: () => _buildLoadingStats(isDark),
                      error: (_, __) => _buildErrorStats(isDark),
                    ),
                    const Gap(32),
                    Text(
                      "Recent Activity",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Outfit',
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    const Gap(16),
                    statsAsync.when(
                      data: (stats) => _buildActivityList(stats.recentMedia, isDark),
                      loading: () => _buildLoadingActivity(isDark),
                      error: (_, __) => const Text("Failed to load activity"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, WidgetRef ref, AppUser? user) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(authViewModelProvider.notifier).logout();
                    },
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.accent],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gap(40),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    user?.name ?? "Traveler Explorer",
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                  ),
                  Text(
                    user?.email ?? "traveler@example.com",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ProfileStats stats, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Trips", "${stats.tripCount}", Icons.map, isDark)),
        const Gap(16),
        Expanded(child: _buildStatCard("Stops", "${stats.stopsCount}", Icons.location_on, isDark)),
        const Gap(16),
        Expanded(child: _buildStatCard("Photos", "${stats.photoCount}", Icons.photo_library, isDark)),
      ],
    );
  }

  Widget _buildLoadingStats(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildLoadingStatCard(isDark)),
        const Gap(16),
        Expanded(child: _buildLoadingStatCard(isDark)),
        const Gap(16),
        Expanded(child: _buildLoadingStatCard(isDark)),
      ],
    );
  }

  Widget _buildLoadingStatCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorStats(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Trips", "0", Icons.map, isDark)),
        const Gap(16),
        Expanded(child: _buildStatCard("Stops", "0", Icons.location_on, isDark)),
        const Gap(16),
        Expanded(child: _buildStatCard("Photos", "0", Icons.photo_library, isDark)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const Gap(8),
          Text(value, style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          )),
          Text(label, style: TextStyle(
            color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted, 
            fontSize: 12,
          )),
        ],
      ),
    );
  }

  Widget _buildLoadingActivity(bool isDark) {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Loading...", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildActivityList(List<Media> recentMedia, bool isDark) {
    if (recentMedia.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.photo_camera_outlined, size: 48, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
              const Gap(16),
              Text(
                "No activity yet",
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  fontSize: 16,
                ),
              ),
              const Gap(8),
              Text(
                "Start capturing moments!",
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recentMedia.map((media) => _buildActivityTile(
        _getActivityTitle(media),
        _getTimeAgo(media.capturedAt),
        _getActivityIcon(media),
        isDark,
      )).toList(),
    );
  }

  String _getActivityTitle(Media media) {
    switch (media.type) {
      case MediaType.photo:
        return "Captured a new photo";
      case MediaType.video:
        return "Recorded a video";
      case MediaType.voice:
        return "Added a voice note";
      case MediaType.text:
        return "Added a text note";
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  IconData _getActivityIcon(Media media) {
    switch (media.type) {
      case MediaType.photo:
        return Icons.camera_alt;
      case MediaType.video:
        return Icons.videocam;
      case MediaType.voice:
        return Icons.mic;
      case MediaType.text:
        return Icons.note_alt;
    }
  }

  Widget _buildActivityTile(String title, String time, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                )),
                Text(time, style: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted, 
                  fontSize: 12,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
