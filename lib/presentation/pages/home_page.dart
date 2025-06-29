import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/medication_cubit.dart';
import '../cubit/medication_state.dart';
import '../widgets/medication_card.dart';
import '../../l10n/app_localizations.dart';

import 'add_medication_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final void Function(Locale)? onLocaleChanged;
  const HomePage({super.key, this.onLocaleChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh medications and clean up completed ones
      _cleanupCompletedMedications();
      context.read<MedicationCubit>().loadMedications();
    }
  }

  void _cleanupCompletedMedications() {
    final cubit = context.read<MedicationCubit>();
    cubit.cleanupCompletedMedications();
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
            final activeMeds = state.medications
                .where((m) => m.isActive)
                .toList();

            // Completed medications are automatically cleaned up in the cubit

            // Sort: incomplete for today at top, complete for today at bottom
            activeMeds.sort((a, b) {
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
              itemCount: activeMeds.length,
              itemBuilder: (context, index) {
                final med = activeMeds[index];
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
