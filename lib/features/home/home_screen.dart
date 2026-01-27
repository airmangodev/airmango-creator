import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'dart:io';
import 'home_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trip.dart';
import '../../data/models/media.dart';
import '../../data/repositories/sync_provider.dart';
import '../../data/repositories/providers.dart';
import '../../shared/widgets/shimmer_loader.dart';
import '../auth/auth_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      body: stateAsync.when(
        data: (state) {
          if (state == null) {
            return const Center(child: Text("Please log in to see your trips"));
          }
          final activeTrips = state.activeTrips;
          final pastTrips = state.pastTrips;
          final inboxMedia = state.inboxMedia;

          return RefreshIndicator(
            onRefresh: () => ref.read(homeViewModelProvider.notifier).loadData(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(context),
                if (activeTrips.isEmpty && pastTrips.isEmpty && inboxMedia.isEmpty)
                  _buildEmptyState(context)
                else ...[
                  // Inbox Section (New!)
                  if (inboxMedia.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _InboxHeroSection(mediaCount: inboxMedia.length),
                    ),

                  if (activeTrips.isNotEmpty && activeTrips.first.name.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _ActiveTripSection(trip: activeTrips.first),
                    ),
                  
                  if (pastTrips.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recent Journeys",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/past-trips'),
                              child: const Text("See All"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _TripCard(trip: pastTrips[index]),
                          childCount: pastTrips.length,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: Gap(100)),
                ],
              ],
            ),
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoader(width: 200, height: 32),
                    const Gap(24),
                    ShimmerLoader(width: MediaQuery.of(context).size.width, height: 200, borderRadius: 24),
                    const Gap(32),
                    const ShimmerLoader(width: 150, height: 24),
                    const Gap(16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: 3,
                        separatorBuilder: (_, __) => const Gap(16),
                        itemBuilder: (_, __) => ShimmerLoader(width: MediaQuery.of(context).size.width, height: 100, borderRadius: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(24.0),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Explore the world",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
                Text(
                  "Hello, Traveler!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Consumer(
              builder: (context, ref, child) {
                final syncStatus = ref.watch(syncStatusProvider);
                return syncStatus.when(
                  data: (status) => status.isSyncing
                      ? _SyncIndicator(pendingCount: status.totalPending)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                );
              },
            ),
            const Gap(12),
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_outline, color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.explore_outlined, size: 64, color: AppTheme.primary),
            ),
            const Gap(24),
            const Text(
              "No adventures yet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            const Text(
              "Capture your memories as you go.\nStart by planning a trip.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/create-trip'),
      label: const Text("Plan Trip", style: TextStyle(fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.add),
      elevation: 4,
    );
  }
}

class _InboxHeroSection extends StatelessWidget {
  final int mediaCount;

  const _InboxHeroSection({required this.mediaCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: () => _showInboxOverlay(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(80),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_fix_high, color: Colors.white, size: 28),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$mediaCount New Captures",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Organize your memories into a journey",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showInboxOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _InboxOrganizeOverlay(),
    );
  }
}

class _InboxOrganizeOverlay extends ConsumerWidget {
  const _InboxOrganizeOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider).value;
    if (state == null) return const SizedBox.shrink();

    final media = state.inboxMedia;
    final trips = state.trips;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Gap(12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Gap(24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text("Inbox", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                Gap(8),
                Text("• Organize Later", style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
              ],
            ),
          ),
          const Gap(24),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: media.length,
              itemBuilder: (context, index) {
                final item = media[index];
                return GestureDetector(
                  onTap: () => _assignMedia(context, ref, item, trips),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(item.filePath), fit: BoxFit.cover),
                        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black54]))),
                        if (item.type == MediaType.video) const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 32)),
                        const Positioned(right: 8, top: 8, child: Icon(Icons.add_circle, color: Colors.white, size: 24)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _assignMedia(BuildContext context, WidgetRef ref, Media media, List<Trip> trips) {
    if (trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Create a trip first to assign media!")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Assign to Journey"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return ListTile(
                leading: const Icon(Icons.flight_takeoff, color: AppTheme.primary),
                title: Text(trip.name),
                onTap: () async {
                  final authState = ref.read(authViewModelProvider);
                  final userId = authState.valueOrNull?.id;
                  if (userId == null) return;
                  await ref.read(mediaRepositoryProvider).assignMediaToStop(media.id, trip.id, null, userId); 
                  await ref.read(homeViewModelProvider.notifier).loadData();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActiveTripSection extends StatelessWidget {
  final Trip trip;
  const _ActiveTripSection({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 220,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(100),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ],
            ),
          ),
          // Background visual (SVG/Image placeholder)
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.flight_takeoff, size: 200, color: Colors.white.withAlpha(30)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(60),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: AppTheme.success, size: 8),
                          Gap(6),
                          Text("ACTIVE NOW", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      "${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d').format(trip.endDate)} • ${trip.travelers} Travelers",
                      style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w500),
                    ),
                    const Gap(20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/trip/${trip.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Open Itinerary", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                      ? DecorationImage(image: AssetImage(trip.heroImagePath!), fit: BoxFit.cover)
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
          color: AppTheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.sync, size: 14, color: AppTheme.primary),
            ),
            const Gap(4),
            Text(
              '${widget.pendingCount}',
              style: const TextStyle(
                color: AppTheme.primary,
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
