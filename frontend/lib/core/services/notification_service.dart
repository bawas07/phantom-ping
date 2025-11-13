import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import '../../data/models/broadcast_message.dart';
import '../utils/logger.dart';

enum NotificationSeverity { low, medium, high }

class NotificationService extends GetxService {
  final Logger _logger = Logger('NotificationService');

  // Flutter local notifications plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Audio player for high severity notifications
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Active notifications tracking
  final Map<String, Timer?> _activeTimers = {};
  final Map<String, StreamSubscription?> _activeAudioSubscriptions = {};

  // Overlay entry for screen pulse effect
  OverlayEntry? _pulseOverlay;

  // Notification enabled preference (cached)
  final RxBool notificationEnabled = true.obs;

  // Notification permission status
  final RxBool permissionGranted = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeNotifications();
    await _loadNotificationPreference();
  }

  /// Initialize notification plugins and request permissions
  Future<void> _initializeNotifications() async {
    try {
      // Initialize Flutter Local Notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _logger.info('Notification service initialized');
    } catch (e) {
      _logger.error('Error initializing notifications', e);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        permissionGranted.value = granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        permissionGranted.value = granted ?? false;
      }
    }
  }

  /// Load notification preference from storage
  Future<void> _loadNotificationPreference() async {
    try {
      // For now, we'll use a simple key-value storage
      // In production, this should be stored in user profile or preferences
      // Default to true if not set
      notificationEnabled.value = true;
    } catch (e) {
      _logger.error('Error loading notification preference', e);
      notificationEnabled.value = true;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
    // Navigate to message detail screen if needed
    // This can be implemented when the message detail screen is ready
  }

  /// Trigger notification based on broadcast message
  Future<void> triggerNotification(BroadcastMessage message) async {
    // Check if notifications are enabled
    if (!notificationEnabled.value) {
      _logger.info('Notifications disabled, skipping: ${message.messageId}');
      return;
    }

    // Check if permission is granted
    if (!permissionGranted.value) {
      _logger.warning('Notification permission not granted');
      return;
    }

    _logger.info(
      'Triggering notification for message: ${message.messageId} (${message.level})',
    );

    // Determine severity level
    final severity = _getSeverity(message.level);

    // Trigger appropriate notification pattern
    switch (severity) {
      case NotificationSeverity.low:
        await _triggerLowSeverityNotification(message);
        break;
      case NotificationSeverity.medium:
        await _triggerMediumSeverityNotification(message);
        break;
      case NotificationSeverity.high:
        await _triggerHighSeverityNotification(message);
        break;
    }

    // Show local notification
    await _showLocalNotification(message, severity);
  }

  /// Stop notification for a specific message (on acknowledgement)
  Future<void> stopNotification(String messageId) async {
    _logger.info('Stopping notification for message: $messageId');

    // Cancel timer
    _activeTimers[messageId]?.cancel();
    _activeTimers.remove(messageId);

    // Stop audio
    await _activeAudioSubscriptions[messageId]?.cancel();
    _activeAudioSubscriptions.remove(messageId);
    await _audioPlayer.stop();

    // Remove pulse overlay
    _removePulseOverlay();

    // Cancel local notification
    await _notificationsPlugin.cancel(messageId.hashCode);

    _logger.info('Notification stopped for message: $messageId');
  }

  /// Get severity enum from string
  NotificationSeverity _getSeverity(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return NotificationSeverity.low;
      case 'medium':
        return NotificationSeverity.medium;
      case 'high':
        return NotificationSeverity.high;
      default:
        return NotificationSeverity.low;
    }
  }

  /// Trigger low severity notification (vibrate only)
  Future<void> _triggerLowSeverityNotification(BroadcastMessage message) async {
    await _vibrateSingle();
  }

  /// Trigger medium severity notification (vibrate + pulse)
  Future<void> _triggerMediumSeverityNotification(
    BroadcastMessage message,
  ) async {
    // Start vibration pattern
    _startVibratePattern(message.messageId);

    // Show screen pulse
    _showPulseOverlay(Colors.orange);
  }

  /// Trigger high severity notification (vibrate + pulse + sound)
  Future<void> _triggerHighSeverityNotification(
    BroadcastMessage message,
  ) async {
    // Start vibration pattern
    _startVibratePattern(message.messageId);

    // Show screen pulse
    _showPulseOverlay(Colors.red);

    // Play sound continuously
    await _playSoundContinuous(message.messageId);
  }

  /// Vibrate once (for low severity)
  Future<void> _vibrateSingle() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 500);
    }
  }

  /// Start repeating vibration pattern (for medium and high severity)
  void _startVibratePattern(String messageId) {
    // Cancel existing timer if any
    _activeTimers[messageId]?.cancel();

    // Vibrate immediately
    _vibrateSingle();

    // Set up repeating vibration every 3 seconds
    _activeTimers[messageId] = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      await _vibrateSingle();
    });
  }

  /// Play sound continuously (for high severity)
  Future<void> _playSoundContinuous(String messageId) async {
    try {
      // Set release mode to loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Play the notification sound
      await _audioPlayer.play(AssetSource('sounds/notification_sound.wav'));

      // Listen for completion (shouldn't happen with loop, but just in case)
      final subscription = _audioPlayer.onPlayerComplete.listen((event) {
        _logger.info('Audio playback completed');
      });

      _activeAudioSubscriptions[messageId] = subscription;
    } catch (e) {
      _logger.error('Error playing notification sound', e);
    }
  }

  /// Show screen pulse overlay
  void _showPulseOverlay(Color color) {
    // Remove existing overlay if any
    _removePulseOverlay();

    // Get overlay state
    final overlayState = Get.overlayContext;
    if (overlayState == null) {
      _logger.warning('Overlay context not available');
      return;
    }

    // Create pulse overlay
    _pulseOverlay = OverlayEntry(
      builder: (context) => _PulseOverlay(color: color),
    );

    // Insert overlay
    Overlay.of(overlayState).insert(_pulseOverlay!);
  }

  /// Remove pulse overlay
  void _removePulseOverlay() {
    _pulseOverlay?.remove();
    _pulseOverlay = null;
  }

  /// Show local notification
  Future<void> _showLocalNotification(
    BroadcastMessage message,
    NotificationSeverity severity,
  ) async {
    try {
      // Determine notification importance based on severity
      final importance = severity == NotificationSeverity.high
          ? Importance.max
          : severity == NotificationSeverity.medium
          ? Importance.high
          : Importance.defaultImportance;

      final priority = severity == NotificationSeverity.high
          ? Priority.max
          : severity == NotificationSeverity.medium
          ? Priority.high
          : Priority.defaultPriority;

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'broadcast_messages',
        'Broadcast Messages',
        channelDescription:
            'Important broadcast messages from your organization',
        importance: importance,
        priority: priority,
        enableVibration: false, // We handle vibration manually
        playSound: false, // We handle sound manually for high severity
        ongoing: severity == NotificationSeverity.high, // Persistent for high
        autoCancel: severity != NotificationSeverity.high,
        fullScreenIntent: severity == NotificationSeverity.high,
      );

      // iOS notification details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false, // We handle sound manually
        interruptionLevel: severity == NotificationSeverity.high
            ? InterruptionLevel.critical
            : severity == NotificationSeverity.medium
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _notificationsPlugin.show(
        message.messageId.hashCode, // Use hash as notification ID
        message.title,
        message.code != null
            ? '${message.message} (${message.code})'
            : message.message,
        notificationDetails,
        payload: message.messageId,
      );
    } catch (e) {
      _logger.error('Error showing local notification', e);
    }
  }

  /// Toggle notification enabled preference
  Future<void> toggleNotificationEnabled(bool enabled) async {
    notificationEnabled.value = enabled;
    // In production, save this to backend or local storage
    _logger.info('Notification enabled set to: $enabled');
  }

  @override
  void onClose() {
    // Cancel all active timers
    for (final timer in _activeTimers.values) {
      timer?.cancel();
    }
    _activeTimers.clear();

    // Cancel all audio subscriptions
    for (final subscription in _activeAudioSubscriptions.values) {
      subscription?.cancel();
    }
    _activeAudioSubscriptions.clear();

    // Stop audio player
    _audioPlayer.stop();
    _audioPlayer.dispose();

    // Remove overlay
    _removePulseOverlay();

    super.onClose();
  }
}

/// Pulse overlay widget for screen flash effect
class _PulseOverlay extends StatefulWidget {
  final Color color;

  const _PulseOverlay({required this.color});

  @override
  State<_PulseOverlay> createState() => _PulseOverlayState();
}

class _PulseOverlayState extends State<_PulseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Repeat the pulse animation
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          color: widget.color.withValues(alpha: _animation.value),
        );
      },
    );
  }
}
