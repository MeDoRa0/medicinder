import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/sync/conflict_resolver.dart';
import '../../core/services/sync/sync_diagnostics.dart';
import '../../core/services/sync/sync_service.dart';
import '../../core/services/sync/connectivity_signal_service.dart';
import '../../core/services/sync/notification_sync_service.dart';
import '../../core/services/notification_optimizer.dart';
import '../../data/datasources/auth/auth_remote_data_source.dart';
import '../../data/datasources/auth/app_entry_local_data_source.dart';
import '../../data/datasources/auth/apple_auth_provider_data_source.dart';
import '../../data/datasources/auth/google_auth_provider_data_source.dart';
import '../../data/datasources/medication_remote_data_source.dart';
import '../../data/datasources/medication_local_data_source.dart';
import '../../data/datasources/medication_history_local_data_source.dart';
import '../../data/datasources/sync_state_local_data_source.dart';
import '../../data/datasources/sync_queue_local_data_source.dart';
import '../../data/models/medication_model.dart';
import '../../data/models/medication_history_model.dart';
import '../../data/models/sync/conflict_metadata_model.dart';
import '../../data/models/sync/pending_change_model.dart';
import '../../data/models/sync/sync_cycle_state_model.dart';
import '../../data/models/sync/user_sync_profile_model.dart';
import '../../data/models/sync_operation_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/app_entry_repository_impl.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/app_entry_repository.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/add_medication.dart';
import '../../domain/usecases/auth/clear_app_entry_state.dart';
import '../../domain/usecases/auth/continue_as_guest.dart';
import '../../domain/usecases/auth/restore_app_entry_session.dart';
import '../../domain/usecases/auth/sign_in_with_apple.dart';
import '../../domain/usecases/auth/sign_in_with_google.dart';
import '../../domain/usecases/sync/sign_in_for_sync.dart';
import '../../domain/usecases/sync/sign_out_from_sync.dart';
import '../../domain/usecases/sync/watch_auth_session.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/update_medication.dart';
import '../../domain/usecases/update_dose_status.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/reset_daily_doses.dart';
import '../../presentation/cubit/auth/auth_entry_cubit.dart';
import '../../presentation/cubit/medication_cubit.dart';
import '../../presentation/cubit/sync/sync_status_cubit.dart';
import '../../features/medication/presentation/cubit/last_taken_medicines_cubit.dart';

import '../services/notification_handler.dart';

final sl = GetIt.instance;

