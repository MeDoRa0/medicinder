import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'dart:developer';

import '../../features/medication/presentation/cubit/last_taken_medicines_cubit.dart';
import '../cubit/medication_cubit.dart';
import '../cubit/medication_state.dart';
import 'add_medication_page.dart';
import 'settings_page.dart';
import 'medication_statistics_page.dart';
import '../../l10n/app_localizations.dart';
import 'dart:async';
import '../widgets/medication_list.dart';
import '../widgets/medication_fab.dart';
import '../widgets/sync/sync_status_banner.dart';
import '../last_taken/pages/last_taken_medicines_page.dart';

class HomePage extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  final VoidCallback? onRestartApp;

  const HomePage({super.key, required this.onLocaleChanged, this.onRestartApp});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Timer? _medicationCheckTimer;
  DateTime? _lastCleanupDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastCleanupDate = DateTime.now();
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

  Future<void> _handleAppResume() async {
    final cubit = context.read<MedicationCubit>();
    // Check for daily reset when app is reopened
    await cubit.checkDailyResetOnAppOpen();
    // Then refresh medications and clean up completed ones (await so list reloads after cleanup)
    await cubit.cleanupCompletedMedications();
    await cubit.loadMedications();
  }

  void _startPeriodicMedicationCheck() {
    // Check for due medications and daily cleanup every 1 hour when app is open
    _medicationCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkForDueMedications();
      _checkForNewDayAndCleanup();
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

  void _checkForNewDayAndCleanup() async {
    final now = DateTime.now();
    if (_lastCleanupDate == null ||
        now.year != _lastCleanupDate!.year ||
        now.month != _lastCleanupDate!.month ||
        now.day != _lastCleanupDate!.day) {
      // New day detected
      final cubit = context.read<MedicationCubit>();
      await cubit.checkDailyResetOnAppOpen();
      await cubit.cleanupCompletedMedications();
      await cubit.loadMedications();
      _lastCleanupDate = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => GetIt.I<LastTakenMedicinesCubit>(),
                    child: const LastTakenMedicinesPage(),
                  ),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.lastTakenTitle,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationStatisticsPage(),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.statistics,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    onLocaleChanged: widget.onLocaleChanged,
                    onRestartApp: widget.onRestartApp,
                  ),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: BlocBuilder<MedicationCubit, MedicationState>(
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
                  return MedicationList(
                    medications: state.medications,
                    now: now,
                  );
                } else if (state is MedicationError) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.error(state.message),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
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
