// therapist_directory_screen.dart
// Browse all verified therapists with search and filter.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/therapist_model.dart';
import '../../../domain/providers/booking_provider.dart';

class TherapistDirectoryScreen extends ConsumerStatefulWidget {
  const TherapistDirectoryScreen({super.key});

  @override
  ConsumerState<TherapistDirectoryScreen> createState() =>
      _TherapistDirectoryScreenState();
}

class _TherapistDirectoryScreenState
    extends ConsumerState<TherapistDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TherapistModel> _filter(List<TherapistModel> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.specialization.toLowerCase().contains(q) ||
          t.specializedFields.any((f) => f.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final directoryAsync = ref.watch(therapistDirectoryProvider);

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('findATherapist'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            context.tr('takYourTime'),
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: context.tr('searchTherapist'),
                    hintStyle: const TextStyle(
                        color: AppColors.textHint, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textHint, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textHint, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              // List
              Expanded(
                child: directoryAsync.when(
                  data: (therapists) {
                    final filtered = _filter(therapists);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          context.tr('noTherapistsFound'),
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _TherapistCard(
                        therapist: filtered[i],
                        index: i,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.therapistProfile,
                          arguments: filtered[i],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(e.toString(),
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TherapistCard extends StatelessWidget {
  final TherapistModel therapist;
  final int index;
  final VoidCallback onTap;

  const _TherapistCard({
    required this.therapist,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            _TherapistAvatar(therapist: therapist),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    therapist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (therapist.nationality.isNotEmpty ||
                      therapist.yearsOfExperience > 0)
                    Text(
                      [
                        if (therapist.nationality.isNotEmpty)
                          therapist.nationality,
                        if (therapist.yearsOfExperience > 0)
                          '${therapist.yearsOfExperience}y exp',
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (therapist.specializedFields.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: therapist.specializedFields
                          .take(3)
                          .map((f) => _Chip(label: f))
                          .toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Rating
            Column(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.warning, size: 18),
                Text(
                  therapist.rating > 0
                      ? therapist.rating.toStringAsFixed(1)
                      : '–',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 60).ms, duration: 300.ms)
        .slideY(begin: 0.08, end: 0);
  }
}

class _TherapistAvatar extends StatelessWidget {
  final TherapistModel therapist;

  const _TherapistAvatar({required this.therapist});

  @override
  Widget build(BuildContext context) {
    if (therapist.profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(therapist.profileImageUrl),
      );
    }
    final initials = therapist.name.isNotEmpty
        ? therapist.name
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
