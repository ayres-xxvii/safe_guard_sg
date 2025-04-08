import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:latlong2/latlong.dart';
import 'package:safe_guard_sg/services/noti_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: false,
      autoStartOnBoot: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final socket = io.io("your-server-url", <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': true,
  });
  socket.onConnect((_) {
    print('Connected. Socket ID: ${socket.id}');
    // Implement your socket logic here
    // For example, you can listen for events or send data
  });

  socket.onDisconnect((_) {
    print('Disconnected');
  });
   socket.on("event-name", (data) {
    //do something here like pushing a notification
  });
  service.on("stop").listen((event) {
    service.stopSelf();
    print("background process is now stopped");
  });

  service.on("start").listen((event) {

  });

  Timer.periodic(const Duration(seconds: 10), (timer) {
    socket.emit("event-name", "your-message");
    print("background service is successfully running ${DateTime.now().second}");

    // TODO: Replace these 2 lines with actual user location and actual dangerZones
    LatLng userLoc = LatLng(1.4292652516965352, 103.83485804010147); // Current location, Yishun MRT - Annas / Replace with actual user location
    List<LatLng> dangerZones = [
      LatLng(1.3521, 103.8198), // Central Singapore (default center)
      LatLng(1.3000, 103.8000), // Tanjong Pagar / Downtown Core
      LatLng(1.2801, 103.8500), // Marina Bay / Raffles Place
      LatLng(1.3341, 103.9611), // East Coast Park
      LatLng(1.4293710684200354, 103.83407928904268), // Yishun S11 - dajie
      LatLng(1.4455, 103.7855), // Woodlands
    ];
    (bool, double?) result = userInDanger(userLoc, dangerZones);
    if (result.$1) {
      NotiService().showNotification(
        title: 'DANGER!!!',
        body: 'You are within ${(result.$2!+1).toStringAsFixed(0)}m of a danger zone.',
      );
    }
  });
}

(bool,double?) userInDanger(LatLng userLoc, List<LatLng> dangerZones) {
  // radius in meter
  double dangerRadius = 1000;
  for (LatLng zone in dangerZones) {
    // double distance = sqrt(pow(111320 * (userLoc.latitude - zone.latitude), 2) 
    //     + pow(111320 * cos(((userLoc.latitude + zone.latitude) / 2) * pi / 180) 
    //           * (userLoc.longitude - zone.longitude), 2)); 
    double distance = haversineDistance(zone.latitude, zone.longitude, userLoc.latitude, userLoc.longitude);
    if (distance < dangerRadius) {
      return (true, distance);
    }
  }
  return (false, null);
}

double haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371000; // Earth radius in meters
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;

  final a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c; // Distance in meters
}