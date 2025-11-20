import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/topic_management_controller.dart';

class TopicManagementScreen extends StatelessWidget {
  const TopicManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TopicManagementController());

    return Scaffold(
      appBar: AppBar(title: const Text('Topic Management')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: Column(
            children: [
              // Create Topic Form
              Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create New Topic',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.topicNameController,
                        decoration: const InputDecoration(
                          labelText: 'Topic Name',
                          hintText: 'Enter topic name',
                          prefixIcon: Icon(Icons.topic),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.createTopic(),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.createTopicError.value.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.createTopicError.value,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.isCreatingTopic.value
                              ? null
                              : controller.createTopic,
                          child: controller.isCreatingTopic.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Topic'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Topics List
              Expanded(
                child: controller.topics.isEmpty
                    ? const Center(child: Text('No topics found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: controller.topics.length,
                        itemBuilder: (context, index) {
                          final topic = controller.topics[index];
                          final supervisorCount = controller.getSupervisorCount(
                            topic.id,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ExpansionTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.topic, color: Colors.white),
                              ),
                              title: Text(
                                topic.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '$supervisorCount Supervisor${supervisorCount != 1 ? 's' : ''}',
                              ),
                              children: [
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Supervisors Section
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Supervisors',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: () =>
                                                _showPromoteSupervisorDialog(
                                                  context,
                                                  controller,
                                                  topic.id,
                                                ),
                                            icon: const Icon(Icons.add),
                                            label: const Text('Promote'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...controller
                                          .getSupervisorsForTopic(topic.id)
                                          .map(
                                            (supervisor) => ListTile(
                                              dense: true,
                                              leading: const Icon(
                                                Icons.person,
                                                color: Colors.orange,
                                              ),
                                              title: Text(supervisor.name),
                                              subtitle: Text(supervisor.email),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_downward,
                                                  color: Colors.orange,
                                                ),
                                                onPressed: () =>
                                                    _showDemoteSupervisorDialog(
                                                      context,
                                                      controller,
                                                      supervisor,
                                                    ),
                                                tooltip: 'Demote to Normal',
                                              ),
                                            ),
                                          ),
                                      if (controller
                                          .getSupervisorsForTopic(topic.id)
                                          .isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Text(
                                            'No supervisors assigned',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 16),

                                      // Assign Users Section
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Assign Users',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: () =>
                                                _showAssignUserDialog(
                                                  context,
                                                  controller,
                                                  topic.id,
                                                ),
                                            icon: const Icon(Icons.add),
                                            label: const Text('Assign'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showAssignUserDialog(
    BuildContext context,
    TopicManagementController controller,
    String topicId,
  ) {
    final normalUsers = controller.getNormalUsers();

    if (normalUsers.isEmpty) {
      Get.snackbar(
        'No Users Available',
        'There are no normal users to assign to this topic',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign User to Topic'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: normalUsers.length,
            itemBuilder: (context, index) {
              final user = normalUsers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () {
                  Navigator.pop(context);
                  controller.assignUserToTopic(topicId, user.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPromoteSupervisorDialog(
    BuildContext context,
    TopicManagementController controller,
    String topicId,
  ) {
    final normalUsers = controller.getNormalUsers();

    if (normalUsers.isEmpty) {
      Get.snackbar(
        'No Users Available',
        'There are no normal users to promote to supervisor',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote User to Supervisor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: normalUsers.length,
            itemBuilder: (context, index) {
              final user = normalUsers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () {
                  Navigator.pop(context);
                  controller.promoteToSupervisor(user.id, topicId);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDemoteSupervisorDialog(
    BuildContext context,
    TopicManagementController controller,
    user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demote Supervisor'),
        content: Text('Demote ${user.name} to Normal User?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.demoteSupervisor(user.id);
            },
            child: const Text('Demote'),
          ),
        ],
      ),
    );
  }
}
