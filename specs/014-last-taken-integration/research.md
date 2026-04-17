# Research & Decisions: Last Taken Integration

## Bottom Navigation Bar Integration
- **Decision**: Update the existing `Scaffold` in `HomePage` by integrating a stateful `BottomNavigationBar`, adding a "History" tab alongside the main Medication list tab.
- **Rationale**: User explicitly selected Bottom Navigation Bar as the entry point during clarification. It provides top-level access without obscuring content. 
- **Alternatives considered**: App Bar Action Icon or FAB menu. Rejected per user preference.

## Data Fetch Lifecycle Tracking
- **Decision**: Invoke the `loadMedicines()` (or equivalent) fetching logic of the Cubit directly within `initState` of `LastTakenMedicinesPage`.
- **Rationale**: Meets FR-003 without blocking the tab switch route transition. It ensures that the view renders quickly, delegating the loading feedback to a local loading skeleton or spinner inside the page state.
- **Alternatives considered**: Pre-fetching before route push. Rejected because it incurs unneeded UI lock-in on the Home screen.

## Dependency Injection Scope Resolution
- **Decision**: Wrap the root widget for the history tab inside the `home_page` layout with `BlocProvider(create: (_) => GetIt.I<LastTakenMedicinesCubit>())`.
- **Rationale**: Ensures the Cubit instance is strictly scoped, robustly initialized, and available to the tab content, meeting FR-002 without runtime exceptions.
- **Alternatives considered**: Global provider over the entire app. Rejected to adhere to scoped presentation architecture.
