enum SyncEntityType { medication, schedule, reminderSettings, profile }

enum SyncOperationType { create, update, delete }

enum SyncOperationStatus { pending, inFlight, failed }

enum SyncCycleStatus { idle, running, succeeded, failed }

enum SyncTrigger {
  appStartup,
  connectivityRestored,
  userSignIn,
  manualRetry,
  localDataChanged,
}

enum ConflictResolutionStrategy { lastWriteWins }
