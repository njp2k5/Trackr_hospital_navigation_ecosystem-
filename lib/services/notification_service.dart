import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for handling local notifications that work even when screen is off.
/// Used for OP number tracking alerts.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS/macOS initialization settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigation or action handling can be added here
  }

  /// Request notification permissions (required for Android 13+)
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    
    return true;
  }

  /// Show an OP notification that works when screen is off
  /// Uses high priority and full-screen intent for immediate visibility
  Future<void> showOpNotification({
    required int opNumber,
    required String wardName,
    String? additionalMessage,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'op_tracker_channel',
      'OP Number Tracker',
      channelDescription: 'Notifications for OP number tracking',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Your OP number is being called!',
      // Make notification visible on lock screen
      visibility: NotificationVisibility.public,
      // Show as heads-up notification
      category: AndroidNotificationCategory.alarm,
      // Use full screen intent to wake up device
      fullScreenIntent: true,
      // Play default notification sound
      playSound: true,
      // Enable vibration
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      // Keep notification on screen
      ongoing: false,
      autoCancel: true,
      // Show notification even in Do Not Disturb mode
      channelShowBadge: true,
      // Large icon for better visibility
      styleInformation: BigTextStyleInformation(
        additionalMessage ?? 'Your OP number $opNumber has been called in $wardName ward. Please proceed to the counter.',
        htmlFormatBigText: false,
        contentTitle: '🔔 Your Turn - OP #$opNumber',
        htmlFormatContentTitle: false,
        summaryText: wardName,
        htmlFormatSummaryText: false,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      opNumber, // Use OP number as notification ID
      '🔔 Your Turn - OP #$opNumber',
      'OP #$opNumber has been called in $wardName. Please proceed to the counter.',
      details,
      payload: 'op_$opNumber',
    );
  }

  /// Show a reminder notification when user's turn is approaching
  Future<void> showApproachingNotification({
    required int currentOp,
    required int userOp,
    required String wardName,
    required int positionsAway,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'op_tracker_channel',
      'OP Number Tracker',
      channelDescription: 'Notifications for OP number tracking',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 100, 300]),
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        'Current OP: #$currentOp\nYour OP: #$userOp\n\nYou are $positionsAway position${positionsAway > 1 ? 's' : ''} away. Please start heading towards $wardName.',
        contentTitle: '⏰ Almost Your Turn!',
        summaryText: wardName,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      userOp + 10000, // Different ID to not replace the main notification
      '⏰ Almost Your Turn!',
      'You are $positionsAway position${positionsAway > 1 ? 's' : ''} away in $wardName',
      details,
      payload: 'approaching_$userOp',
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    
    return true;
  }
}
