import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'organize_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../../data/models/stop.dart';
import '../../data/models/day.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class OrganizeScreen extends ConsumerWidget {
  final String tripId;

  const OrganizeScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(organizeViewModelProvider(tripId));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppTheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Organize Journey",
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          stateAsync.when(
            data: (state) {
              if (state == null) {
                return const SliverFillRemaining(
                  child: Center(child: Text("Trip data unavailable")),
                );
              }
              final mediaList = state.unassignedMedia;

              if (mediaList.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success),
                        ),
                        const Gap(24),
                        const Text("All organized!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Gap(8),
                        const Text("Your journey is neat and tidy.", style: TextStyle(color: AppTheme.textMuted)),
                        const Gap(32),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text("Return to Itinerary"),
                        )
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final media = mediaList[index];
                      return GestureDetector(
                        onTap: () => _showOrganizeDialog(context, ref, media, state.stops, state.days),
                        child: Hero(
                          tag: 'media_${media.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(media.filePath), fit: BoxFit.cover),
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black87],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.white, size: 14),
                                        const Gap(4),
                                        Expanded(
                                          child: Text(
                                            DateFormat('HH:mm').format(media.capturedAt),
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GlassCard(
                                      borderRadius: 12,
                                      opacity: 0.2,
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(Icons.auto_fix_high, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: mediaList.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: Gap(40)),
        ],
      ),
    );
  }

  void _showOrganizeDialog(
      BuildContext context, WidgetRef ref, dynamic media, List<Stop> stops, List<TripDay> days) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignMediaSheet(
        tripId: tripId,
        media: media,
        stops: stops,
        days: days,
        suggestedStopId: ref.read(organizeViewModelProvider(tripId).notifier).getSuggestedStop(media)?.id,
      ),
    );
  }
}

class _AssignMediaSheet extends ConsumerStatefulWidget {
  final String tripId;
  final dynamic media;
  final List<Stop> stops;
  final List<TripDay> days;
  final String? suggestedStopId;

  const _AssignMediaSheet({
    required this.tripId,
    required this.media,
    required this.stops,
    required this.days,
    this.suggestedStopId,
  });

  @override
  ConsumerState<_AssignMediaSheet> createState() => _AssignMediaSheetState();
}

class _AssignMediaSheetState extends ConsumerState<_AssignMediaSheet> {
  bool _showNewStopForm = false;
  final _stopNameController = TextEditingController();
  StopType _selectedType = StopType.other;
  String? _selectedDayId;

  @override
  void initState() {
    super.initState();
    if (widget.days.isNotEmpty) {
      _selectedDayId = widget.days.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showNewStopForm ? "Create New Stop" : "Assign Capture",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          const Gap(24),
          if (!_showNewStopForm) ...[
            if (widget.stops.isEmpty)
              _buildEmptyStops()
            else
              _buildStopsList(),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showNewStopForm = true),
                icon: const Icon(Icons.add),
                label: const Text("New Destination"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBg,
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ),
          ] else ...[
            _buildNewStopForm(),
          ],
          Gap(MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildEmptyStops() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.textMuted),
          Gap(12),
          Expanded(
            child: Text(
              "No stops created yet. Create a stop to group your captures.",
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopsList() {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        itemCount: widget.stops.length,
        separatorBuilder: (context, index) => const Gap(12),
        itemBuilder: (context, index) {
          final stop = widget.stops[index];
          final isSuggested = stop.id == widget.suggestedStopId;
          
          return InkWell(
            onTap: () {
              ref.read(organizeViewModelProvider(widget.tripId).notifier)
                  .assignMediaToStop(widget.media.id, stop.id);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_pin, color: AppTheme.primary, size: 20),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(stop.type.name, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                  if (isSuggested) ...[
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "SUGGESTED",
                        style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewStopForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _stopNameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Place Name",
            hintText: "Where was this taken?",
          ),
        ),
        const Gap(16),
        const Text("Visit Day", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const Gap(8),
        DropdownButtonFormField<String>(
          value: _selectedDayId,
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
          items: widget.days.map((day) => DropdownMenuItem(
            value: day.id,
            child: Text("Day ${day.dayNumber} - ${DateFormat('MMM d').format(day.date)}"),
          )).toList(),
          onChanged: (val) => setState(() => _selectedDayId = val),
        ),
        const Gap(16),
        const Text("Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const Gap(8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: StopType.values.map((type) {
              final isSelected = _selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(type.name),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedType = type),
                  selectedColor: AppTheme.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary),
                ),
              );
            }).toList(),
          ),
        ),
        const Gap(32),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _showNewStopForm = false),
                child: const Text("Cancel"),
              ),
            ),
            const Gap(16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_stopNameController.text.isNotEmpty) {
                    ref.read(organizeViewModelProvider(widget.tripId).notifier)
                        .createNewStopAndAssign(
                          widget.media.id,
                          _stopNameController.text,
                          _selectedType,
                          _selectedDayId,
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Create & Assign"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
