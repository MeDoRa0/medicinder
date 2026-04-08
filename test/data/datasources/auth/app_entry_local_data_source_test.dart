import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/datasources/auth/app_entry_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppEntryLocalDataSource', () {
    test('reads null when no resolved entry mode is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final dataSource = AppEntryLocalDataSource(preferences);

      expect(dataSource.readResolvedEntryMode(), isNull);
    });

    test('persists and restores the guest marker', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final dataSource = AppEntryLocalDataSource(preferences);

      await dataSource.persistResolvedEntryMode('guest');

      expect(dataSource.readResolvedEntryMode(), 'guest');
    });

    test('clears the stored entry mode', () async {
      SharedPreferences.setMockInitialValues({
        AppEntryLocalDataSource.resolvedEntryModeKey: 'guest',
      });
      final preferences = await SharedPreferences.getInstance();
      final dataSource = AppEntryLocalDataSource(preferences);

      await dataSource.clearResolvedEntryMode();

      expect(dataSource.readResolvedEntryMode(), isNull);
    });
  });
}
