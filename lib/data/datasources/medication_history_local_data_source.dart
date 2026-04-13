import 'package:hive/hive.dart';
import '../models/medication_history_model.dart';

class MedicationHistoryLocalDataSource {
  final Box<MedicationHistoryModel> _box;

  MedicationHistoryLocalDataSource(this._box);

  Future<void> addHistoryRecord(MedicationHistoryModel record) async {
    // Generate a unique ID, or just add
    await _box.add(record);
  }

  Future<List<MedicationHistoryModel>> getHistoryRecords() async {
    return _box.values.toList();
  }

  Future<void> clearHistory() async {
    await _box.clear();
  }
}
