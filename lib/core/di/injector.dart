import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/datasources/medication_local_data_source.dart';
import '../../data/models/medication_model.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/usecases/add_medication.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/update_dose_status.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../presentation/cubit/medication_cubit.dart';

import '../services/notification_handler.dart';


final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Initialize Hive
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(MedicationDoseModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MedicationModelAdapter());
  }

  // Handle data migration for model structure changes
  Box<MedicationModel> medicationBox;
  try {
    medicationBox = await Hive.openBox<MedicationModel>('medications');
  } catch (e) {
    // If there's an error reading the box (likely due to model structure change),
    // delete the existing box and create a new one
    try {
      await Hive.deleteBoxFromDisk('medications');
    } catch (deleteError) {
      // Box might not exist, which is fine
      print('Box deletion error (likely box doesn\'t exist): $deleteError');
    }
    medicationBox = await Hive.openBox<MedicationModel>('medications');
  }

  // Data sources
  sl.registerLazySingleton<MedicationLocalDataSource>(
    () => MedicationLocalDataSource(medicationBox),
  );

  // Repositories
  sl.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => AddMedication(sl()));
  sl.registerLazySingleton(() => GetMedications(sl()));
  sl.registerLazySingleton(() => UpdateDoseStatus(sl()));
  sl.registerLazySingleton(() => DeleteMedication(sl()));

  // Services
  // sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<NotificationHandler>(() => NotificationHandler());


  // Cubit
  sl.registerFactory(
    () => MedicationCubit(
      addMedication: sl(),
      getMedications: sl(),
      updateDoseStatus: sl(),
      deleteMedication: sl(),
    ),
  );
}
