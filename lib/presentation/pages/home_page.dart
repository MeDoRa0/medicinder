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
  int _currentIndex = 0;

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
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    final cubit = context.read<MedicationCubit>();
    await cubit.checkDailyResetOnAppOpen();
    await cubit.cleanupCompletedMedications();
    await cubit.loadMedications();
  }

  void _startPeriodicMedicationCheck() {
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
    }
  }

  void _checkForNewDayAndCleanup() async {
    final now = DateTime.now();
    if (_lastCleanupDate == null ||
        now.year != _lastCleanupDate!.year ||
        now.month != _lastCleanupDate!.month ||
        now.day != _lastCleanupDate!.day) {
      final cubit = context.read<MedicationCubit>();
      await cubit.checkDailyResetOnAppOpen();
      await cubit.cleanupCompletedMedications();
      await cubit.loadMedications();
      _lastCleanupDate = now;
    }
  }

  Widget _buildTabContent() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        Column(
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
        BlocProvider(
          create: (_) => GetIt.I<LastTakenMedicinesCubit>(),
          child: const LastTakenMedicinesPage(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: _currentIndex == 0 ? AppBar(
          title: Text(AppLocalizations.of(context)!.homeTitle),
          actions: [
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
        ) : null,
        body: _buildTabContent(),
        floatingActionButton: _currentIndex == 0 ? MedicationFAB(
          onAddMedication: () async {
            final medication = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddMedicationPage()),
            );
            if (medication != null && context.mounted) {
              context.read<MedicationCubit>().addNewMedication(medication);
            }
          },
        ) : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.medical_services),
              label: AppLocalizations.of(context)!.homeTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: AppLocalizations.of(context)!.lastTakenNavTitle,
            ),
          ],
        ),
      ),
    );
  }
}
