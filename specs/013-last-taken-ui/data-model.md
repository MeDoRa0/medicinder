# Data Model

*Note: This feature is only the UI implementation phase. The persistent data models and domain entities are managed by the Data Layer. The entities listed here represent the UI's View Models consumed from the Cubit.*

## Entities

### `MedicationIntakeRecord` (Domain / View Entity)
Represents the medication taken, provided via the `LastTakenMedicinesCubit` state.

**Fields**:
- `medicineId` : String - Unique identifier for the medication.
- `medicineName` : String - The name of the medication.
- `dose` : String - The dosage amount (e.g. "1 Pill", "5 ml").
- `takenAt` : DateTime - The exact UTC timestamp the medication was taken.

**UI State Transitions**:
- Derived `relativeTimeString`: Computed in the UI layer by comparing `takenAt` to `DateTime.now()` directly before render.
