import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/user.dart';
import '../../data/repositories/organization_repository.dart';
import '../../services/auth_service.dart';

class UserManagementController extends GetxController {
  final OrganizationRepository _orgRepository = OrganizationRepository();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<User> users = <User>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Register user form
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final RxString selectedRole = 'normal'.obs;
  final RxBool isRegistering = false.obs;
  final RxString registerError = ''.obs;
  final RxString generatedPin = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      final usersList = await _orgRepository.getUsers(user.organizationId);
      users.value = usersList;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerUser() async {
    try {
      isRegistering.value = true;
      registerError.value = '';
      generatedPin.value = '';

      // Validate inputs
      if (nameController.text.trim().isEmpty) {
        registerError.value = 'Please enter a name';
        return;
      }

      if (emailController.text.trim().isEmpty) {
        registerError.value = 'Please enter an email';
        return;
      }

      final user = _authService.currentUser.value;
      if (user == null) {
        registerError.value = 'User not authenticated';
        return;
      }

      final result = await _orgRepository.registerUser(
        orgId: user.organizationId,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        role: selectedRole.value,
      );

      generatedPin.value = result['pin'] as String;

      // Clear form
      nameController.clear();
      emailController.clear();
      selectedRole.value = 'normal';

      // Reload users
      await loadUsers();
    } catch (e) {
      registerError.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isRegistering.value = false;
    }
  }

  Future<void> promoteToAdmin(User user) async {
    try {
      final currentUser = _authService.currentUser.value;
      if (currentUser == null) return;

      await _orgRepository.updateUserRole(
        orgId: currentUser.organizationId,
        userId: user.id,
        role: 'admin',
      );

      Get.snackbar(
        'Success',
        'User promoted to Admin',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadUsers();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> demoteToNormal(User user) async {
    try {
      final currentUser = _authService.currentUser.value;
      if (currentUser == null) return;

      await _orgRepository.updateUserRole(
        orgId: currentUser.organizationId,
        userId: user.id,
        role: 'normal',
      );

      Get.snackbar(
        'Success',
        'User demoted to Normal User',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadUsers();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> kickUser(User user) async {
    try {
      final currentUser = _authService.currentUser.value;
      if (currentUser == null) return;

      await _orgRepository.kickUser(
        orgId: currentUser.organizationId,
        userId: user.id,
      );

      Get.snackbar(
        'Success',
        'User removed from organization',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadUsers();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  bool get isOwner => _authService.currentUser.value?.isOwner ?? false;

  bool canPromoteToAdmin(User user) {
    return isOwner && user.role == 'normal';
  }

  bool canDemoteAdmin(User user) {
    return isOwner && user.role == 'admin';
  }

  bool canKickUser(User user) {
    final currentUser = _authService.currentUser.value;
    if (currentUser == null) return false;
    // Cannot kick yourself or the owner
    return user.id != currentUser.id && user.role != 'owner';
  }

  String getRoleBadgeText(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'supervisor':
        return 'Supervisor';
      case 'normal':
        return 'Normal';
      default:
        return role;
    }
  }

  Color getRoleBadgeColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'supervisor':
        return Colors.orange;
      case 'normal':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
