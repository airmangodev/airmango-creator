import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import '../../data/models/stop.dart';
import '../../data/models/media.dart';
import '../../features/active_trip/active_trip_view_model.dart';
import '../../core/theme/app_theme.dart';

class StoryPlayerScreen extends ConsumerStatefulWidget {
  final String tripId;
  const StoryPlayerScreen({super.key, required this.tripId});

  @override
  ConsumerState<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends ConsumerState<StoryPlayerScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<_StoryItem> _storyItems = [];

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure provider is ready if needed, 
    // but ref.read in build is better for initial data access if provider is already warm.
  }

  void _prepareStoryItems(ActiveTripState state) {
    if (_storyItems.isNotEmpty) return; // Already prepared

    final items = <_StoryItem>[];
    
    // Sort days chronologically
    final days = [...state.days]..sort((a, b) => a.date.compareTo(b.date));

    for (var day in days) {
      final dayMedia = state.dayMedia[day.id] ?? [];
      
      // 1. Get stops for the day and sort items
      // (Assuming activeTripViewModel already loaded stops for the selected day, 
      // but here we want ALL days. The ViewModel loads current day. 
      // Ideally we need a 'Load Full Trip Story' method, 
      // but for MVP we can show what we have in state or just iterates available media)
      
      // Since ActiveTripState primarily holds data for the SELECTED day + all day media list,
      // we can construct the story based on Media mostly.
      
      // Group media by stop if possible, otherwise independent
      // A better approach for "Story" is simply chronological media playback
      
      if (dayMedia.isEmpty) continue;

      // Sort media by creation time (if we had it) or just use list order
      for (var media in dayMedia) {
         Stop? relatedStop;
         if (media.stopId != null) {
             // We might not have all stops in state if they weren't loaded
             // But we can try to find it if it was loaded
             try {
                relatedStop = state.stopsForDay.firstWhere((s) => s.id == media.stopId);
             } catch (_) {}
         }

         items.add(_StoryItem(
           media: media,
           dayNumber: day.dayNumber,
           date: day.date,
           stop: relatedStop,
         ));
      }
    }
    
    setState(() {
      _storyItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(activeTripViewModelProvider(widget.tripId)).valueOrNull;

    if (tripState == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    if (_storyItems.isEmpty) {
        _prepareStoryItems(tripState);
    }
    
    if (_storyItems.isEmpty) {
       return Scaffold(
         backgroundColor: Colors.black,
         appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
         body: const Center(
           child: Text("No memories to show yet.", style: TextStyle(color: Colors.white)),
         ),
       );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Content
          PageView.builder(
            controller: _pageController,
            itemCount: _storyItems.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final item = _storyItems[index];
              return Image.file(
                File(item.media.filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white)),
              );
            },
          ),

          // Overlay Gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Top Progres Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              children: List.generate(_storyItems.length, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 3,
                    decoration: BoxDecoration(
                      color: index <= _currentIndex ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Footer Info
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_storyItems[_currentIndex].stop != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _storyItems[_currentIndex].stop!.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    ),
                  ),
                
                Text(
                  "Day ${_storyItems[_currentIndex].dayNumber} • ${DateFormat('MMM d').format(_storyItems[_currentIndex].date)}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Time
                Text(
                   DateFormat('h:mm a').format(_storyItems[_currentIndex].date), // Ideally use media time if available
                   style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Navigation Taps
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex > 0) {
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex < _storyItems.length - 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      context.pop();
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryItem {
  final Media media;
  final int dayNumber;
  final DateTime date;
  final Stop? stop;

  _StoryItem({required this.media, required this.dayNumber, required this.date, this.stop});
}
