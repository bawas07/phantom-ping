import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/topic.dart';
import '../../data/models/user.dart';
import '../../data/repositories/organization_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../services/auth_service.dart';

class TopicManagementController extends GetxController {
  final TopicRepository _topicRepository = TopicRepository();
  final OrganizationRepository _orgRepository = OrganizationRepository();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<Topic> topics = <Topic>[].obs;
  final RxList<User> users = <User>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Create topic form
  final topicNameController = TextEditingController();
  final RxBool isCreatingTopic = false.obs;
  final RxString createTopicError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  @override
  void onClose() {
    topicNameController.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      // Load topics and users in parallel
      final results = await Future.wait([
        _topicRepository.getTopics(user.organizationId),
        _orgRepository.getUsers(user.organizationId),
      ]);

      topics.value = results[0] as List<Topic>;
      users.value = results[1] as List<User>;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createTopic() async {
    try {
      isCreatingTopic.value = true;
      createTopicError.value = '';

      // Validate input
      if (topicNameController.text.trim().isEmpty) {
        createTopicError.value = 'Please enter a topic name';
        return;
      }

      final user = _authService.currentUser.value;
      if (user == null) {
        createTopicError.value = 'User not authenticated';
        return;
      }

      await _topicRepository.createTopic(
        orgId: user.organizationId,
        name: topicNameController.text.trim(),
      );

      // Clear form
      topicNameController.clear();

      Get.snackbar(
        'Success',
        'Topic created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Reload topics
      await loadData();
    } catch (e) {
      createTopicError.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isCreatingTopic.value = false;
    }
  }

  Future<void> assignUserToTopic(String topicId, String userId) async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) return;

      await _topicRepository.assignUserToTopic(
        orgId: user.organizationId,
        topicId: topicId,
        userId: userId,
      );

      Get.snackbar(
        'Success',
        'User assigned to topic',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadData();
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

  Future<void> promoteToSupervisor(String userId, String topicId) async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) return;

      await _orgRepository.updateUserRole(
        orgId: user.organizationId,
        userId: userId,
        role: 'supervisor',
        topicId: topicId,
      );

      Get.snackbar(
        'Success',
        'User promoted to Supervisor',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadData();
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

  Future<void> demoteSupervisor(String userId) async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) return;

      await _orgRepository.updateUserRole(
        orgId: user.organizationId,
        userId: userId,
        role: 'normal',
      );

      Get.snackbar(
        'Success',
        'Supervisor demoted to Normal User',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await loadData();
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

  int getSupervisorCount(String topicId) {
    return users.where((u) => u.supervisorTopicId == topicId).length;
  }

  List<User> getSupervisorsForTopic(String topicId) {
    return users.where((u) => u.supervisorTopicId == topicId).toList();
  }

  List<User> getNormalUsers() {
    return users.where((u) => u.role == 'normal').toList();
  }

  List<User> getSupervisors() {
    return users.where((u) => u.role == 'supervisor').toList();
  }
}
