# Last Taken Medicine Feature --- Spec-Kit Plan

## Executive Summary

The **Last Taken Medicine** feature allows users to quickly see which
medications they have taken within the last **24 hours**. This helps
users verify their medication intake and avoid taking duplicate doses.

The feature will use the existing medication tracking system already
implemented in the Medicinder app. When a user marks a medication as
**taken**, the system records the timestamp. The new feature will query
these records and display only those taken within the **last 24 hours**.

The page will present a clear list of medications taken recently,
including the medication name, dose, and the time the medication was
taken.

This feature will be implemented using the **Spec-Kit development
workflow**, divided into multiple phases covering the data layer, domain
logic, UI, integration, and testing.

------------------------------------------------------------------------

# Objectives

## Primary Objectives

-   Allow users to view medications taken within the last **24 hours**
-   Help users confirm if a medication dose has already been taken
-   Reduce the risk of duplicate medication intake
-   Provide a simple medication intake history for the current day

## Secondary Objectives

-   Reuse the existing medication data and logic
-   Maintain consistency with the current UI design
-   Prepare the feature for future **cloud synchronization**

------------------------------------------------------------------------

# Non-Goals

The following capabilities are **not included** in this feature:

-   Full medication history
-   Medication adherence analytics
-   Editing past medication records
-   Medication intake statistics
-   Multi-day history views

These may be implemented as future features.

------------------------------------------------------------------------

# User Story

**As a user**

I want to see which medications I have taken during the last day

So that I can confirm my medication intake and avoid accidentally taking
the same dose twice.

------------------------------------------------------------------------

# Functional Requirements

1.  The system must store the timestamp when a medication dose is marked
    as **taken**.
2.  The system must retrieve medication intake records within the **last
    24 hours**.
3.  The application must display the list of taken medications in the
    UI.
4.  Each medication entry must show:
    -   Medication name
    -   Dose
    -   Time taken
5.  The list must be sorted by **most recent first**.
6.  If no medications were taken during the last 24 hours, an **empty
    state UI** should be shown.
7.  The list must update automatically after a medication is marked as
    taken.

------------------------------------------------------------------------

# Architecture Alignment

This feature must follow the existing architecture used in the
Medicinder app.

## State Management

Cubit-based state management will be used.

Expected cubit:

LastTakenMedicinesCubit

States:

LastTakenMedicinesInitial\
LastTakenMedicinesLoading\
LastTakenMedicinesLoaded\
LastTakenMedicinesError

------------------------------------------------------------------------

## Data Source

Current data source:

Hive local database

Future extension:

Cloud sync storage

The data layer must be designed so cloud sync can be added later without
refactoring the feature.

------------------------------------------------------------------------

## Repository Layer

The medication repository will expose a new method:

getLastTakenMedicines()

This method will:

-   retrieve medication intake records
-   filter records within the last 24 hours
-   sort records by timestamp

------------------------------------------------------------------------

# Data Model Requirements

Each taken medication record must contain:

medicineId\
medicineName\
dose\
takenAt (DateTime)

Optional fields:

medicineColor\
medicineIcon

------------------------------------------------------------------------

# UI Structure

Suggested structure:

LastTakenMedicinesView\
└── LastTakenMedicinesViewBody\
  └── BlocBuilder\
    └── LastTakenMedicinesListView\
      └── TakenMedicineCard

Each card should display:

Medication Name\
Dose Taken\
Time Taken

------------------------------------------------------------------------

# Spec-Kit Implementation Phases

## Phase 1 --- Data Layer

### Objective

Provide access to medications taken during the last 24 hours.

### Tasks

Add repository method:

getLastTakenMedicines()

Implementation details:

-   retrieve medication records from Hive
-   filter records where takenAt \>= now - 24 hours
-   sort results by latest timestamp

### Deliverables

MedicationRepo update\
MedicationRepoImpl implementation\
Hive query logic

------------------------------------------------------------------------

## Phase 2 --- Domain & State Management

### Objective

Provide business logic and state management for retrieving recent
medication intake.

### Tasks

Create cubit:

LastTakenMedicinesCubit

Create states:

LastTakenMedicinesInitial\
LastTakenMedicinesLoading\
LastTakenMedicinesLoaded\
LastTakenMedicinesError

Cubit responsibilities:

-   call repository method
-   handle loading state
-   emit loaded state with medication list
-   handle errors

### Deliverables

LastTakenMedicinesCubit\
LastTakenMedicinesState

------------------------------------------------------------------------

## Phase 3 --- UI Implementation

### Objective

Create the page displaying recently taken medications.

### Tasks

Create the following UI components:

LastTakenMedicinesView\
LastTakenMedicinesViewBody\
LastTakenMedicinesListView\
TakenMedicineCard

Features:

-   vertical list of medications
-   sorted by most recent
-   clear time display
-   empty state UI

Example empty state:

"No medications taken today"

### Deliverables

Complete UI page with BlocBuilder integration.

------------------------------------------------------------------------

## Phase 4 --- Feature Integration

### Objective

Integrate the feature into the main app navigation.

### Tasks

Add navigation entry point.

Possible locations:

Home Screen\
Medication Screen\
History Section

Actions:

-   open LastTakenMedicinesView
-   trigger cubit fetch on page load

### Deliverables

Fully integrated feature accessible from the app UI.

------------------------------------------------------------------------

## Phase 5 --- Testing

### Objective

Ensure the feature behaves correctly.

### Test Cases

1.  Medication taken today appears in the list.
2.  Medication taken more than 24 hours ago does not appear.
3.  Multiple medications are sorted by most recent.
4.  Empty state appears if no medications were taken.
5.  The list updates after marking a medication as taken.

------------------------------------------------------------------------

# Edge Cases

The system must correctly handle:

-   No medications taken
-   Multiple doses taken in a short period
-   App reopened after several hours
-   Device time changes
-   Timezone differences

------------------------------------------------------------------------

# Future Enhancements

Potential improvements:

-   Full medication history page
-   Weekly medication tracking
-   Medication adherence statistics
-   Timeline visualization
-   Cloud synced medication logs
-   Export medication history

------------------------------------------------------------------------

# Success Criteria

The feature will be considered successful if:

-   Users can instantly see medications taken in the last 24 hours
-   The list updates immediately after marking a medication as taken
-   The UI is consistent with the existing application design
-   The feature integrates smoothly with future cloud sync functionality
