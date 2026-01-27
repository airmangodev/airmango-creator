import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'trip_creation_view_model.dart';
import '../home/home_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';

class TripCreationScreen extends ConsumerStatefulWidget {
  const TripCreationScreen({super.key});

  @override
  ConsumerState<TripCreationScreen> createState() => _TripCreationScreenState();
}

class _TripCreationScreenState extends ConsumerState<TripCreationScreen> {
  late PageController _pageController;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withAlpha(20),
              AppTheme.bgSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, state.currentStep),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: notifier.setStep,
                  children: [
                    _NameStep(controller: _nameController, onNext: _nextPage),
                    _DateStep(onNext: _nextPage, onBack: _previousPage),
                    _TravelersStep(onNext: _nextPage, onBack: _previousPage),
                    _ReviewStep(onBack: _previousPage),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int currentStep) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close),
              ),
              Text(
                "Step ${currentStep + 1} of 4",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              const SizedBox(width: 48), // Spacer
            ],
          ),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 4,
              minHeight: 8,
              backgroundColor: AppTheme.borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameStep extends ConsumerWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const _NameStep({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Where are we\ngoing next?", 
            style: Theme.of(context).textTheme.displaySmall),
          const Gap(32),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: ref.read(tripCreationProvider.notifier).setName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: "e.g. Iceland Road Trip",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.text.length > 2 ? onNext : null,
                child: const Text("Next"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _DateStep({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("When is the\nadventure?", 
            style: Theme.of(context).textTheme.displaySmall),
          const Gap(32),
          Row(
            children: [
              Expanded(
                child: _SelectionCard(
                  label: "Starts",
                  value: state.startDate == null 
                    ? "Select" 
                    : DateFormat('MMM d, y').format(state.startDate!),
                  onTap: () async {
                    final date = await _showPicker(context, state.startDate ?? DateTime.now());
                    if (date != null) {
                      notifier.setDateRange(date, state.endDate ?? date.add(const Duration(days: 7)));
                    }
                  },
                ),
              ),
              const Gap(16),
              Expanded(
                child: _SelectionCard(
                  label: "Ends",
                  value: state.endDate == null 
                    ? "Select" 
                    : DateFormat('MMM d, y').format(state.endDate!),
                  onTap: () async {
                    final date = await _showPicker(context, state.endDate ?? DateTime.now());
                    if (date != null) {
                      notifier.setDateRange(state.startDate ?? date.subtract(const Duration(days: 7)), date);
                    }
                  },
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(onPressed: onBack, child: const Text("Back")),
              const Gap(16),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.startDate != null && state.endDate != null ? onNext : null,
                  child: const Text("Next"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _showPicker(BuildContext context, DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
  }
}

class _TravelersStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _TravelersStep({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How many\ntravelers?", 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Gap(32),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: state.travelers > 1 ? () => notifier.setTravelers(state.travelers - 1) : null,
                    icon: const Icon(Icons.remove_circle, color: AppTheme.primary, size: 32),
                  ),
                  const Gap(24),
                  Text("${state.travelers}", 
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  const Gap(24),
                  IconButton(
                    onPressed: () => notifier.setTravelers(state.travelers + 1),
                    icon: const Icon(Icons.add_circle, color: AppTheme.primary, size: 32),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(onPressed: onBack, child: const Text("Back")),
              const Gap(16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  child: const Text("Final Review"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  final VoidCallback onBack;

  const _ReviewStep({required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripCreationProvider);
    final notifier = ref.read(tripCreationProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ready to go?", 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Gap(32),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _ReviewTile(icon: Icons.map, label: "Destination", value: state.name),
                  const Divider(height: 32),
                  _ReviewTile(
                    icon: Icons.calendar_month, 
                    label: "Dates", 
                    value: state.startDate != null && state.endDate != null 
                        ? "${DateFormat('MMM d').format(state.startDate!)} - ${DateFormat('MMM d, y').format(state.endDate!)}"
                        : "Not selected"
                  ),
                  const Divider(height: 32),
                  _ReviewTile(icon: Icons.people, label: "Group Size", value: "${state.travelers} People"),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(onPressed: onBack, child: const Text("Back")),
              const Gap(16),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () async {
                    final id = await notifier.finalizetrip();
                    if (id != null && context.mounted) {
                      ref.invalidate(homeViewModelProvider);
                      context.go('/trip/$id');
                    }
                  },
                  child: state.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Create Journey"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SelectionCard({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const Gap(4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
