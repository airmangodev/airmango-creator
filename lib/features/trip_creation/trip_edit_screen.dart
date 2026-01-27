import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'trip_creation_view_model.dart';
import '../home/home_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';

class TripEditScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripEditScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripEditScreen> createState() => _TripEditScreenState();
}

class _TripEditScreenState extends ConsumerState<TripEditScreen> {
  late TextEditingController _nameController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    // Load trip data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripCreationProvider.notifier).loadTripForEditing(widget.tripId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    // Initialize text controller with loaded data
    if (!_initialized && state.name.isNotEmpty) {
      _nameController.text = state.name;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text("Edit Trip", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          TextButton(
            onPressed: state.isLoading ? null : () async {
              final id = await notifier.finalizetrip();
              if (id != null && context.mounted) {
                ref.invalidate(homeViewModelProvider);
                context.pop();
              }
            },
            child: state.isLoading 
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: state.isLoading && !_initialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Trip Name", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const Gap(8),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _nameController,
                        onChanged: notifier.setName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: "e.g. Iceland Road Trip",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const Gap(24),
                  const Text("Dates", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerCard(
                          label: "Start",
                          date: state.startDate,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: state.startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              notifier.setDateRange(date, state.endDate ?? date.add(const Duration(days: 7)));
                            }
                          },
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _DatePickerCard(
                          label: "End",
                          date: state.endDate,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: state.endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              notifier.setDateRange(state.startDate ?? date.subtract(const Duration(days: 7)), date);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const Gap(24),
                  const Text("Travelers", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const Gap(8),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: state.travelers > 1 ? () => notifier.setTravelers(state.travelers - 1) : null,
                            icon: const Icon(Icons.remove_circle, color: AppTheme.primary, size: 32),
                          ),
                          const Gap(24),
                          Text("${state.travelers}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const Gap(24),
                          IconButton(
                            onPressed: () => notifier.setTravelers(state.travelers + 1),
                            icon: const Icon(Icons.add_circle, color: AppTheme.primary, size: 32),
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
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerCard({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const Gap(4),
              Text(
                date != null ? DateFormat('MMM d, y').format(date!) : "Select",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
