import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';
import '../cubit/medication_cubit.dart';
import '../cubit/medication_state.dart';

class MedicationStatisticsPage extends StatefulWidget {
  const MedicationStatisticsPage({super.key});

  @override
  State<MedicationStatisticsPage> createState() =>
      _MedicationStatisticsPageState();
}

class _MedicationStatisticsPageState extends State<MedicationStatisticsPage> {
  int _selectedPeriod = 30; // Default to 30 days (1 month)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.medicationStatistics),
      ),
      body: BlocBuilder<MedicationCubit, MedicationState>(
        builder: (context, state) {
          if (state is MedicationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MedicationError) {
            return Center(child: Text(AppLocalizations.of(context)!.error(state.message)));
          } else if (state is MedicationLoaded) {
            return _buildStatisticsContent(context, state.medications);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatisticsContent(
      BuildContext context, List<Medication> medications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: _selectedPeriod));
    final endDate = today;

    // Calculate statistics
    final statistics = _calculateStatistics(
      medications,
      startDate,
      endDate,
    );

    if (statistics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noMedicationData,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.takeMedicationsForStats,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Find most taken medication
    final mostTaken = statistics.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    // Calculate percentages
    final totalDoses = statistics.values.fold<int>(0, (sum, count) => sum + count);
    final percentages = statistics.map(
      (key, value) => MapEntry(
        key,
        totalDoses > 0 ? (value / totalDoses * 100) : 0.0,
      ),
    );

    // Sort by count (descending)
    final sortedStats = statistics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _buildPeriodSelector(),
          const SizedBox(height: 24),

          // Most taken medication card
          _buildMostTakenCard(mostTaken, totalDoses),
          const SizedBox(height: 24),

          // Chart
          _buildChartCard(context, percentages),
          const SizedBox(height: 24),

          // Statistics list
          _buildStatisticsList(sortedStats, percentages),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.timePeriod,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPeriodButton(AppLocalizations.of(context)!.days7, 7),
                const SizedBox(width: 8),
                _buildPeriodButton(AppLocalizations.of(context)!.days30, 30),
                const SizedBox(width: 8),
                _buildPeriodButton(AppLocalizations.of(context)!.days90, 90),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, int days) {
    final isSelected = _selectedPeriod == days;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedPeriod = days;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFF71C0B2)
              : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildMostTakenCard(
      MapEntry<String, int> mostTaken, int totalDoses) {
    final percentage = totalDoses > 0
        ? (mostTaken.value / totalDoses * 100).toStringAsFixed(1)
        : '0.0';
    return Card(
      color: const Color(0xFF71C0B2).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: const Color(0xFF71C0B2),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.mostTakenMedication,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              mostTaken.key,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF71C0B2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.dosesTaken(mostTaken.value, percentage),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, Map<String, double> percentages) {
    if (percentages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Prepare data for pie chart
    final chartData = percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 8 for readability
    final displayData = chartData.take(8).toList();
    final otherPercentage = chartData
        .skip(8)
        .fold<double>(0.0, (sum, entry) => sum + entry.value);

    if (otherPercentage > 0) {
      displayData.add(MapEntry(AppLocalizations.of(context)!.other, otherPercentage));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.medicationDistribution,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(displayData),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(displayData),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
      List<MapEntry<String, double>> data) {
    final colors = [
      const Color(0xFF71C0B2),
      const Color(0xFF4A90E2),
      const Color(0xFFF5A623),
      const Color(0xFF7ED321),
      const Color(0xFFBD10E0),
      const Color(0xFF50E3C2),
      const Color(0xFFB8E986),
      const Color(0xFF9013FE),
      Colors.grey,
    ];

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final medicationData = entry.value;
      final color = colors[index % colors.length];

      return PieChartSectionData(
        value: medicationData.value,
        title: '${medicationData.value.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildChartLegend(List<MapEntry<String, double>> data) {
    final colors = [
      const Color(0xFF71C0B2),
      const Color(0xFF4A90E2),
      const Color(0xFFF5A623),
      const Color(0xFF7ED321),
      const Color(0xFFBD10E0),
      const Color(0xFF50E3C2),
      const Color(0xFFB8E986),
      const Color(0xFF9013FE),
      Colors.grey,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final medicationData = entry.value;
        final color = colors[index % colors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${medicationData.key} (${medicationData.value.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatisticsList(
      List<MapEntry<String, int>> statistics, Map<String, double> percentages) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.allMedications,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...statistics.map((entry) {
              final percentage = percentages[entry.key] ?? 0.0;
              return _buildMedicationStatItem(entry.key, entry.value, percentage);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationStatItem(
      String medicationName, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${AppLocalizations.of(context)!.doses} • ${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF71C0B2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStatistics(
    List<Medication> medications,
    DateTime startDate,
    DateTime endDate,
  ) {
    final statistics = <String, int>{};

    for (final medication in medications) {
      int takenCount = 0;

      for (final dose in medication.doses) {
        if (dose.taken && dose.takenDate != null) {
          final takenDate = DateTime(
            dose.takenDate!.year,
            dose.takenDate!.month,
            dose.takenDate!.day,
          );

          // Check if the dose was taken within the selected period (inclusive)
          // Compare dates only (year, month, day)
          if (!takenDate.isBefore(startDate) && !takenDate.isAfter(endDate)) {
            takenCount++;
          }
        }
      }

      if (takenCount > 0) {
        statistics[medication.name] =
            (statistics[medication.name] ?? 0) + takenCount;
      }
    }

    return statistics;
  }
}
