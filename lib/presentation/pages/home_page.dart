import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injector.dart';
import 'dart:developer';

import '../cubit/medication_cubit.dart';
import '../cubit/medication_state.dart';
import '../widgets/medication_card.dart';
import 'add_medication_page.dart';
import 'settings_page.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  final Function(Locale) onLocaleChanged;

  const HomePage({super.key, required this.onLocaleChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Timer? _medicationCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicMedicationCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _medicationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, check for daily reset first, then refresh medications
      _handleAppResume();
    }
  }

  void _handleAppResume() async {
    final cubit = context.read<MedicationCubit>();
    // Check for daily reset when app is reopened
    await cubit.checkDailyResetOnAppOpen();
    // Then refresh medications and clean up completed ones
    _cleanupCompletedMedications();
    await cubit.loadMedications();
  }

  void _cleanupCompletedMedications() {
    final cubit = context.read<MedicationCubit>();
    cubit.cleanupCompletedMedications();
  }

  void _startPeriodicMedicationCheck() {
    // Check for due medications every 2 minutes when app is open
    _medicationCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkForDueMedications();
    });
  }

  Future<void> _checkForDueMedications() async {
    try {
      log('🔍 HomePage: Checking for due medications...');
    } catch (e) {
      log('❌ HomePage: Error checking due medications: $e');
      // Don't crash the app, just log the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsPage(onLocaleChanged: widget.onLocaleChanged),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
      body: BlocBuilder<MedicationCubit, MedicationState>(
        builder: (context, state) {
          if (state is MedicationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MedicationLoaded) {
            if (state.medications.isEmpty) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noMedications),
              );
            }
            final now = DateTime.now();

            // Show all medications since users can delete any medication at any time
            final allMeds = state.medications.toList();

            // Sort: incomplete for today at top, complete for today at bottom
            allMeds.sort((a, b) {
              final aTodayDone = a.doses
                  .where(
                    (d) =>
                        d.time != null &&
                        d.time!.year == now.year &&
                        d.time!.month == now.month &&
                        d.time!.day == now.day,
                  )
                  .every((d) => d.taken);
              final bTodayDone = b.doses
                  .where(
                    (d) =>
                        d.time != null &&
                        d.time!.year == now.year &&
                        d.time!.month == now.month &&
                        d.time!.day == now.day,
                  )
                  .every((d) => d.taken);
              if (aTodayDone == bTodayDone) return 0;
              if (aTodayDone) return 1;
              return -1;
            });

            return ListView.builder(
              itemCount: allMeds.length,
              itemBuilder: (context, index) {
                final med = allMeds[index];
                final isTodayComplete = med.doses
                    .where(
                      (d) =>
                          d.time != null &&
                          d.time!.year == now.year &&
                          d.time!.month == now.month &&
                          d.time!.day == now.day,
                    )
                    .every((d) => d.taken);
                return MedicationCard(
                  medication: med,
                  highlight: isTodayComplete,
                  onDoseTaken: (doseIndex) {
                    context.read<MedicationCubit>().markDoseTaken(
                      med.id,
                      doseIndex,
                      true,
                    );
                  },
                  onDelete: () {
                    context.read<MedicationCubit>().deleteMedication(med.id);
                  },
                  onEdit: () async {
                    final updatedMedication = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMedicationPage(medication: med),
                      ),
                    );
                    if (updatedMedication != null && context.mounted) {
                      context.read<MedicationCubit>().addNewMedication(
                        updatedMedication,
                      );
                    }
                  },
                );
              },
            );
          } else if (state is MedicationError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add_medication',
            onPressed: () async {
              final medication = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMedicationPage()),
              );
              if (medication != null && context.mounted) {
                // Add the medication using the cubit
                context.read<MedicationCubit>().addNewMedication(medication);
              }
            },
            tooltip: AppLocalizations.of(context)!.addMedication,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
