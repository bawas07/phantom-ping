---
inclusion: fileMatch
fileMatchPattern: "frontend/**/*.dart"
---

# Flutter Development Guidelines

When working with Flutter code in the frontend directory:

- Follow Flutter's official style guide and best practices
- Use meaningful widget names and organize code by feature
- Always use StatelessWidget with GetX - avoid StatefulWidget since GetX handles state reactivity
- Use const constructors wherever possible for better performance
- Implement proper error handling and loading states
- Use GetX (get package) for state management, routing, and dependency injection
- Use GetX controllers (GetxController) for state management with reactive programming (.obs and Obx)
- Use Get.to(), Get.off(), Get.offAll() for navigation instead of Navigator
- Use Get.put(), Get.lazyPut(), Get.find() for dependency injection
- Prefer GetView<Controller> or GetWidget<Controller> for widgets that need a controller
- Use GetBuilder only when reactive updates aren't needed
- Use Dio package for HTTP requests and API calls
- Configure Dio with interceptors for authentication, logging, and error handling
- Use Dio's built-in features like request cancellation, timeouts, and retry logic
- Structure API calls in separate service/repository classes
- Handle Dio exceptions (DioException) properly with appropriate error messages

## Security & Storage

- Use flutter_secure_storage for storing sensitive data (JWT tokens, refresh tokens)
- Never store tokens in shared_preferences or plain text
- Use flutter_secure_storage's read(), write(), and delete() methods for token management

## Real-time Communication

- Use web_socket_channel for WebSocket connections
- Implement reconnection logic for WebSocket disconnections
- Handle WebSocket lifecycle (connect, disconnect, error, reconnect)
- Use StreamBuilder to listen to WebSocket streams

## UUID Generation

- Use uuid package for generating unique identifiers
- Use uuid.v7() for UUIDv7 generation (time-based with random component)
- Generate UUIDs on the client side when needed for optimistic updates

## Notifications & Alerts

- Use flutter_local_notifications for persistent notifications
- Configure notification channels with appropriate importance levels
- Use vibration package for haptic feedback patterns
- Implement custom vibration patterns: pattern: [delay, vibrate, delay, vibrate]
- Use just_audio for playing notification sounds (supports background playback)
- For continuous alerts, use just_audio's setLoopMode(LoopMode.one)

## Permissions

- Use permission_handler for runtime permissions
- Request notification permissions before showing notifications
- Check permission status before requesting: await Permission.notification.status
- Handle permanently denied permissions by opening app settings
- Request permissions at appropriate times (not on app launch)

## Network & Connectivity

- Use connectivity_plus to monitor network status
- Show offline indicators when network is unavailable
- Queue actions when offline and retry when connection restored
- Listen to connectivity changes with connectivity.onConnectivityChanged

## Screen Management

- Use wakelock_plus to keep screen on during critical alerts
- Enable wakelock for high-severity notifications: await Wakelock.enable()
- Disable wakelock after alert is acknowledged: await Wakelock.disable()
- Check if wakelock is supported: await Wakelock.supported

## General Best Practices

- Keep widgets small and composable
- Use proper null safety practices
- Format code using `dart format` standards
- Write descriptive comments for complex business logic
- Handle platform-specific code with Platform.isAndroid / Platform.isIOS checks
