enum SyncEntityType { medication, schedule, reminderSettings, profile }

enum SyncOperationType { create, update, delete }

enum SyncOperationStatus { pending, inFlight, failed }

enum SyncTrigger { appStartup, connectivityRestored, userSignIn, manualRetry }

enum ConflictResolutionStrategy { lastWriteWins }
