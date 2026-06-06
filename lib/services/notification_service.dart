import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// ─── Background message handler (top-level) ───────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[Customer FCM Background] ${message.notification?.title}');
}

// ─────────────────────────────────────────────────────────────────────────────
/// CustomerNotificationService
///
/// Handles FCM push notifications for the Customer App.
/// - Receives order status updates (accepted, preparing, ready)
/// - Shows local notification when app is in foreground
/// - Registers FCM token anonymously (linked to orderId + deviceUUID)
/// ─────────────────────────────────────────────────────────────────────────────
class CustomerNotificationService {
  static final CustomerNotificationService _instance =
      CustomerNotificationService._internal();
  factory CustomerNotificationService() => _instance;
  CustomerNotificationService._internal();

  static const String _deviceUUIDKey = 'customer_device_uuid';

  // Android notification channel
  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
    'qrcafe_customer_orders',
    'QR Cafe Order Updates',
    description: 'Order status updates from your restaurant',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callback when user taps a notification (for navigation)
  Function(String type, Map<String, String> data)? onNotificationTap;

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[CustomerNotificationService] Bypassing FCM init on Web');
      return;
    }
    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      await _requestPermissions();
      await _initLocalNotifications();

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _setupMessageHandlers();

      debugPrint('[CustomerNotificationService] Initialized.');
    } catch (e) {
      debugPrint('[CustomerNotificationService] Init error (non-fatal): $e');
    }
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _initLocalNotifications() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_orderChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = Map<String, String>.from(jsonDecode(payload));
            onNotificationTap?.call(data['type'] ?? '', data);
          } catch (_) {}
        }
      },
    );
  }

  void _setupMessageHandlers() {
    // Foreground
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
          '[Customer FCM Foreground] ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final type = message.data['type'] ?? '';
      onNotificationTap?.call(type, Map<String, String>.from(message.data));
    });

    // Terminated tap
    try {
      if (!kIsWeb) {
        FirebaseMessaging.instance.getInitialMessage().then((message) {
          if (message != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              final type = message.data['type'] ?? '';
              onNotificationTap?.call(
                  type, Map<String, String>.from(message.data));
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[CustomerNotificationService] getInitialMessage error: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _orderChannel.id,
          _orderChannel.name,
          channelDescription: _orderChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          styleInformation:
              BigTextStyleInformation(notification.body ?? ''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── Token Registration ───────────────────────────────────────────────────

  /// Call this after a customer places an order to link their FCM token
  /// to the orderId so they receive status updates for that order.
  Future<void> registerTokenForOrder(String orderId) async {
    if (kIsWeb) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken(
        vapidKey: '0wqglRYLdebz4nDLL99Gh5QbkK0hHv-Wyk6X0a_hmtY',
      );
      if (fcmToken == null) return;

      final customerUUID = await getOrCreateDeviceUUID();

      final response = await http.post(
        Uri.parse(CustomerApiConfig.registerCustomerToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'orderId': orderId,
          'customerUUID': customerUUID,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint(
            '[CustomerNotificationService] Token registered for orderId: $orderId');
      } else {
        debugPrint(
            '[CustomerNotificationService] Token registration failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[CustomerNotificationService] registerTokenForOrder error: $e');
    }
  }

  // ─── Device UUID ─────────────────────────────────────────────────────────

  /// Gets an existing persistent UUID or generates a new one on first run.
  /// This UUID is used as the anonymous customer identifier in the backend.
  Future<String> getOrCreateDeviceUUID() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_deviceUUIDKey);
    if (uuid == null) {
      uuid = _generateUUID();
      await prefs.setString(_deviceUUIDKey, uuid);
    }
    return uuid;
  }

  String _generateUUID() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
