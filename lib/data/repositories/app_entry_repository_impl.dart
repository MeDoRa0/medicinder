import '../../domain/repositories/app_entry_repository.dart';
import '../datasources/auth/app_entry_local_data_source.dart';

class AppEntryRepositoryImpl implements AppEntryRepository {
  final AppEntryLocalDataSource _localDataSource;

  const AppEntryRepositoryImpl(this._localDataSource);

  @override
  Future<void> clearResolvedEntryMode() {
    return _localDataSource.clearResolvedEntryMode();
  }

  @override
  Future<void> persistGuestMode() {
    return _localDataSource.persistResolvedEntryMode('guest');
  }

  @override
  Future<String?> readResolvedEntryMode() async {
    final resolvedMode = _localDataSource.readResolvedEntryMode();
    if (resolvedMode == null || resolvedMode.isEmpty) {
      return null;
    }
    return resolvedMode;
  }
}
