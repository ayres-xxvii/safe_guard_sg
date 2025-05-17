// Make sure this is at the top
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'l10n/app_localizations.dart';
import 'dart:math' as math;

class RecentReportPage extends StatefulWidget {
  const RecentReportPage({super.key});

  @override
  State<RecentReportPage> createState() => _RecentReportPageState();
}

class _RecentReportPageState extends State<RecentReportPage> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.rrBarTitle),
      ),
      body: const Center(
        child: Text("Recent Report Details screen goes here"),
      ),
    );
  }
}