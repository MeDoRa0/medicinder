import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_cubit.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_state.dart';
import 'package:medicinder/presentation/last_taken/widgets/last_taken_medicines_list.dart';
import 'package:medicinder/presentation/last_taken/widgets/empty_state_widget.dart';
import 'package:medicinder/l10n/app_localizations.dart';

class LastTakenMedicinesPage extends StatefulWidget {
  const LastTakenMedicinesPage({super.key});

  @override
  State<LastTakenMedicinesPage> createState() => _LastTakenMedicinesPageState();
}

class _LastTakenMedicinesPageState extends State<LastTakenMedicinesPage> {
  @override
  void initState() {
    super.initState();
    context.read<LastTakenMedicinesCubit>().watchRecentMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.lastTakenTitle),
      ),
      body: BlocBuilder<LastTakenMedicinesCubit, LastTakenMedicinesState>(
        builder: (context, state) {
          if (state is LastTakenMedicinesLoading || state is LastTakenMedicinesInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is LastTakenMedicinesError) {
            return Center(child: Text(AppLocalizations.of(context)!.unknownError));
          } else if (state is LastTakenMedicinesLoaded) {
            if (state.medications.isEmpty) {
              return const EmptyStateWidget();
            }
            return LastTakenMedicinesList(medications: state.medications);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
