# Services

This directory contains core services for the Phantom Ping application.

## NotificationService

The `NotificationService` handles all notification functionality including vibration, screen pulse effects, and sound playback based on message severity levels.

### Features

- **Three severity levels:**

  - **Low**: Single vibration (500ms)
  - **Medium**: Repeating vibration (every 3s) + orange screen pulse
  - **High**: Repeating vibration (every 3s) + red screen pulse + continuous sound (loops until acknowledged)

- **User preference support**: Respects user's notification enabled/disabled preference
- **Permission handling**: Requests and manages notification permissions for Android and iOS
- **Acknowledgement support**: Stops all notifications when message is acknowledged

### Usage

#### Initialize the service

```dart
// The service is initialized automatically when registered with GetX
Get.put(NotificationService());
```

#### Trigger a notification

```dart
final notificationService = Get.find<NotificationService>();
final message = BroadcastMessage(
  messageId: '123',
  level: 'high',
  title: 'Emergency Alert',
  message: 'Evacuation required',
  code: 'CODE-RED',
  timestamp: DateTime.now(),
);

await notificationService.triggerNotification(message);
```

#### Stop a notification (on acknowledgement)

```dart
await notificationService.stopNotification(messageId);
```

#### Toggle notification preference

```dart
await notificationService.toggleNotificationEnabled(false); // Disable
await notificationService.toggleNotificationEnabled(true);  // Enable
```

### Integration with WebSocket

To automatically trigger notifications when broadcast messages are received:

```dart
final webSocketService = Get.find<WebSocketService>();
final notificationService = Get.find<NotificationService>();

// Listen to incoming messages
webSocketService.messageStream.listen((message) {
  // Trigger notification
  notificationService.triggerNotification(message);
});
```

### Platform Configuration

#### Android

Permissions are configured in `android/app/src/main/AndroidManifest.xml`:

- `VIBRATE`: For vibration
- `WAKE_LOCK`: To wake screen
- `POST_NOTIFICATIONS`: For Android 13+ notifications
- `USE_FULL_SCREEN_INTENT`: For high-priority notifications

#### iOS

Permissions are configured in `ios/Runner/Info.plist`:

- `UIBackgroundModes`: For background audio and notifications
- `NSUserNotificationsUsageDescription`: Permission description

### Dependencies

- `vibration`: Haptic feedback
- `flutter_local_notifications`: Persistent notifications
- `audioplayers`: Sound playback

### Notes

- The notification sound file should be placed at `assets/sounds/notification_sound.mp3`
- For production, replace the placeholder sound file with an actual audio file
- The screen pulse effect uses an overlay widget that animates opacity
- High severity notifications are persistent and require user acknowledgement
