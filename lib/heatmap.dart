// Make sure this is at the top
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class HeatMapPage extends StatefulWidget {
  const HeatMapPage({super.key});

  @override
  State<HeatMapPage> createState() => _HeatMapPageState();
}

class _HeatMapPageState extends State<HeatMapPage> {
  LatLng? _currentPosition;
  bool _isLoading = true;
  final MapController _mapController = MapController();
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeFrame = 'Day';
  String _selectedIncidentType = 'All';
  
  // List of severity areas (heat zones)
  final List<HeatZone> _heatZones = [
    // High risk zones (red)
    HeatZone(
      center: LatLng(1.433500, 103.840300),
      radius: 150,
      severity: SeverityLevel.high,
      incidentCount: 12,
      incidentType: 'Fire',
    ),
    HeatZone(
      center: LatLng(1.427800, 103.833200),
      radius: 120,
      severity: SeverityLevel.high,
      incidentCount: 8,
      incidentType: 'Crime',
    ),
    // Medium risk zones (orange)
    HeatZone(
      center: LatLng(1.437200, 103.831200),
      radius: 180,
      severity: SeverityLevel.medium,
      incidentCount: 5,
      incidentType: 'Accident',
    ),
    HeatZone(
      center: LatLng(1.423500, 103.822500),
      radius: 200,
      severity: SeverityLevel.medium,
      incidentCount: 6,
      incidentType: 'Crime',
    ),
    // Low risk zones (yellow)
    HeatZone(
      center: LatLng(1.421800, 103.843500),
      radius: 200,
      severity: SeverityLevel.low,
      incidentCount: 3,
      incidentType: 'Fire',
    ),
    HeatZone(
      center: LatLng(1.416500, 103.828000),
      radius: 170,
      severity: SeverityLevel.low,
      incidentCount: 2,
      incidentType: 'Accident',
    ),
  ];

