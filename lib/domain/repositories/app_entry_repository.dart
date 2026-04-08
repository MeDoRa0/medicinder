abstract class AppEntryRepository {
  Future<String?> readResolvedEntryMode();
  Future<void> persistGuestMode();
  Future<void> clearResolvedEntryMode();
}
