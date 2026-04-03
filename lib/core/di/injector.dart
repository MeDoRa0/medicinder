import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/services/sync/conflict_resolver.dart';
import '../../core/services/sync/sync_diagnostics.dart';
import '../../core/services/sync/sync_service.dart';
import '../../core/services/sync/connectivity_signal_service.dart';
import '../../data/datasources/auth/auth_remote_data_source.dart';
import '../../data/datasources/medication_remote_data_source.dart';
import '../../data/datasources/medication_local_data_source.dart';
import '../../data/datasources/sync_state_local_data_source.dart';
import '../../data/datasources/sync_queue_local_data_source.dart';
import '../../data/models/medication_model.dart';
import '../../data/models/sync/conflict_metadata_model.dart';
import '../../data/models/sync/pending_change_model.dart';
import '../../data/models/sync/sync_cycle_state_model.dart';
import '../../data/models/sync/user_sync_profile_model.dart';
import '../../data/models/sync_operation_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/add_medication.dart';
import '../../domain/usecases/sync/sign_in_for_sync.dart';
import '../../domain/usecases/sync/sign_out_from_sync.dart';
import '../../domain/usecases/sync/watch_auth_session.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/update_medication.dart';
import '../../domain/usecases/update_dose_status.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/reset_daily_doses.dart';
import '../../presentation/cubit/medication_cubit.dart';
import '../../presentation/cubit/sync/sync_status_cubit.dart';

import '../services/notification_handler.dart';

final sl = GetIt.instance;

Future<void> initDependencies({
  bool firebaseConfigured = false,
}) async {
  // Initialize Hive
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(MedicationDoseModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MedicationModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(SyncOperationModelAdapter());
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

  // Handle data migration for model structure changes
  Box<MedicationModel> medicationBox;
  Box<SyncOperationModel> syncQueueBox;
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
  syncQueueBox = await Hive.openBox<SyncOperationModel>('sync_queue');
  syncProfileBox = await Hive.openBox<UserSyncProfileModel>('sync_profiles');
  pendingChangeBox = await Hive.openBox<PendingChangeModel>('pending_changes');
  conflictMetadataBox =
      await Hive.openBox<ConflictMetadataModel>('sync_conflicts');
  syncCycleBox = await Hive.openBox<SyncCycleStateModel>('sync_cycles');

  // Data sources
  sl.registerLazySingleton<MedicationLocalDataSource>(
    () => MedicationLocalDataSource(medicationBox),
  );
  sl.registerLazySingleton<SyncQueueLocalDataSource>(
    () => SyncQueueLocalDataSource(syncQueueBox, pendingChangeBox),
  );
  sl.registerLazySingleton<SyncStateLocalDataSource>(
    () => SyncStateLocalDataSource(
      syncProfileBox,
      conflictMetadataBox,
      syncCycleBox,
    ),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => firebaseConfigured
        ? FirebaseAuthRemoteDataSource(
            FirebaseAuth.instance,
            () => FirebaseFirestore.instance,
            sl(),
          )
        : const DisabledAuthRemoteDataSource(),
  );
  sl.registerLazySingleton<MedicationRemoteDataSource>(
    () => firebaseConfigured
        ? FirestoreMedicationRemoteDataSource(() => FirebaseFirestore.instance)
        : const DisabledMedicationRemoteDataSource(),
  );

  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<ConnectivitySignalService>(
    () => ConnectivitySignalService(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(sl(), sl(), sl()),
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
  sl.registerLazySingleton(() => SignInForSync(sl()));
  sl.registerLazySingleton(() => SignOutFromSync(sl()));
  sl.registerLazySingleton(() => WatchAuthSession(sl()));

  // Services
  // sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<NotificationHandler>(() => NotificationHandler());
  sl.registerLazySingleton<SyncDiagnostics>(() => SyncDiagnostics(sl()));
  sl.registerLazySingleton<MedicationConflictResolver>(
    () => const MedicationConflictResolver(),
  );

  // Cubit
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
      syncRepository: sl(),
      syncDiagnostics: sl(),
      connectivitySignal: sl(),
    ),
  );
}
