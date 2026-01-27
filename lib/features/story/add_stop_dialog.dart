import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'dart:io';
import 'package:exif/exif.dart';
import '../../data/models/stop.dart';
import '../../data/models/media.dart';
import '../../data/models/day.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/stop_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../features/active_trip/active_trip_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_view_model.dart';

class AddStopDialog extends ConsumerStatefulWidget {
  final String tripId;
  final String? dayId;
  final List<TripDay> days;
  final Stop? existingStop;

  const AddStopDialog({
    super.key,
    required this.tripId,
    this.dayId,
    required this.days,
    this.existingStop,
  });

  @override
  ConsumerState<AddStopDialog> createState() => _AddStopDialogState();
}

class _AddStopDialogState extends ConsumerState<AddStopDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  List<XFile> _selectedImages = [];
  DateTime? _extractedTime;
  StopType _selectedType = StopType.activity;
  late String? _selectedDayId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDayId = widget.dayId;
    if (widget.existingStop != null) {
        _titleController.text = widget.existingStop!.name;
        _descriptionController.text = widget.existingStop!.notes ?? '';
        _selectedType = widget.existingStop!.type;
        _selectedDayId = widget.existingStop!.dayId;
        // Note: loading existing images is more complex as they are Media objects, not XFiles.
        // For simplicity in this iteration, we don't pre-fill existing images in the picker
        // but users can add more. A full implementation would require mapping Media to a displayable type.
        // However, we can simply NOT show them in the 'selected for upload' list, but they remain in the stop.
        // If the user wants to remove existing photos, that would be done in the Stop Detail screen (out of scope for quick edit).
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        _tryExtractTime(images.first);
      }
    } catch (e) {
      debugPrint('AddStopDialog: Error picking images: $e');
    }
  }

  Future<void> _tryExtractTime(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final data = await readExifFromBytes(bytes);
      
      if (data.containsKey('Image DateTime')) {
        final dateStr = data['Image DateTime']!.toString();
        // Format: YYYY:MM:DD HH:MM:SS
        final parts = dateStr.split(' ');
        final dateParts = parts[0].split(':');
        final timeParts = parts[1].split(':');
        
        final dt = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          int.parse(timeParts[2]),
        );
        
        setState(() {
          _extractedTime = dt;
        });
      }
    } catch (e) {
      debugPrint('Story: Could not extract EXIF data: $e');
    }
  }

  Future<void> _saveStop() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for this stop')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authViewModelProvider);
      final userId = authState.valueOrNull?.id;
      if (userId == null) throw Exception('User not logged in');

      final stopRepo = ref.read(stopRepositoryProvider);
      final mediaRepo = ref.read(mediaRepositoryProvider);

      String stopId;

      if (widget.existingStop != null) {
          // UPDATE Existing
          final updatedStop = Stop(
            id: widget.existingStop!.id,
            userId: userId,
            tripId: widget.tripId,
            dayId: _selectedDayId,
            name: _titleController.text,
            type: _selectedType,
            lat: widget.existingStop!.lat,
            lng: widget.existingStop!.lng,
            visitTime: widget.existingStop!.visitTime,
            notes: _descriptionController.text,
            placeId: widget.existingStop!.placeId,
            isAccommodation: _selectedType == StopType.accommodation,
            stopOrder: widget.existingStop!.stopOrder,
            updatedAt: DateTime.now(),
          );
          await stopRepo.updateStop(updatedStop);
          stopId = updatedStop.id;
      } else {
          // CREATE New
          final stop = Stop.create(
            userId: userId,
            tripId: widget.tripId,
            dayId: _selectedDayId,
            name: _titleController.text,
            type: _selectedType,
            notes: _descriptionController.text,
            isAccommodation: _selectedType == StopType.accommodation,
          );
          stopId = await stopRepo.createStop(stop);
      }

      // 2. Process NEW Media
      for (var xFile in _selectedImages) {
        final media = Media.create(
          userId: userId,
          tripId: widget.tripId,
          stopId: stopId,
          type: MediaType.photo,
          filePath: xFile.path,
        );
        await mediaRepo.createMedia(media);
      }

      await ref.read(activeTripViewModelProvider(widget.tripId).notifier).refresh();
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving stop: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.existingStop != null ? "Edit Stop" : "Add a Stop",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      inherit: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Gap(8),
            Text(
              "Compose a moment with photos and notes",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const Gap(24),

            // Photos Section
            if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primary.withAlpha(30), style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, color: AppTheme.primary, size: 32),
                      const Gap(8),
                      Text(widget.existingStop != null ? "Add More Photos" : "Select Photos", style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, inherit: true)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            
            const Gap(24),

            // Title Input
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, inherit: true),
              decoration: InputDecoration(
                hintText: "What's the highlight?",
                labelText: "Stop Title",
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const Gap(16),

            // Day Select & Type
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedDayId,
                    decoration: InputDecoration(
                      labelText: "Day",
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: widget.days.map((day) => DropdownMenuItem(
                      value: day.id,
                      child: Text("Day ${day.dayNumber}", style: const TextStyle(fontSize: 14, inherit: true)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedDayId = val),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: DropdownButtonFormField<StopType>(
                    isExpanded: true,
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: "Category",
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: StopType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase(), style: const TextStyle(fontSize: 12, inherit: true), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedType = val ?? StopType.activity),
                  ),
                ),
              ],
            ),
            
            const Gap(16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Elaborate on this memory...",
                labelText: "Notes",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const Gap(24),

            // Time indicator (Auto-extracted)
            if (_extractedTime != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.green, size: 18),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        "Time auto-extracted: ${DateFormat('h:mm a').format(_extractedTime!)}",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12, inherit: true),
                      ),
                    ),
                  ],
                ),
              ),

            const Gap(24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.existingStop != null ? "Update Moment" : "Publish This Moment", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, inherit: true)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
