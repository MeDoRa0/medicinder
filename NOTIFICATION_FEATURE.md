# Medication Notification Feature

This document describes the medication notification feature implemented in the Medicinder app.

## Overview

The notification feature provides medication reminders with the following capabilities:

- **Persistent Notifications**: Notifications stay visible until the user takes action
- **Action Buttons**: Two action buttons - "Done" and "Remind Me Later"
- **Background Processing**: Works even when the app is closed
- **Automatic Scheduling**: Notifications are automatically scheduled when medications are added

## Features

### 1. Notification Actions

- **Done**: Marks the dose as taken and cancels the notification
- **Remind Me Later**: Reschedules the notification for 15 minutes later

### 2. Persistent Notifications

- Notifications are configured as "ongoing" and "autoCancel: false"
- They will continue to ring and stay visible until user interaction
- High priority notifications that can wake the device

### 3. Background Processing

- Uses WorkManager for periodic background tasks
- Checks for due medications every 15 minutes
- Processes notifications even when the app is not running

### 4. Automatic Scheduling

- Notifications are automatically scheduled when medications are added
- Notifications are cancelled when medications are deleted or doses are marked as taken
- Supports both specific time and context-based medication timing

## Implementation Details

### Core Services

1. **NotificationService** (`lib/core/services/notification_service.dart`)
   - Handles local notification scheduling and management
   - Creates notification channels for Android
   - Manages notification lifecycle

2. **NotificationHandler** (`lib/core/services/notification_handler.dart`)
   - Processes notification action responses
   - Updates medication dose status when "Done" is pressed
   - Reschedules notifications when "Remind Me Later" is pressed

3. **NotificationProcessor** (`lib/core/services/notification_processor.dart`)
   - Handles pending notifications when the app starts
   - Processes background notifications

4. **BackgroundService** (`lib/core/services/background_service.dart`)
   - Manages background tasks using WorkManager
   - Checks for due medications periodically
   - Queues notifications for processing

### Integration Points

- **MedicationCubit**: Integrates with notification services to schedule/cancel notifications
- **Main App**: Initializes all notification services on app startup
- **Dependency Injection**: All services are registered in the DI container

### Platform Configuration

#### Android
- Added notification permissions in `AndroidManifest.xml`
- Configured notification channels with high priority
- Added background processing permissions

#### iOS
- Added notification permissions in `Info.plist`
- Configured background modes for notifications
- Added usage description for notifications

## Testing

A notification test page is available in the settings menu that allows users to:

1. Schedule a test notification (appears in 10 seconds)
2. View pending notifications
3. Cancel all notifications

## Usage

### For Users

1. **Adding Medications**: Notifications are automatically scheduled when medications are added
2. **Taking Medications**: Press "Done" on the notification to mark the dose as taken
3. **Delaying**: Press "Remind Me Later" to be reminded again in 15 minutes
4. **Testing**: Use the "Test Notifications" button in Settings to test the system

### For Developers

1. **Adding New Notification Types**: Extend the `NotificationService` class
2. **Modifying Actions**: Update the `NotificationHandler` class
3. **Background Processing**: Modify the `BackgroundService` class
4. **Testing**: Use the `NotificationTestPage` for testing

## Technical Notes

- Notifications use timezone-aware scheduling
- Background tasks run every 15 minutes to check for due medications
- Notification IDs are generated based on medication ID and dose index
- All notification data is stored in SharedPreferences for background processing
- The system handles app lifecycle changes gracefully

## Dependencies

- `flutter_local_notifications: ^18.0.0` - Local notification management
- `workmanager: ^0.6.0` - Background task processing
- `timezone: ^0.10.1` - Timezone handling
- `shared_preferences: ^2.0.0` - Data persistence for background processing

## Future Enhancements

1. **Meal Time Integration**: Better integration with meal time settings
2. **Custom Reminder Intervals**: Allow users to set custom reminder intervals
3. **Notification Sounds**: Custom notification sounds for different medications
4. **Smart Scheduling**: AI-powered scheduling based on user behavior
5. **Family Sharing**: Share medication schedules with family members 