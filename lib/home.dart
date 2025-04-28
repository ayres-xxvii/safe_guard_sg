import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Added for timer functionality
import 'heatmap.dart';
import 'report_incident.dart';
import 'recent_incident.dart';
import 'languages.dart';
import 'incident_details.dart';
import 'shared_layer/shared_scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isFirstVisit = false;
  
  // Timer for updating the countdown
  Timer? _countdownTimer;

  final List<CheckPoint> _checkPoints = [
    CheckPoint(
      id: 1, 
      position: LatLng(1.433500, 103.8403007), 
      name: "Checkpoint Alpha", 
      description: "High security zone",
      severity: CheckpointSeverity.low,
      isReported: true, // Set as reported for demonstration
      reportedTime: DateTime.now(), // Current time as the report time
    ),
    CheckPoint(
      id: 2, 
      position: LatLng(1.437200, 103.831200), 
      name: "Checkpoint Beta", 
      description: "Medium risk area",
      severity: CheckpointSeverity.low,
      isReported: false,
      reportedTime: null,
    ),
  CheckPoint(
    id: 3, 
    position: LatLng(1.437210, 103.833210), 
    name: "Stamford Detection Tank", 
    description: "Primary water quality monitoring point",
    severity: CheckpointSeverity.low,
    isReported: false,
    reportedTime: null,
  ),
    CheckPoint(
    id: 4, 
    position: LatLng(1.437210, 103.833910), 
    name: "Test 4", 
    description: "Primary water quality monitoring point",
    severity: CheckpointSeverity.low,
    isReported: false,
    reportedTime: null,
  ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkFirstVisit();
    
    // Start the countdown timer that updates every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        // This will trigger a rebuild to update the countdown displays
        _checkReportedStatus();
      });
    });
  }
  
  void _checkReportedStatus() {
    // Check each checkpoint's reported status
    for (var checkpoint in _checkPoints) {
      if (checkpoint.isReported && checkpoint.reportedTime != null) {
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(checkpoint.reportedTime!);
        
        // If 24 hours have passed, mark as not reported anymore
        if (difference.inHours >= 24) {
          setState(() {
            checkpoint.isReported = false;
            checkpoint.reportedTime = null;
          });
        }
      }
    }
  }

  Future<void> _checkFirstVisit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Fix: Ensure we have a non-null boolean by providing a default value
    bool firstVisit = prefs.getBool('first_visit') ?? true;
    
    setState(() {
      _isFirstVisit = firstVisit;
    });
    
    if (firstVisit) {
      // Fix: Add a null check for context before trying to use it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showWelcomeNotification();
          prefs.setBool('first_visit', false);
        }
      });
    }
  }

  void _showWelcomeNotification() {
    // Fix: Add a null check for context
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 10.0, right: 10.0, left: 10.0),
        content: const Text(
          'Welcome, Jane Ayres!',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
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
        // Fix: Add a null check for map controller before moving
        if (_mapController != null) {
          _mapController.move(_currentPosition!, 15.0);
        }
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
    // Calculate the distance between user and checkpoint if current position is available
    String distanceText = '';
    double? distanceInMeters;
    
    if (_currentPosition != null) {
      final Distance distance = const Distance();
      distanceInMeters = distance(checkpoint.position, _currentPosition!);
      
      // Format distance display
      if (distanceInMeters > 1000) {
        distanceText = '${(distanceInMeters / 1000).toStringAsFixed(2)} km away';
      } else {
        distanceText = '${distanceInMeters.toStringAsFixed(0)} m away';
      }
    }

    // Calculate remaining time for countdown if checkpoint is reported
    String countdownText = '';
    if (checkpoint.isReported && checkpoint.reportedTime != null) {
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(checkpoint.reportedTime!);
      final int hoursRemaining = 24 - difference.inHours - 1;
      final int minutesRemaining = 60 - difference.inMinutes % 60;
      
      countdownText = 'Status resets in: $hoursRemaining hours, $minutesRemaining minutes';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(checkpoint.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(checkpoint.description),
              const SizedBox(height: 10),
              if (distanceText.isNotEmpty) Text(distanceText),
              const SizedBox(height: 10),
              if (checkpoint.isReported) 
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Incident Reported',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                            Text(
                              countdownText,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: checkpoint.getSeverityColor().withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('Checkpoint location'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reportIncident(checkpoint);
              },
              child: const Text('Report Incident'),
            ),
          ],
        );
      },
    );
  }
  
  void _reportIncident(CheckPoint checkpoint) {
    // Mark the checkpoint as reported with the current time
    setState(() {
      checkpoint.isReported = true;
      checkpoint.reportedTime = DateTime.now();
    });
    
    // Navigate to report incident page
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const ReportIncidentPage(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

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
                            // User's location indicator - only if current position exists
                            if (_currentPosition != null)
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _currentPosition!,
                                    color: Colors.blue.withOpacity(0.1),
                                    borderColor: Colors.blue.withOpacity(0.3),
                                    borderStrokeWidth: 2,
                                    radius: 20, // Small indicator for user's position
                                  ),
                                ],
                              ),
                            // Checkpoint markers
                            MarkerLayer(
                              markers: _checkPoints.map((checkpoint) {
                                // Calculate remaining time if checkpoint is reported
                                String countdownText = '';
                                Duration? remainingTime;
                                
                                if (checkpoint.isReported && checkpoint.reportedTime != null) {
                                  final DateTime now = DateTime.now();
                                  final Duration elapsedTime = now.difference(checkpoint.reportedTime!);
                                  
                                  // Calculate remaining time (24 hours - elapsed time)
                                  final int totalMinutes = 24 * 60; // 24 hours in minutes
                                  final int elapsedMinutes = elapsedTime.inMinutes;
                                  final int remainingMinutes = totalMinutes - elapsedMinutes;
                                  
                                  // Convert to hours and minutes
                                  final int hoursRemaining = remainingMinutes ~/ 60;
                                  final int minutesRemainder = remainingMinutes % 60;
                                  
                                  countdownText = '$hoursRemaining:${minutesRemainder.toString().padLeft(2, '0')}';
                                  
                                  // Create Duration object for animation calculations
                                  remainingTime = Duration(
                                    hours: hoursRemaining,
                                    minutes: minutesRemainder
                                  );
                                }
                                
                                return Marker(
                                  width: 60.0,
                                  height: 90.0,
                                  point: checkpoint.position,
                                  child: Column(
                                    children: [
                                      // Countdown indicator for reported checkpoints
                                      if (checkpoint.isReported)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            countdownText,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () => _showCheckpointInfo(context, checkpoint),
                                        child: Icon(
                                          Icons.location_on,
                                          // Use grey for reported checkpoints, blue for non-reported
                                          color: checkpoint.isReported 
                                            ? Colors.grey[700]
                                            : checkpoint.getSeverityColor(),
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            // User location marker
                            if (_currentPosition != null)
                              MarkerLayer(
                                markers: [
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
                  child: Text(localizations.homeReportNow),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 8, bottom: 4)
              ),
              
              _buildLegend(localizations),
              const SizedBox(height: 20),
              _buildCard(
                context,
                title: localizations.heatMap,
                subtitle: localizations.homePredictiveAnalysis,
                icon: Icons.local_fire_department,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HeatMapPage())),
              ),
              const SizedBox(height: 10),
              _buildCard(
                context,
                title: localizations.homeRecentReports,
                subtitle: localizations.homeIncidentDetails,
                icon: Icons.report_problem,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecentIncidentsPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(AppLocalizations localizations) {

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${localizations.homeObservationCheckpoints} • (1/4)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _legendItem(Colors.blue, "Stamford Detection Tank •"),
                Text(
                  localizations.homeObservationNotLogged,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blue[700],
                  ),), 
                   _legendItem(Colors.blue, "Stamford Outflow Patrol •"),
                Text(
                  localizations.homeObservationNotLogged,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blue[700],
                  ),), 
                _legendItem(Colors.blue[700]!, "Cuscaden Storm Drain •"),
                Text(
                  localizations.homeObservationNotLogged,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blue[700],
                  ),),
                _legendItem(Colors.grey[700]!, "Stamford Canal Patrol Check •"),
                Text(
                  localizations.homeObservationCaptured,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.green[700],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
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

enum CheckpointSeverity {
  low,
  medium,
  high,
}

class CheckPoint {
  final int id;
  final LatLng position;
  final String name;
  final String description;
  final CheckpointSeverity severity;
  bool isReported;              // Flag to track if an incident is reported
  DateTime? reportedTime;       // Time when the incident was reported

  CheckPoint({
    required this.id,
    required this.position,
    required this.name,
    required this.description,
    required this.severity,
    required this.isReported,   // Made required to avoid null issues
    this.reportedTime,
  });

  Color getSeverityColor() {
    switch (severity) {
      case CheckpointSeverity.high:
        return Color(0xFF1DA1F2);
      case CheckpointSeverity.medium:
        return Colors.blue;
      case CheckpointSeverity.low:
        return Colors.blue[700] ?? Colors.blue;
    }
  }
}