Future<void> initDependencies({bool firebaseConfigured = false}) async {
  if (sl.isRegistered<SharedPreferences>()) {
    sl.unregister<SharedPreferences>();
  }
  sl.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );

  // Initialize Hive
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(MedicationDoseModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MedicationModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(UserSyncProfileModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(PendingChangeModelAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(ConflictMetadataModelAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(SyncCycleStateModelAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(MedicationHistoryModelAdapter());
  }

  // Handle data migration for model structure changes
  Box<MedicationModel> medicationBox;
  Box<UserSyncProfileModel> syncProfileBox;
  Box<PendingChangeModel> pendingChangeBox;
  Box<ConflictMetadataModel> conflictMetadataBox;
  Box<SyncCycleStateModel> syncCycleBox;
  try {
    medicationBox = await Hive.openBox<MedicationModel>('medications');
  } catch (e) {
    // If there's an error reading the box (likely due to model structure change),
    // delete the existing box and create a new one
    try {
      await Hive.deleteBoxFromDisk('medications');
    } catch (deleteError) {
      // Box might not exist, which is fine
    }
    medicationBox = await Hive.openBox<MedicationModel>('medications');
  }

  syncProfileBox = await Hive.openBox<UserSyncProfileModel>('sync_profiles');
  pendingChangeBox = await Hive.openBox<PendingChangeModel>('pending_changes');
  conflictMetadataBox = await Hive.openBox<ConflictMetadataModel>(
    'sync_conflicts',
  );
  syncCycleBox = await Hive.openBox<SyncCycleStateModel>('sync_cycles');

  final legacySyncOperationBox = await Hive.openBox<SyncOperationModel>(
    'sync_operations_legacy',
  );

  final medicationHistoryBox = await Hive.openBox<MedicationHistoryModel>(
    'medication_history',
  );

  // Migrate legacy sync_queue box (no longer needed after PendingChange migration)
  try {
    if (await Hive.boxExists('sync_queue')) {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(_LegacySyncOperationAdapter());
      }
      final legacyBox = await Hive.openBox<Map<dynamic, dynamic>>('sync_queue');

      for (final key in legacyBox.keys) {
        final legacyMap = legacyBox.get(key);
        if (legacyMap == null) continue;

        final changeId = legacyMap['id'] as String?;
        final operationIndex = legacyMap['typeIndex'] as int?;
        final entityId = legacyMap['entityId'] as String?;
        final entityTypeIndex = legacyMap['entityTypeIndex'] as int?;
        final queuedAt = legacyMap['createdAt'] as DateTime?;

        if (changeId == null ||
            operationIndex == null ||
            entityId == null ||
            entityTypeIndex == null ||
            queuedAt == null) {
          continue;
        }

        Map<String, dynamic>? payload;

        // operationIndex: 0 = create, 1 = update, 2 = delete
        if (operationIndex == 0 || operationIndex == 1) {
          try {
            final medication = medicationBox.values.firstWhere(
              (m) => m.id == entityId,
            );
            payload = medication.toEntity().toMap();
          } catch (_) {
            continue;
          }
        }

        final changeModel = PendingChangeModel(
          changeId: changeId,
          entityTypeIndex: entityTypeIndex,
          entityId: entityId,
          operationIndex: operationIndex,
          queuedAt: queuedAt,
          sourceUpdatedAt: queuedAt,
          payload: payload,
          attemptCount: (legacyMap['attemptCount'] as int?) ?? 0,
          lastAttemptAt: legacyMap['lastAttemptAt'] as DateTime?,
          errorMessage: legacyMap['errorMessage'] as String?,
          statusIndex: 0,
        );

        await pendingChangeBox.put(changeModel.changeId, changeModel);
      }
      await legacyBox.clear();
      await legacyBox.close();
      await Hive.deleteBoxFromDisk('sync_queue');
    }
  } catch (_) {
    try {
      await Hive.deleteBoxFromDisk('sync_queue');
    } catch (_) {}
  }

  // Data sources
  sl.registerLazySingleton<MedicationLocalDataSource>(
    () => MedicationLocalDataSource(medicationBox),
  );
  sl.registerLazySingleton<MedicationHistoryLocalDataSource>(
    () => MedicationHistoryLocalDataSource(medicationHistoryBox),
  );
  sl.registerLazySingleton<SyncQueueLocalDataSource>(
    () => SyncQueueLocalDataSource(legacySyncOperationBox, pendingChangeBox),
  );
  sl.registerLazySingleton<SyncStateLocalDataSource>(
    () => SyncStateLocalDataSource(
      syncProfileBox,
      conflictMetadataBox,
      syncCycleBox,
    ),
  );
  sl.registerLazySingleton<GoogleAuthProviderDataSource>(
    () => PlatformGoogleAuthProviderDataSource(),
  );
  sl.registerLazySingleton<AppleAuthProviderDataSource>(
    () => PlatformAppleAuthProviderDataSource(),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => firebaseConfigured
        ? FirebaseAuthRemoteDataSource(
            FirebaseAuth.instance,
            () => FirebaseFirestore.instance,
            sl(),
            sl(),
            sl(),
          )
        : const DisabledAuthRemoteDataSource(),
  );
  sl.registerLazySingleton<MedicationRemoteDataSource>(
    () => firebaseConfigured
        ? FirestoreMedicationRemoteDataSource(() => FirebaseFirestore.instance)
        : const DisabledMedicationRemoteDataSource(),
  );
  sl.registerLazySingleton<AppEntryLocalDataSource>(
    () => AppEntryLocalDataSource(sl()),
  );

  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<ConnectivitySignalService>(
    () => ConnectivitySignalService(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AppEntryRepository>(
    () => AppEntryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<SyncRepository>(
    () => SyncService(
      authRepository: sl(),
      medicationRepository: sl(),
      remoteDataSource: sl(),
      syncQueue: sl(),
      conflictResolver: sl(),
      syncState: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AddMedication(sl()));
  sl.registerLazySingleton(() => GetMedications(sl()));
  sl.registerLazySingleton(() => UpdateMedication(sl()));
  sl.registerLazySingleton(() => UpdateDoseStatus(sl()));
  sl.registerLazySingleton(() => DeleteMedication(sl()));
  sl.registerLazySingleton(() => ResetDailyDoses(sl()));
  sl.registerLazySingleton(() => RestoreAppEntrySession(sl(), sl()));
  sl.registerLazySingleton(() => ContinueAsGuest(sl()));
  sl.registerLazySingleton(() => ClearAppEntryState(sl()));
  sl.registerLazySingleton(() => SignInWithApple(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInForSync(sl()));
  sl.registerLazySingleton(() => SignOutFromSync(sl()));
  sl.registerLazySingleton(() => WatchAuthSession(sl()));

  // Services
  // sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<NotificationHandler>(() => NotificationHandler());
  sl.registerLazySingleton<SyncDiagnostics>(() => SyncDiagnostics(sl()));
  sl.registerLazySingleton<NotificationSyncService>(
    () => NotificationSyncService(
      medicationRepository: sl(),
      notificationOptimizer: NotificationOptimizer(),
      syncDiagnostics: sl(),
    ),
  );
  sl.registerLazySingleton<MedicationConflictResolver>(
    () => const MedicationConflictResolver(),
  );

  // Cubit
  sl.registerFactory(
    () => AuthEntryCubit(
      restoreAppEntrySession: sl(),
      continueAsGuest: sl(),
      clearAppEntryState: sl(),
      signInWithApple: sl(),
      signInWithGoogle: sl(),
    ),
  );
  sl.registerFactory(
    () => MedicationCubit(
      addMedication: sl(),
      getMedications: sl(),
      updateMedication: sl(),
      updateDoseStatus: sl(),
      deleteMedication: sl(),
      resetDailyDoses: sl(),
    ),
  );
  sl.registerFactory(
    () => SyncStatusCubit(
      signInForSync: sl(),
      signOutFromSync: sl(),
      watchAuthSession: sl(),
      clearAppEntryState: sl(),
      syncRepository: sl(),
      syncDiagnostics: sl(),
      connectivitySignal: sl(),
      syncQueue: sl(),
      notificationSyncService: sl(),
    ),
  );
  sl.registerFactory(
    () => LastTakenMedicinesCubit(
      repository: sl(),
    ),
  );
}

class _LegacySyncOperationAdapter extends TypeAdapter<Map<dynamic, dynamic>> {
  @override
  final int typeId = 2;

  @override
  Map<dynamic, dynamic> read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return {
      'id': fields[0],
      'entityTypeIndex': fields[1],
      'entityId': fields[2],
      'typeIndex': fields[3],
      'createdAt': fields[4],
      'lastAttemptAt': fields[5],
      'attemptCount': fields[6],
      'errorMessage': fields[7],
    };
  }

  @override
  void write(BinaryWriter writer, Map<dynamic, dynamic> obj) {}
}
