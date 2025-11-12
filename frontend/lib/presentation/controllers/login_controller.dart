import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final pinController = TextEditingController();
  final organizationIdController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onClose() {
    pinController.dispose();
    organizationIdController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    // Clear previous error
    errorMessage.value = '';

    // Validate inputs
    if (pinController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter your PIN';
      return;
    }

    if (organizationIdController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter your Organization ID';
      return;
    }

    try {
      isLoading.value = true;

      await _authService.login(
        pinController.text.trim(),
        organizationIdController.text.trim(),
      );

      // Navigate based on role
      final user = _authService.currentUser.value;
      if (user != null) {
        if (user.isOwner || user.isAdmin) {
          Get.offAllNamed('/admin-dashboard');
        } else if (user.isSupervisor) {
          Get.offAllNamed('/supervisor-dashboard');
        } else {
          Get.offAllNamed('/user-dashboard');
        }
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }
}
