import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/broadcast_composer_controller.dart';

class BroadcastComposerScreen extends GetView<BroadcastComposerController> {
  const BroadcastComposerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Broadcast')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity Level Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Severity Level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => Column(
                          children: [
                            _buildLevelOption(
                              controller,
                              'low',
                              'Low',
                              'Vibrate only',
                              Icons.vibration,
                            ),
                            const SizedBox(height: 8),
                            _buildLevelOption(
                              controller,
                              'medium',
                              'Medium',
                              'Vibrate + Screen pulse',
                              Icons.notifications_active,
                            ),
                            const SizedBox(height: 8),
                            _buildLevelOption(
                              controller,
                              'high',
                              'High',
                              'Vibrate + Pulse + Sound',
                              Icons.warning,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scope Selector (Admin/Owner only)
              if (controller.canSelectScope)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Broadcast Scope',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => RadioGroup<String>(
                            groupValue: controller.selectedScope.value,
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedScope.value = value;
                                if (value == 'organization') {
                                  controller.selectedTopic.value = null;
                                }
                              }
                            },
                            child: Column(
                              children: [
                                RadioListTile<String>(
                                  value: 'organization',
                                  title: const Text('Organization-wide'),
                                  subtitle: const Text(
                                    'Send to all users in organization',
                                  ),
                                  dense: true,
                                ),
                                RadioListTile<String>(
                                  value: 'topic',
                                  title: const Text('Topic'),
                                  subtitle: const Text(
                                    'Send to specific topic',
                                  ),
                                  dense: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Topic Selector (if scope is topic and user is Admin/Owner)
              if (controller.canSelectScope)
                Obx(() {
                  if (controller.selectedScope.value == 'topic') {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Topic',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      controller.selectedTopic.value?.id,
                                  decoration: const InputDecoration(
                                    labelText: 'Topic',
                                    prefixIcon: Icon(Icons.topic),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: controller.topics
                                      .map(
                                        (topic) => DropdownMenuItem(
                                          value: topic.id,
                                          child: Text(topic.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      controller.selectedTopic.value =
                                          controller.topics.firstWhereOrNull(
                                            (t) => t.id == value,
                                          );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

              // Supervisor Info (if supervisor)
              if (controller.isSupervisor)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'As a Supervisor, you can only broadcast to your assigned topic',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Message Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter message title',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message *',
                          hintText: 'Enter message content',
                          prefixIcon: Icon(Icons.message),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.codeController,
                        decoration: const InputDecoration(
                          labelText: 'Code (Optional)',
                          hintText: 'Enter optional code',
                          prefixIcon: Icon(Icons.code),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error Message
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Send Button
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isSending.value
                      ? null
                      : controller.sendBroadcast,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: controller.getLevelColor(
                      controller.selectedLevel.value,
                    ),
                  ),
                  child: controller.isSending.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Send Broadcast',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLevelOption(
    BroadcastComposerController controller,
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = controller.selectedLevel.value == value;
    final color = controller.getLevelColor(value);

    return InkWell(
      onTap: () => controller.selectedLevel.value = value,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? color : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