  // Recent reported incidents
  final List<Incident> _recentIncidents = [
    Incident(
      id: 1,
      position: LatLng(1.432700, 103.839400),
      type: 'Fire',
      severity: SeverityLevel.high,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      description: 'Kitchen fire in HDB block',
    ),
    Incident(
      id: 2,
      position: LatLng(1.437100, 103.830900),
      type: 'Crime',
      severity: SeverityLevel.medium,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      description: 'Theft reported in shopping mall',
    ),
    Incident(
      id: 3,
      position: LatLng(1.421500, 103.843100),
      type: 'Accident',
      severity: SeverityLevel.low,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      description: 'Minor traffic collision',
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
        setState(() {
          _isLoading = false;
          _currentPosition = LatLng(1.429387, 103.835090); // Default to Singapore
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
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
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
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
        });
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPosition = LatLng(1.429387, 103.835090); // Default to Singapore
      });
    }
  }

  // Show heat zone details
  void _showHeatZoneInfo(BuildContext context, HeatZone heatZone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${heatZone.severity.name.toUpperCase()} RISK AREA'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${heatZone.incidentType}'),
              const SizedBox(height: 5),
              Text('Recent incidents: ${heatZone.incidentCount}'),
              const SizedBox(height: 10),
              const Text('AI Prediction:'),
              const SizedBox(height: 5),
              Text('This area has a ${_getSeverityPercentage(heatZone.severity)}% probability of incidents in the next 24 hours.'),
            ],
          ),
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

  // Show incident details
  void _showIncidentInfo(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              _getSeverityIcon(incident.severity),
              const SizedBox(width: 10),
              Text(incident.type),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Severity: ${incident.severity.name.toUpperCase()}'),
              const SizedBox(height: 5),
              Text('Time: ${_formatDateTime(incident.timestamp)}'),
              const SizedBox(height: 10),
              Text(incident.description),
            ],
          ),
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

  // Get severity percentage for AI predictions
  String _getSeverityPercentage(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.high:
        return '75-90';
      case SeverityLevel.medium:
        return '40-60';
      case SeverityLevel.low:
        return '10-25';
    }
  }

  // Format date time for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Get severity icon for incidents
  Icon _getSeverityIcon(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.high:
        return const Icon(Icons.warning, color: Colors.red);
      case SeverityLevel.medium:
        return const Icon(Icons.warning, color: Colors.orange);
      case SeverityLevel.low:
        return const Icon(Icons.info, color: Colors.yellow);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter heat zones based on selected incident type
    List<HeatZone> filteredHeatZones = _selectedIncidentType == 'All'
        ? _heatZones
        : _heatZones.where((zone) => zone.incidentType == _selectedIncidentType).toList();
    
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
                "Heat Map Analysis",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF04971F),
                ),
              ),
              const SizedBox(height: 10),
              
              // Filter controls
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Incident type filter
                    DropdownButton<String>(
                      value: _selectedIncidentType,
                      items: <String>['All', 'Fire', 'Crime', 'Accident']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedIncidentType = newValue!;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    
                    // Time frame filter
                    DropdownButton<String>(
                      value: _selectedTimeFrame,
                      items: <String>['Day', 'Week', 'Month']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTimeFrame = newValue!;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    
                    // Date selection
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2022),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 5),
                          Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(Colors.red.withOpacity(0.6), 'High Risk'),
                  const SizedBox(width: 15),
                  _legendItem(Colors.orange.withOpacity(0.6), 'Medium Risk'),
                  const SizedBox(width: 15),
                  _legendItem(Colors.yellow.withOpacity(0.5), 'Low Risk'),
                ],
              ),
              
              const SizedBox(height: 15),
              
              // Map with heat zones and user location
              SizedBox(
                height: 350,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _currentPosition ?? LatLng(1.429387, 103.835090),
                      zoom: 14.0,
                      maxZoom: 18,
                      minZoom: 5,
                      interactiveFlags: InteractiveFlag.all,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.safe_guard_sg',
                      ),
                      
                      // Heat zone circles
                      CircleLayer(
                        circles: filteredHeatZones.map((zone) => 
                          CircleMarker(
                            point: zone.center,
                            color: _getSeverityColor(zone.severity),
                            borderColor: _getSeverityBorderColor(zone.severity),
                            borderStrokeWidth: 2,
                            radius: zone.radius.toDouble(),
                            useRadiusInMeter: true,
                          ),
                        ).toList(),
                      ),
                      
                      // Recent incident markers
                      MarkerLayer(
                        markers: _recentIncidents
                            .where((incident) => _selectedIncidentType == 'All' || incident.type == _selectedIncidentType)
                            .map((incident) => 
                          Marker(
                            width: 40.0,
                            height: 40.0,
                            point: incident.position,
                            child: GestureDetector(
                              onTap: () => _showIncidentInfo(context, incident),
                              child: Icon(
                                Icons.emergency,
                                color: _getSeverityIconColor(incident.severity),
                                size: 28,
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
                      
                      // Map controls
                      Stack(
                        children: [
                          // Zoom controls
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
                                  _mapController.move(_currentPosition!, 14.0);
                                }
                              },
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                          // Display heat zones button
                          Positioned(
                            top: 10,
                            right: 10,
                            child: FloatingActionButton(
                              mini: true,
                              heroTag: 'toggle_heat',
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: () {
                                // Toggle heat map visibility (to be implemented)
                              },
                              child: const Icon(Icons.local_fire_department),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Stats summary card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safety Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('High Risk', '2', Colors.red),
                          _buildStatColumn('Medium Risk', '2', Colors.orange),
                          _buildStatColumn('Low Risk', '2', Colors.yellow),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Divider(),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AI Safety Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const Icon(Icons.star, color: Colors.amber),
                              const Icon(Icons.star, color: Colors.amber),
                              const Icon(Icons.star, color: Colors.amber),
                              const Icon(Icons.star_half, color: Colors.amber),
                              const SizedBox(width: 5),
                              const Text(
                                '4.5/5',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Recent incidents header
              const Text(
                "Recent Incidents",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Recent incidents list
              ...filteredIncidents().map((incident) => 
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                  child: ListTile(
                    leading: _getSeverityIcon(incident.severity),
                    title: Text(incident.type),
                    subtitle: Text(_formatDateTime(incident.timestamp)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showIncidentInfo(context, incident),
                  ),
                )
              ).toList(),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Heat map tab
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
  
  // Helper method to build stat column
  Widget _buildStatColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper method to build legend item
  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  // Helper method to get severity color
  Color _getSeverityColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.high:
        return Colors.red.withOpacity(0.6);
      case SeverityLevel.medium:
        return Colors.orange.withOpacity(0.6);
      case SeverityLevel.low:
        return Colors.yellow.withOpacity(0.5);
    }
  }
  
  // Helper method to get severity border color
  Color _getSeverityBorderColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.high:
        return Colors.red.withOpacity(0.8);
      case SeverityLevel.medium:
        return Colors.orange.withOpacity(0.8);
      case SeverityLevel.low:
        return Colors.yellow.withOpacity(0.7);
    }
  }
  
  // Helper method to get severity icon color
  Color _getSeverityIconColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.high:
        return Colors.red;
      case SeverityLevel.medium:
        return Colors.orange;
      case SeverityLevel.low:
        return Colors.yellow;
    }
  }
  
  // Filter incidents based on selected incident type
  List<Incident> filteredIncidents() {
    return _selectedIncidentType == 'All'
        ? _recentIncidents
        : _recentIncidents.where((incident) => incident.type == _selectedIncidentType).toList();
  }
}

// Heat zone class to store heat map data
class HeatZone {
  final LatLng center;
  final double radius;
  final SeverityLevel severity;
  final int incidentCount;
  final String incidentType;

  HeatZone({
    required this.center,
    required this.radius,
    required this.severity,
    required this.incidentCount,
    required this.incidentType,
  });
}

// Incident class to store incident data
class Incident {
  final int id;
  final LatLng position;
  final String type;
  final SeverityLevel severity;
  final DateTime timestamp;
  final String description;

  Incident({
    required this.id,
    required this.position,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.description,
  });
}

// Severity level enum
enum SeverityLevel {
  high,
  medium,
  low,
}



























  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text("Heat Map"),
  //     ),
  //     body: const Center(
  //       child: Text("Heatmap screen goes here"),
  //     ),
  //   );
  // }
// }
