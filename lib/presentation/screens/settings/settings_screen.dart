// settings_screen.dart
// Unified settings screen for both patients and therapists.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/repositories/therapist_repository.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/locale_provider.dart';
import '../../../domain/providers/therapist_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeProvider);
    final isTherapist = user?.role == 'therapist';

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
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
                      Text(
                        context.tr('settings'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Profile card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _ProfileCard(
                    name: user?.name ?? '',
                    email: user?.email ?? '',
                    role: user?.role ?? '',
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Language
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SectionLabel(label: context.tr('language')),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _LanguageSelector(
                    currentLocale: locale,
                    onSelect: (l) =>
                        ref.read(localeProvider.notifier).setLocale(l),
                  ),
                ).animate().fadeIn(delay: 150.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Availability (therapists only)
              if (isTherapist) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child:
                        _SectionLabel(label: context.tr('availability')),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AvailabilitySection(uid: user!.uid)
                      .animate()
                      .fadeIn(delay: 200.ms),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // Account
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SectionLabel(label: context.tr('account')),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _AccountSection(email: user?.email ?? ''),
                ).animate().fadeIn(delay: 250.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Danger zone
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SectionLabel(
                    label: context.tr('dangerZone'),
                    color: AppColors.error,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _DangerSection(),
                ).animate().fadeIn(delay: 300.ms),
              ),

              // Version
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      context.tr('version'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;

  const _ProfileCard(
      {required this.name, required this.email, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    role.isNotEmpty
                        ? role[0].toUpperCase() + role.substring(1)
                        : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language selector
// ---------------------------------------------------------------------------

class _LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onSelect;

  const _LanguageSelector(
      {required this.currentLocale, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _LangTab(
            label: 'English',
            isSelected: currentLocale.languageCode == 'en',
            onTap: () => onSelect(const Locale('en')),
          ),
          _LangTab(
            label: 'العربية',
            isSelected: currentLocale.languageCode == 'ar',
            onTap: () => onSelect(const Locale('ar')),
          ),
        ],
      ),
    );
  }
}

class _LangTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangTab(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Availability (therapists)
// ---------------------------------------------------------------------------

class _AvailabilitySection extends ConsumerWidget {
  final String uid;
  const _AvailabilitySection({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapistAsync = ref.watch(currentTherapistProvider);

    return therapistAsync.when(
      data: (therapist) {
        if (therapist == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ToggleTile(
                  icon: Icons.work_rounded,
                  title: context.tr('onShift'),
                  subtitle: context.tr('onShiftSub'),
                  value: therapist.isOnShift,
                  onChanged: (v) => TherapistRepository()
                      .updateAvailability(uid, isOnShift: v),
                ),
                const Divider(
                    height: 1,
                    color: AppColors.border,
                    indent: 56,
                    endIndent: 16),
                _ToggleTile(
                  icon: Icons.bolt_rounded,
                  title: context.tr('availableForImmediate'),
                  subtitle: context.tr('availableForImmediateSub'),
                  value: therapist.isAvailableForImmediate,
                  onChanged: (v) => TherapistRepository()
                      .updateAvailability(uid, isAvailableForImmediate: v),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account section
// ---------------------------------------------------------------------------

class _AccountSection extends ConsumerWidget {
  final String email;
  const _AccountSection({required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.lock_reset_rounded,
            title: context.tr('resetPassword'),
            subtitle: context.tr('resetPasswordSub'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final sentLabel = context.tr('resetLinkSent');
              final failLabel = context.tr('failedTo');
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                messenger.showSnackBar(SnackBar(
                  content: Text('$sentLabel $email'),
                  backgroundColor: AppColors.success,
                ));
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text('$failLabel $e'),
                  backgroundColor: AppColors.error,
                ));
              }
            },
          ),
          const Divider(
              height: 1,
              color: AppColors.border,
              indent: 56,
              endIndent: 16),
          _ActionTile(
            icon: Icons.privacy_tip_rounded,
            title: context.tr('privacyPolicy'),
            subtitle: context.tr('app'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Danger zone
// ---------------------------------------------------------------------------

class _DangerSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.logout_rounded,
            title: context.tr('signOut'),
            iconColor: AppColors.error,
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (_) => false);
              }
            },
          ),
          const Divider(
              height: 1,
              color: AppColors.border,
              indent: 56,
              endIndent: 16),
          _ActionTile(
            icon: Icons.delete_forever_rounded,
            title: context.tr('deleteAccount'),
            subtitle: context.tr('deleteAccountSub'),
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('deleteConfirmTitle')),
        content: Text(context.tr('deleteConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('close')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final failLabel = context.tr('failedDelete');
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.login, (_) => false);
                }
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text('$failLabel $e'),
                  backgroundColor: AppColors.error,
                ));
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ic.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: ic, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
