import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'zenos_api.dart';

class PushService {
  PushService._();

  static final instance = PushService._();
  static const channelId = 'zenos_mail_inbox';

  final _local = FlutterLocalNotificationsPlugin();
  final _openedMessages = StreamController<String>.broadcast();
  StreamSubscription<String>? _tokenSubscription;
  String? _pendingMessageId;
  bool _initialized = false;
  bool _available = false;

  Stream<String> get openedMessages => _openedMessages.stream;
  bool get available => _available;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
      const channel = AndroidNotificationChannel(
        channelId,
        'Email masuk',
        description: 'Notifikasi untuk email baru di Zenos Mail',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          _open(response.payload);
        },
      );

      final localLaunch = await _local.getNotificationAppLaunchDetails();
      if (localLaunch?.didNotificationLaunchApp ?? false) {
        _pendingMessageId = localLaunch?.notificationResponse?.payload;
      }
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      _pendingMessageId ??= initialMessage?.data['email_id'];

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _open(message.data['email_id']);
      });
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  Future<void> registerCurrentDevice(ZenosApi api) async {
    if (!_available) return;
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 20),
      );
      if (token != null && token.isNotEmpty) await api.registerDevice(token);
      await _tokenSubscription?.cancel();
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
        token,
      ) async {
        try {
          await api.registerDevice(token);
        } catch (_) {}
      });
    } catch (_) {
      // Mail remains usable when Play Services is temporarily unavailable.
    }
  }

  Future<void> unregisterCurrentDevice(ZenosApi api) async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    if (!_available) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await api.unregisterDevice(token);
      } catch (_) {}
    }
  }

  String? takePendingMessageId() {
    final id = _pendingMessageId;
    _pendingMessageId = null;
    return id;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    await _local.show(
      id: message.messageId.hashCode,
      title: notification?.title ?? 'Email baru',
      body: notification?.body ?? 'Buka Zenos Mail untuk membacanya.',
      payload: message.data['email_id'],
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Email masuk',
          channelDescription: 'Notifikasi untuk email baru di Zenos Mail',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFE8913C),
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  void _open(String? id) {
    if (id == null || id.isEmpty) return;
    if (_openedMessages.hasListener) {
      _openedMessages.add(id);
    } else {
      _pendingMessageId = id;
    }
  }
}
