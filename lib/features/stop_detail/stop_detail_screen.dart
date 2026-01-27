import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'stop_detail_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../../data/models/media.dart';
import '../upload/upload_overlay.dart';

import '../../shared/widgets/media_viewer.dart';

class StopDetailScreen extends ConsumerStatefulWidget {
  final String stopId;

  const StopDetailScreen({super.key, required this.stopId});

  @override
  ConsumerState<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends ConsumerState<StopDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isEditingNotes = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(stopDetailViewModelProvider(widget.stopId));

    return Scaffold(
      body: stateAsync.when(
        data: (state) {
          if (state == null) {
            return const Center(child: Text("Stop data unavailable"));
          }
          final stop = state.stop;
          final mediaList = state.media;
          
          if (!_isEditingNotes) {
            _notesController.text = stop.notes ?? "";
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.surface,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    ),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  title: Text(
                    stop.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (mediaList.isNotEmpty)
                        Image.file(File(mediaList.first.filePath), fit: BoxFit.cover)
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
              
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Info Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            stop.type.name.toUpperCase(), 
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('hh:mm a').format(stop.visitTime), 
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Notes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                        IconButton(
                          icon: Icon(_isEditingNotes ? Icons.check : Icons.edit_note, color: AppTheme.primary),
                          onPressed: () {
                            if (_isEditingNotes) {
                              ref.read(stopDetailViewModelProvider(widget.stopId).notifier).updateNotes(_notesController.text);
                            }
                            setState(() => _isEditingNotes = !_isEditingNotes);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _isEditingNotes
                          ? TextField(
                              controller: _notesController,
                              maxLines: null,
                              decoration: const InputDecoration(border: InputBorder.none, hintText: "Add your thoughts..."),
                              style: const TextStyle(fontSize: 15, height: 1.5),
                              autofocus: true,
                            )
                          : Text(
                              stop.notes ?? "Capture your thoughts about this place...",
                              style: TextStyle(
                                color: stop.notes == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Gallery Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Gallery (${mediaList.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                        if (mediaList.isNotEmpty)
                          TextButton(
                            onPressed: () {}, 
                            child: const Text("View All", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              
              if (mediaList.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.textSecondary.withAlpha(25)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppTheme.textSecondary.withAlpha(100)),
                          const SizedBox(height: 12),
                          Text("No content captured yet", style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final media = mediaList[index];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => MediaViewer(media: media)),
                          ),
                          child: Hero(
                            tag: 'media_${media.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(media.filePath), fit: BoxFit.cover),
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black26],
                                      ),
                                    ),
                                  ),
                                  if (media.type == MediaType.video)
                                    const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 30)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: mediaList.length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentState = stateAsync.value;
          if (currentState != null) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (context) => UploadOverlay(tripId: currentState.stop.tripId, dayId: currentState.stop.id),
            );
          }
        },
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text("ADD PHOTOS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        backgroundColor: AppTheme.primary,
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
