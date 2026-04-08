import 'package:equatable/equatable.dart';

import 'app_entry_session.dart';

enum LaunchDestination { entryGate, initialSettings, home }

class LaunchRouteDecision extends Equatable {
  final LaunchDestination destination;
  final AppEntrySession session;
  final bool mealTimesConfigured;

  const LaunchRouteDecision({
    required this.destination,
    required this.session,
    required this.mealTimesConfigured,
  });

  @override
  List<Object?> get props => [destination, session, mealTimesConfigured];
}
