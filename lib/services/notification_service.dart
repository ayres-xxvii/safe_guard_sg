// 1. First, update your pubspec.yaml to add these dependencies:
// flutter_local_notifications: ^15.1.0  
// permission_handler: ^10.2.0 (for handling notification permissions)

// 2. Create a notification service class (notifications_service.dart)

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart'; // Import for Color class

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // Handle notification tap, maybe navigate to incident details
        print('Notification clicked: ${notificationResponse.payload}');
      },
    );
    
    // Request notification permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // For Android 13+, request notification permission
    await Permission.notification.request();
    
    // For iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showNearbyIncidentNotification(String title, String body, {String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'nearby_incidents_channel',
      'Nearby Incidents',
      channelDescription: 'Notifications for nearby incidents',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'SafeGuard Notification',
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1DA1F2), // Match your app's blue color
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}

// 3. Now update your MainPage class to use these notifications