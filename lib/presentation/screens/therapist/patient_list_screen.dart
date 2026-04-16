// patient_list_screen.dart
// Lists all patients assigned to the current therapist via a Firestore stream.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/providers/therapist_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/therapist/patient_card.dart';

/// Screen showing the therapist's assigned patient list.
/// Streams live updates from Firestore.
class PatientListScreen extends ConsumerWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(therapistPatientsProvider);

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.myPatients,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              ),

              const SizedBox(height: 16),

              // Patient list
              Expanded(
                child: patientsAsync.when(
                  data: (patients) => _buildList(context, patients),
                  loading: () => const LoadingWidget(),
                  error: (error, _) => _buildError(context, error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<PatientModel> patients) {
    if (patients.isEmpty) {
      return Center(
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text(
              AppStrings.noPatients,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return PatientCard(
          patient: patient,
          index: index,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.patientDetail,
            arguments: patient,
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
