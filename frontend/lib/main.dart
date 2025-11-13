import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/websocket_service.dart';
import 'presentation/screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services in order
  await Get.putAsync(() async => ConnectivityService());
  await Get.putAsync(() async => AuthService());
  await Get.putAsync(() async => WebSocketService());
  await Get.putAsync(() async => NotificationService());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Connect WebSocket if user is authenticated
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    if (_authService.isAuthenticated.value) {
      await _wsService.connect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground, reconnect WebSocket if authenticated
        if (_authService.isAuthenticated.value &&
            !_wsService.isConnected.value) {
          _wsService.connect();
        }
        break;
      case AppLifecycleState.paused:
        // App went to background, keep connection alive
        // WebSocket will handle reconnection if needed
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

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
