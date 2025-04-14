import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'heatmap.dart';
import 'report_incident.dart';
import 'recent_incident.dart';
import 'languages.dart';
import 'incident_details.dart';
import 'shared_layer/shared_scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  LatLng? _currentPosition;
  bool _isLoading = true;
  final MapController _mapController = MapController();

  final List<CheckPoint> _checkPoints = [
    CheckPoint(id: 1, position: LatLng(1.433500, 103.8403007), name: "Checkpoint Alpha", description: "High security zone"),
    CheckPoint(id: 2, position: LatLng(1.437200, 103.831200), name: "Checkpoint Beta", description: "Medium risk area"),
    CheckPoint(id: 3, position: LatLng(1.421800, 103.843500), name: "Checkpoint Gamma", description: "Low risk zone"),
    CheckPoint(id: 4, position: LatLng(1.416500, 103.828000), name: "Checkpoint C", description: "Low risk zone"),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const MainPage(),
    const HeatMapPage(),
    const ReportIncidentPage(),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _currentPosition = LatLng(1.429387, 103.835090);
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _mapController.move(_currentPosition!, 15.0);
      });

      Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPosition = LatLng(1.429387, 103.835090);
      });
    }
  }

  void _showCheckpointInfo(BuildContext context, CheckPoint checkpoint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(checkpoint.name),
          content: Text(checkpoint.description),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localizations = AppLocalizations.of(context);

    return SharedScaffold(
      currentIndex: 0,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/safeguardlogo.png', height: 50),
            const SizedBox(width: 8),
            const Text(
              "SafeGuard.SG",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguagesPage())
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            center: _currentPosition ?? LatLng(1.429387, 103.835090),
                            zoom: 15.0,
                            maxZoom: 18,
                            minZoom: 5,
                            interactiveFlags: InteractiveFlag.all,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.safe_guard_sg',
                            ),
                            CircleLayer(
                              circles: [
                                if (_currentPosition != null)
                                  CircleMarker(
                                    point: _currentPosition!,
                                    color: Colors.blue.withOpacity(0.2),
                                    borderColor: Colors.blue.withOpacity(0.4),
                                    borderStrokeWidth: 2,
                                    radius: 120,
                                  ),
                              ],
                            ),
                            MarkerLayer(
                              markers: _checkPoints.map((checkpoint) => Marker(
                                width: 40.0,
                                height: 40.0,
                                point: checkpoint.position,
                                child: GestureDetector(
                                  onTap: () => _showCheckpointInfo(context, checkpoint),
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                ),
                              )).toList(),
                            ),
                            MarkerLayer(
                              markers: [
                                if (_currentPosition != null)
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: _currentPosition!,
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            Stack(
                              children: [
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Column(
                                    children: [
                                      FloatingActionButton(
                                        mini: true,
                                        heroTag: 'zoom_in',
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: const BorderSide(color: Colors.black),
                                        ),
                                        onPressed: () {
                                          _mapController.move(_mapController.center, _mapController.zoom + 1);
                                        },
                                        child: const Icon(Icons.zoom_in),
                                      ),
                                      const SizedBox(height: 8),
                                      FloatingActionButton(
                                        mini: true,
                                        heroTag: 'zoom_out',
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: const BorderSide(color: Colors.black),
                                        ),
                                        onPressed: () {
                                          _mapController.move(_mapController.center, _mapController.zoom - 1);
                                        },
                                        child: const Icon(Icons.zoom_out),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: FloatingActionButton(
                                    mini: true,
                                    heroTag: 'recenter',
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Colors.blue),
                                    ),
                                    onPressed: () {
                                      if (_currentPosition != null) {
                                        _mapController.move(_currentPosition!, 15.0);
                                      }
                                    },
                                    child: const Icon(Icons.my_location),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportIncidentPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD88E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  child: Text(localizations!.homeReportNow),
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                context,
                title: "Heat Map",
                subtitle: "Predictive Analytics",
                icon: Icons.local_fire_department,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HeatMapPage())),
              ),
              const SizedBox(height: 10),
              _buildCard(
                context,
                title: "Recent Reports",
                subtitle: "Incident Details",
                icon: Icons.report_problem,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentIncidentsPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Card _buildCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.grey[150],
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 30, color: Colors.red),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 18, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, size: 30),
      ),
    );
  }
}

class CheckPoint {
  final int id;
  final LatLng position;
  final String name;
  final String description;

  CheckPoint({
    required this.id,
    required this.position,
    required this.name,
    required this.description,
  });
}