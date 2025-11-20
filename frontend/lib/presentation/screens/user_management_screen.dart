import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/user_management_controller.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserManagementController());

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
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
                  onPressed: controller.loadUsers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadUsers,
          child: Column(
            children: [
              // Register User Form
              Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Register New User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter user name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter user email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: controller.selectedRole.value,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'normal',
                              child: Text('Normal User'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedRole.value = value;
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.registerError.value.isNotEmpty) {
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
                                    controller.registerError.value,
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
                      Obx(() {
                        if (controller.generatedPin.value.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'User registered successfully!',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Generated PIN: ${controller.generatedPin.value}',
                                        style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: controller.generatedPin.value,
                                          ),
                                        );
                                        Get.snackbar(
                                          'Copied',
                                          'PIN copied to clipboard',
                                          snackPosition: SnackPosition.BOTTOM,
                                          duration: const Duration(seconds: 2),
                                        );
                                      },
                                      tooltip: 'Copy PIN',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.isRegistering.value
                              ? null
                              : controller.registerUser,
                          child: controller.isRegistering.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Register User'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Users List
              Expanded(
                child: controller.users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: controller.users.length,
                        itemBuilder: (context, index) {
                          final user = controller.users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: controller.getRoleBadgeColor(
                                  user.role,
                                ),
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.email),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: controller
                                          .getRoleBadgeColor(user.role)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      controller.getRoleBadgeText(user.role),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: controller.getRoleBadgeColor(
                                          user.role,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'promote') {
                                    _showPromoteDialog(
                                      context,
                                      controller,
                                      user,
                                    );
                                  } else if (value == 'demote') {
                                    _showDemoteDialog(
                                      context,
                                      controller,
                                      user,
                                    );
                                  } else if (value == 'kick') {
                                    _showKickDialog(context, controller, user);
                                  }
                                },
                                itemBuilder: (context) {
                                  final items = <PopupMenuEntry<String>>[];

                                  if (controller.canPromoteToAdmin(user)) {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'promote',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_upward,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Promote to Admin'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  if (controller.canDemoteAdmin(user)) {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'demote',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_downward,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Demote to Normal'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  if (controller.canKickUser(user)) {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'kick',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Kick User'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  if (items.isEmpty) {
                                    items.add(
                                      const PopupMenuItem(
                                        enabled: false,
                                        child: Text('No actions available'),
                                      ),
                                    );
                                  }

                                  return items;
                                },
                              ),
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

  void _showPromoteDialog(
    BuildContext context,
    UserManagementController controller,
    user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote User'),
        content: Text('Promote ${user.name} to Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.promoteToAdmin(user);
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }

  void _showDemoteDialog(
    BuildContext context,
    UserManagementController controller,
    user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demote User'),
        content: Text('Demote ${user.name} to Normal User?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.demoteToNormal(user);
            },
            child: const Text('Demote'),
          ),
        ],
      ),
    );
  }

  void _showKickDialog(
    BuildContext context,
    UserManagementController controller,
    user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick User'),
        content: Text(
          'Remove ${user.name} from the organization? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              controller.kickUser(user);
            },
            child: const Text('Kick User'),
          ),
        ],
      ),
    );
  }
}
