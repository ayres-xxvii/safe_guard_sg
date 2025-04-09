import 'package:flutter/material.dart';
import 'package:safe_guard_sg/home.dart';
import 'package:safe_guard_sg/heatmap.dart';
import 'package:safe_guard_sg/report_incident.dart';

class SharedScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final PreferredSizeWidget? appBar;

  const SharedScaffold({
    Key? key,
    required this.body,
    required this.currentIndex,
    this.appBar,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const MainPage();
        break;
      case 1:
        nextPage = const HeatMapPage();
        break;
      case 2:
        nextPage = const ReportIncidentPage();
        break;
    //   case 3:
    //     nextPage = const SettingsPage(); // add this if you have a settings page
    //     break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF73D3D0), // Your blue color
        type: BottomNavigationBarType.fixed, // Required for text labels to show
        onTap: (index) => _onItemTapped(context, index),
        items: const [
            BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            ),
            BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department), // Or Icons.map
            label: "Heat Map", // Note the space between words
            ),
            BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: "Report Incident", // Full text as shown
            ),
            BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
            ),
        ],
        ),
    );
  }
}