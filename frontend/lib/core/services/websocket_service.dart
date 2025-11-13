import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/models/broadcast_message.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';
import 'connectivity_service.dart';
import 'storage_service.dart';

class WebSocketService extends GetxService {
  final Logger _logger = Logger('WebSocketService');
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  StreamSubscription? _connectivitySubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  final StorageService _storageService = StorageService();
  final ConnectivityService _connectivityService =
      Get.find<ConnectivityService>();

  // Observable state
  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;

  // Stream controller for broadcast messages
  final _messageController = StreamController<BroadcastMessage>.broadcast();
  Stream<BroadcastMessage> get messageStream => _messageController.stream;

  // Message queue for offline scenarios
  final List<Map<String, dynamic>> _messageQueue = [];

  // Reconnection configuration
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  int _reconnectAttempts = 0;
  Duration _currentReconnectDelay = _initialReconnectDelay;

  @override
  void onInit() {
    super.onInit();
    _listenToConnectivity();
  }

  /// Listen to connectivity changes for automatic reconnection
  void _listenToConnectivity() {
    _connectivitySubscription = _connectivityService.onlineStream.listen((
      isOnline,
    ) {
      if (isOnline && !isConnected.value && !isConnecting.value) {
        // Network recovered, attempt to reconnect
        _scheduleReconnect();
      }
    });
  }

  /// Connect to WebSocket server with JWT authentication
  Future<void> connect() async {
    if (isConnected.value || isConnecting.value) {
      return;
    }

    try {
      isConnecting.value = true;

      // Get access token for authentication
      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      // Build WebSocket URL with token as query parameter
      final wsUrl = '${ApiConstants.wsUrl}?token=$accessToken';

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait for connection to be established
      await _channel!.ready;

      // Listen to incoming messages
      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      isConnected.value = true;
      isConnecting.value = false;
      _reconnectAttempts = 0;
      _currentReconnectDelay = _initialReconnectDelay;

      // Start heartbeat
      _startHeartbeat();

      // Process queued messages
      _processMessageQueue();

      _logger.info('WebSocket connected successfully');
    } catch (e) {
      _logger.error('WebSocket connection error', e);
      isConnecting.value = false;
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer = null;

    await _channelSubscription?.cancel();
    await _channel?.sink.close();

    _channelSubscription = null;
    _channel = null;

    isConnected.value = false;
    isConnecting.value = false;
    _reconnectAttempts = 0;

    _logger.info('WebSocket disconnected');
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      final jsonData = jsonDecode(data as String) as Map<String, dynamic>;
      final event = jsonData['event'] as String?;

      if (event == 'message:broadcast') {
        final payload = jsonData['payload'] as Map<String, dynamic>;
        final message = BroadcastMessage.fromJson(payload);
        _messageController.add(message);
      } else if (event == 'pong') {
        // Heartbeat response received
        _logger.debug('Heartbeat pong received');
      }
    } catch (e) {
      _logger.error('Error parsing WebSocket message', e);
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    _logger.error('WebSocket error', error);
    isConnected.value = false;
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    _logger.info('WebSocket disconnected');
    isConnected.value = false;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.warning('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    _logger.info(
      'Scheduling reconnection attempt $_reconnectAttempts in $_currentReconnectDelay',
    );

    _reconnectTimer = Timer(_currentReconnectDelay, () async {
      if (_connectivityService.isOnline) {
        await connect();
      }

      // Exponential backoff
      _currentReconnectDelay = Duration(
        milliseconds: (_currentReconnectDelay.inMilliseconds * 2).clamp(
          0,
          _maxReconnectDelay.inMilliseconds,
        ),
      );
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected.value) {
        _sendHeartbeat();
      } else {
        timer.cancel();
      }
    });
  }

  /// Send heartbeat ping to server
  void _sendHeartbeat() {
    try {
      final message = jsonEncode({'event': 'ping'});
      _channel?.sink.add(message);
    } catch (e) {
      _logger.error('Error sending heartbeat', e);
    }
  }

  /// Send message acknowledgement to server
  Future<void> acknowledgeMessage(String messageId, String userId) async {
    final message = {
      'event': 'message:acknowledge',
      'payload': {'messageId': messageId, 'userId': userId},
    };

    if (!isConnected.value) {
      // Queue message for later if offline
      _messageQueue.add(message);
      _logger.info('Message queued for later: $messageId');
      return;
    }

    try {
      _channel?.sink.add(jsonEncode(message));
      _logger.info('Message acknowledgement sent: $messageId');
    } catch (e) {
      _logger.error('Error sending acknowledgement', e);
      // Queue message on error
      _messageQueue.add(message);
      rethrow;
    }
  }

  /// Process queued messages after reconnection
  void _processMessageQueue() {
    if (_messageQueue.isEmpty) return;

    _logger.info('Processing ${_messageQueue.length} queued messages');

    final messages = List<Map<String, dynamic>>.from(_messageQueue);
    _messageQueue.clear();

    for (final message in messages) {
      try {
        _channel?.sink.add(jsonEncode(message));
        _logger.info('Queued message sent: ${message['payload']['messageId']}');
      } catch (e) {
        _logger.error('Error sending queued message', e);
        // Re-queue on failure
        _messageQueue.add(message);
      }
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _messageController.close();
    disconnect();
    super.onClose();
  }
}
