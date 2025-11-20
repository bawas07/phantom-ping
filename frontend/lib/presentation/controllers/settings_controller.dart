import 'package:get/get.dart';

import '../../core/services/notification_service.dart';
import '../../core/utils/logger.dart';
import '../../services/auth_service.dart';

class SettingsController extends GetxController {
  final Logger _logger = Logger('SettingsController');
  final AuthService _authService = Get.find<AuthService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  // Observable state
  final RxBool notificationEnabled = true.obs;
  final RxBool isUpdatingNotification = false.obs;
  final RxBool isLoggingOut = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotificationPreference();
  }

  /// Load notification preference
  void _loadNotificationPreference() {
    notificationEnabled.value = _notificationService.notificationEnabled.value;
  }

  /// Toggle notification status
  Future<void> toggleNotificationStatus(bool enabled) async {
    try {
      isUpdatingNotification.value = true;

      // Update notification service
      await _notificationService.toggleNotificationEnabled(enabled);

      // Update local state
      notificationEnabled.value = enabled;

      // In production, this should also update the backend
      // For now, we'll just store it locally
      _logger.info('Notification status updated: $enabled');

      Get.snackbar(
        'Success',
        enabled ? 'Notifications enabled' : 'Notifications disabled',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _logger.error('Error updating notification status', e);

      Get.snackbar(
        'Error',
        'Failed to update notification status',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isUpdatingNotification.value = false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      isLoggingOut.value = true;

      await _authService.logout();

      // Navigate to login screen
      Get.offAllNamed('/login');

      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _logger.error('Error during logout', e);

      Get.snackbar(
        'Error',
        'Failed to logout: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  /// Get current user info
  String get userName => _authService.currentUser.value?.name ?? 'Unknown';
  String get userEmail => _authService.currentUser.value?.email ?? 'Unknown';
  String get organizationId =>
      _authService.currentUser.value?.organizationId ?? 'Unknown';
  String get userRole => _authService.currentUser.value?.role ?? 'Unknown';
}
