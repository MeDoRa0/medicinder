import '../../repositories/app_entry_repository.dart';

class ClearAppEntryState {
  final AppEntryRepository _repository;

  const ClearAppEntryState(this._repository);

  Future<void> call() => _repository.clearResolvedEntryMode();
}
