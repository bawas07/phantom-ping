import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // User Information Section
          _SectionHeader(title: 'User Information'),
          _InfoTile(
            icon: Icons.person,
            label: 'Name',
            value: controller.userName,
          ),
          _InfoTile(
            icon: Icons.email,
            label: 'Email',
            value: controller.userEmail,
          ),
          _InfoTile(
            icon: Icons.business,
            label: 'Organization',
            value: controller.organizationId,
          ),
          _InfoTile(
            icon: Icons.badge,
            label: 'Role',
            value: controller.userRole.toUpperCase(),
          ),
          const Divider(height: 32),

          // Notification Settings Section
          _SectionHeader(title: 'Notifications'),
          Obx(
            () => SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive alerts for broadcast messages'),
              value: controller.notificationEnabled.value,
              onChanged: controller.isUpdatingNotification.value
                  ? null
                  : controller.toggleNotificationStatus,
            ),
          ),
          const Divider(height: 32),

          // Account Actions Section
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Sign out of your account'),
            onTap: () => _showLogoutDialog(context, controller),
          ),
          const SizedBox(height: 16),

          // App Version
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Phantom Ping v1.0.0',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => TextButton(
              onPressed: controller.isLoggingOut.value
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      controller.logout();
                    },
              child: controller.isLoggingOut.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
