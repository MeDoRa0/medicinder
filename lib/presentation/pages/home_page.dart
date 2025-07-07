import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer';

import '../cubit/medication_cubit.dart';
import '../cubit/medication_state.dart';
import 'add_medication_page.dart';
import 'settings_page.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../widgets/medication_list.dart';
import '../widgets/medication_fab.dart';

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
            return MedicationList(medications: state.medications, now: now);
          } else if (state is MedicationError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: MedicationFAB(
        onAddMedication: () async {
          final medication = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationPage()),
          );
          if (medication != null && context.mounted) {
            context.read<MedicationCubit>().addNewMedication(medication);
          }
        },
      ),
    );
  }
}
