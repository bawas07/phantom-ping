import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/topic.dart';
import '../../data/repositories/broadcast_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../services/auth_service.dart';

class BroadcastComposerController extends GetxController {
  final BroadcastRepository _broadcastRepository = BroadcastRepository();
  final TopicRepository _topicRepository = TopicRepository();
  final AuthService _authService = Get.find<AuthService>();

  // Form controllers
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final codeController = TextEditingController();

  // Form state
  final RxString selectedLevel = 'low'.obs;
  final RxString selectedScope = 'organization'.obs;
  final Rx<Topic?> selectedTopic = Rx<Topic?>(null);
  final RxList<Topic> topics = <Topic>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTopics();
    _setupSupervisorDefaults();
  }

  @override
  void onClose() {
    titleController.dispose();
    messageController.dispose();
    codeController.dispose();
    super.onClose();
  }

  void _setupSupervisorDefaults() {
    final user = _authService.currentUser.value;
    if (user?.isSupervisor ?? false) {
      // For supervisors, auto-set scope to topic
      selectedScope.value = 'topic';
    }
  }

  Future<void> loadTopics() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      final topicsList = await _topicRepository.getTopics(user.organizationId);
      topics.value = topicsList;

      // If supervisor, auto-select their assigned topic
      if (user.isSupervisor && user.supervisorTopicId != null) {
        selectedTopic.value = topicsList.firstWhereOrNull(
          (t) => t.id == user.supervisorTopicId,
        );
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendBroadcast() async {
    try {
      isSending.value = true;
      errorMessage.value = '';

      // Validate inputs
      if (titleController.text.trim().isEmpty) {
        errorMessage.value = 'Please enter a title';
        return;
      }

      if (messageController.text.trim().isEmpty) {
        errorMessage.value = 'Please enter a message';
        return;
      }

      final user = _authService.currentUser.value;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      // For supervisors, use their assigned topic
      String? topicId;
      if (user.isSupervisor) {
        topicId = user.supervisorTopicId;
        if (topicId == null) {
          errorMessage.value = 'Supervisor must have an assigned topic';
          return;
        }
      } else {
        // For admin/owner, validate topic selection if scope is topic
        if (selectedScope.value == 'topic') {
          if (selectedTopic.value == null) {
            errorMessage.value = 'Please select a topic';
            return;
          }
          topicId = selectedTopic.value!.id;
        }
      }

      final result = await _broadcastRepository.sendBroadcast(
        level: selectedLevel.value,
        title: titleController.text.trim(),
        message: messageController.text.trim(),
        code: codeController.text.trim().isNotEmpty
            ? codeController.text.trim()
            : null,
        scope: selectedScope.value,
        topicId: topicId,
      );

      // Show success message
      Get.snackbar(
        'Success',
        'Broadcast sent to ${result['recipientCount']} recipient(s)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear form
      titleController.clear();
      messageController.clear();
      codeController.clear();
      selectedLevel.value = 'low';
      if (!user.isSupervisor) {
        selectedScope.value = 'organization';
        selectedTopic.value = null;
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isSending.value = false;
    }
  }

  bool get isSupervisor =>
      _authService.currentUser.value?.isSupervisor ?? false;

  bool get canSelectScope =>
      _authService.currentUser.value?.canBroadcastOrgWide ?? false;

  String getLevelLabel(String level) {
    switch (level) {
      case 'low':
        return 'Low (Vibrate only)';
      case 'medium':
        return 'Medium (Vibrate + Pulse)';
      case 'high':
        return 'High (Vibrate + Pulse + Sound)';
      default:
        return level;
    }
  }

  Color getLevelColor(String level) {
    switch (level) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
