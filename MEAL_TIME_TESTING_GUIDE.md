# Meal Time Calculation Testing Guide

## Issue Fixed
When users created medications with meal-based timing (e.g., "before breakfast by 15 minutes"), the system was setting the time to the meal time (8:00) instead of calculating the correct offset time (7:45).

## Root Cause
1. **Add Medication Page**: The calculation logic was correct, but there was no default offset value
2. **Notification Service**: Was using hardcoded meal times instead of the pre-calculated times from the medication doses

## Changes Made
1. **Fixed default offset**: Now defaults to 15 minutes if no offset is selected
2. **Added debugging**: Console logs show the calculation process
3. **Fixed notification service**: Now uses pre-calculated times from medication doses instead of recalculating

## How to Test

### Test Case 1: Before Breakfast with 15-minute offset
1. Go to Settings and set breakfast time to 8:00 AM
2. Add a new medication
3. Select "Before/After Meals" timing
4. Select "Before Breakfast" 
5. Set offset to 15 minutes
6. Save the medication
7. **Expected Result**: 
   - Console should show: "AddMedicationPage: Meal time: 8:0"
   - Console should show: "AddMedicationPage: Offset: 15 minutes"
   - Console should show: "AddMedicationPage: Before meal - subtracting 15 minutes"
   - Console should show: "AddMedicationPage: Final dose time: 7:45"
   - Medication card should show "7:45 AM" for the dose

### Test Case 2: After Lunch with 30-minute offset
1. Go to Settings and set lunch time to 1:00 PM
2. Add a new medication
3. Select "Before/After Meals" timing
4. Select "After Lunch"
5. Set offset to 30 minutes
6. Save the medication
7. **Expected Result**:
   - Console should show: "AddMedicationPage: Meal time: 13:0"
   - Console should show: "AddMedicationPage: Offset: 30 minutes"
   - Console should show: "AddMedicationPage: After meal - adding 30 minutes"
   - Console should show: "AddMedicationPage: Final dose time: 13:30"
   - Medication card should show "1:30 PM" for the dose

### Test Case 3: Multiple meal contexts
1. Add a medication with multiple meal contexts:
   - Before Breakfast (15 min offset)
   - After Dinner (60 min offset)
2. **Expected Result**:
   - Should show two doses with correct calculated times
   - Before Breakfast: 7:45 AM (if breakfast is 8:00)
   - After Dinner: 8:00 PM (if dinner is 7:00)

### Test Case 4: Notification scheduling
1. Create a medication with meal-based timing
2. Check console logs for notification scheduling
3. **Expected Result**:
   - Console should show: "NotificationService: Using pre-calculated time for [medication name]: [calculated time]"
   - Notifications should be scheduled at the calculated time, not the meal time

## Debug Information
Check the console logs for these messages:

**Add Medication Page:**
- `AddMedicationPage: Loading meal times from SharedPreferences`
- `AddMedicationPage: Breakfast time: [hour]:[minute]`
- `AddMedicationPage: Calculating dose time for [context]`
- `AddMedicationPage: Meal time: [hour]:[minute]`
- `AddMedicationPage: Offset: [minutes] minutes`
- `AddMedicationPage: Before/After meal - [adding/subtracting] [minutes] minutes`
- `AddMedicationPage: Final dose time: [hour]:[minute]`

**Notification Service:**
- `NotificationService: Using pre-calculated time for [medication name]: [hour]:[minute]`

## Expected Behavior
- ✅ **Correct time calculation**: "Before breakfast by 15 minutes" should result in 7:45 AM (not 8:00 AM)
- ✅ **Proper offset application**: Offsets should be correctly added/subtracted from meal times
- ✅ **Notification scheduling**: Notifications should be scheduled at calculated times
- ✅ **Visual display**: Medication cards should show the correct calculated times
- ✅ **Debug logging**: Console should show the calculation process

## Troubleshooting
If the issue persists:

1. **Check meal times**: Ensure meal times are properly saved in Settings
2. **Verify offset selection**: Make sure the offset dropdown is working
3. **Check console logs**: Look for the debug messages above
4. **Test with different offsets**: Try 15, 30, and 60-minute offsets
5. **Clear app data**: If needed, clear SharedPreferences to reset meal times 