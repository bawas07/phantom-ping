import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'presentation/screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthService
  await Get.putAsync(() async => AuthService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Phantom Ping',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        // Placeholder routes - will be implemented in later tasks
        GetPage(
          name: '/admin-dashboard',
          page: () => const Scaffold(
            body: Center(child: Text('Admin Dashboard - Coming Soon')),
          ),
        ),
        GetPage(
          name: '/supervisor-dashboard',
          page: () => const Scaffold(
            body: Center(child: Text('Supervisor Dashboard - Coming Soon')),
          ),
        ),
        GetPage(
          name: '/user-dashboard',
          page: () => const Scaffold(
            body: Center(child: Text('User Dashboard - Coming Soon')),
          ),
        ),
      ],
    );
  }
}
