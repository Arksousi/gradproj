// therapist_profile_screen.dart
// Detailed profile view for a therapist — shown before booking.
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/therapist_model.dart';

class TherapistProfileScreen extends StatelessWidget {
  const TherapistProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final therapist =
        ModalRoute.of(context)?.settings.arguments as TherapistModel?;

    if (therapist == null) {
      return const Scaffold(
        body: Center(child: Text('Therapist not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.dark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _Avatar(therapist: therapist),
                      const SizedBox(height: 12),
                      Text(
                        therapist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (therapist.specialization.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          therapist.specialization,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (therapist.rating > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.warning, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${therapist.rating.toStringAsFixed(1)} (${therapist.reviewCount})',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (therapist.bio.isNotEmpty) ...[
                    _SectionTitle(title: 'About'),
                    const SizedBox(height: 8),
                    Text(
                      therapist.bio,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),
                  ],

                  if (therapist.specializedFields.isNotEmpty) ...[
                    _SectionTitle(title: 'Specializations'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: therapist.specializedFields
                          .map((f) => _InfoChip(label: f))
                          .toList(),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 24),
                  ],

                  if (therapist.languages.isNotEmpty) ...[
                    _SectionTitle(title: 'Languages'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: therapist.languages
                          .map((l) => _InfoChip(
                                label: l,
                                color: AppColors.accent,
                              ))
                          .toList(),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),
                  ],

                  if (therapist.sessionTypes.isNotEmpty) ...[
                    _SectionTitle(title: 'Session Types'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: therapist.sessionTypes
                          .map((s) => _InfoChip(
                                label: s,
                                icon: _sessionIcon(s),
                              ))
                          .toList(),
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 24),
                  ],

                  if (therapist.workingHours.isNotEmpty) ...[
                    _SectionTitle(title: 'Working Hours'),
                    const SizedBox(height: 8),
                    ...therapist.workingHours.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (therapist.clinicLocation.isNotEmpty) ...[
                    _SectionTitle(title: 'Clinic Location'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            therapist.clinicLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),
                  ],

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.bookingConsent,
                        arguments: therapist,
                      ),
                      icon: const Icon(Icons.calendar_today_rounded,
                          size: 18),
                      label: Text(context.tr('bookSession')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _sessionIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('video')) return Icons.videocam_rounded;
    if (t.contains('person') || t.contains('in-person')) {
      return Icons.location_on_rounded;
    }
    return Icons.chat_bubble_rounded;
  }
}

class _Avatar extends StatelessWidget {
  final TherapistModel therapist;
  const _Avatar({required this.therapist});

  @override
  Widget build(BuildContext context) {
    if (therapist.profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(therapist.profileImageUrl),
        backgroundColor: Colors.white.withValues(alpha: 0.2),
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
      radius: 44,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const _InfoChip({required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: c, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
