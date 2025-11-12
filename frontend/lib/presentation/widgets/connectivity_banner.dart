import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/connectivity_service.dart';

class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();

    return Column(
      children: [
        Obx(() {
          if (!connectivityService.isOnline) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.shade700,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'No internet connection',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Expanded(child: child),
      ],
    );
  }
}
