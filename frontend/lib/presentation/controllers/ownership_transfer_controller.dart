import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/user.dart';
import '../../data/repositories/organization_repository.dart';
import '../../services/auth_service.dart';

class OwnershipTransferController extends GetxController {
  final OrganizationRepository _orgRepository = OrganizationRepository();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<User> admins = <User>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isTransferring = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAdmins();
  }

  Future<void> loadAdmins() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      if (!user.isOwner) {
        errorMessage.value = 'Only the Owner can transfer ownership';
        return;
      }

      final users = await _orgRepository.getUsers(user.organizationId);
      admins.value = users.where((u) => u.role == 'admin').toList();
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> transferOwnership(String newOwnerId) async {
    try {
      isTransferring.value = true;

      final user = _authService.currentUser.value;
      if (user == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _orgRepository.transferOwnership(
        orgId: user.organizationId,
        newOwnerId: newOwnerId,
      );

      Get.snackbar(
        'Success',
        'Ownership transferred successfully. You are now an Admin.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Logout and redirect to login since role has changed
      await Future.delayed(const Duration(seconds: 2));
      await _authService.logout();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isTransferring.value = false;
    }
  }
}
