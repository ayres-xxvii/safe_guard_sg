import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  LatLng? _currentPosition;
  bool _isLoading = true;
  final MapController _mapController = MapController();
  
  // List of checkpoints to display on the map
  final List<CheckPoint> _checkPoints = [
    CheckPoint(
      id: 1,
      position: LatLng(1.433500, 103.8403007), // Slight offset from Singapore center
      name: "Checkpoint Alpha",
      description: "High security zone",
    ),
    CheckPoint(
      id: 2,
      position: LatLng(1.437200, 103.831200), // Another offset
      name: "Checkpoint Beta",
      description: "Medium risk area",
    ),
    CheckPoint(
      id: 3,
      position: LatLng(1.421800, 103.843500), // North of center
      name: "Checkpoint Gamma",
      description: "Low risk zone",
    ),
    CheckPoint(
      id: 4,
      position: LatLng(1.416500, 103.828000), // North of center
      name: "Checkpoint C",
      description: "Low risk zone",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle location permission denial
        setState(() {
          _isLoading = false;
          _currentPosition = LatLng(1.429387, 103.835090); // Default to Singapore
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle permanent denial
      setState(() {
        _isLoading = false;
        _currentPosition = LatLng(1.429387, 103.835090); // Default to Singapore
      });
      return;
    }

    // Get the current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    //   Position position = await Geolocator.getCurrentPosition();
    //   print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;

        // Move to current position - removed ready check
        _mapController.move(_currentPosition!, 15.0);
      });
      
      // Start position updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        )
      ).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          zoom: 15.0;
          maxZoom: 18;
          minZoom: 5;
          interactiveFlags: InteractiveFlag.all;
        });
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPosition = LatLng(1.429387, 103.8350907); // Default to Singapore
      });
    }
  }

  // Show checkpoint info dialog
  void _showCheckpointInfo(BuildContext context, CheckPoint checkpoint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(checkpoint.name),
          content: Text(checkpoint.description),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpeg',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            const Text('SafeGuard.SG', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "You are safe!",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF04971F),
                ),
              ),
              const SizedBox(height: 20),
              
              // Map with user location and checkpoints
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
                      
                      // Safety zone circle around current location
                      CircleLayer(
                        circles: [
                          if (_currentPosition != null)
                            CircleMarker(
                              point: _currentPosition!,
                              color: Colors.blue.withOpacity(0.2),
                              borderColor: Colors.blue.withOpacity(0.4),
                              borderStrokeWidth: 2,
                              radius: 120, // 300 meters safety zone
                            ),
                        ],
                      ),
                      
                      // Checkpoint markers (red)
                      MarkerLayer(
                        markers: _checkPoints.map((checkpoint) => 
                          Marker(
                            width: 40.0,
                            height: 40.0,
                            point: checkpoint.position,
                            child: GestureDetector(
                              onTap: () => _showCheckpointInfo(context, checkpoint),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          )
                        ).toList(),
                      ),
                      
                      // Current user location marker (blue)
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
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                        )
                                      ]
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // Zoom buttons overlay
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
                                    _mapController.move(
                                      _mapController.center,
                                      _mapController.zoom + 1,
                                    );
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
                                    _mapController.move(
                                      _mapController.center,
                                      _mapController.zoom - 1,
                                    );
                                  },
                                  child: const Icon(Icons.zoom_out),
                                ),
                              ],
                            ),
                          ),
                          // Recenter button
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD88E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Report Now!"),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: Colors.grey[150],
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  title: const Text(
                    'Heat Map',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Predictive Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 30),
                  onTap: () {},
                ),
              ),
              
              const SizedBox(height: 10),
              
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: Colors.grey[150],
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  title: const Text(
                    'Recent Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Incident Details',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 30),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF85CFCD),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Heat Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Report Incident',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Checkpoint class to store checkpoint data
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