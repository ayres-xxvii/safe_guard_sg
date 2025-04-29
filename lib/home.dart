import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Added for timer functionality
import 'dart:math' show sin; // Added for bobbing animation
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for database access
import 'heatmap.dart';
import 'report_incident.dart';
import 'recent_incident.dart';
import 'languages.dart';
import 'incident_details.dart';
import 'shared_layer/shared_scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_report.dart'; // Add this import for the IncidentReport model
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
// Add this import at the top of your file
import '../services/notification_service.dart';


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
  late NotificationService _notificationService; // Define the notification service


  
  
  // Counter for submitted checkpoints
  int _submittedCheckpointsCount = 1; // Start with 1 as one is already marked as reported
  
  // Timer for updating the countdown
  Timer? _countdownTimer;

  final List<CheckPoint> _checkPoints = [
    CheckPoint(
      id: 1, 
      position: LatLng(1.433500, 103.8403007), 
      name: "Stamford Canal Patrol Check", 
      description: "The Stamford Canal Patrol Check monitors a key section of the Stamford Stormwater Canal, a concrete-lined drainage channel that collects rainwater runoff from Orchard Road and surrounding urban areas.",
      severity: CheckpointSeverity.low,
      isReported: true, // Set as reported for demonstration
      reportedTime: DateTime.now(), // Current time as the report time
      isFromDatabase: false, // This is a hardcoded checkpoint
    ),
    CheckPoint(
      id: 2, 
      position: LatLng(1.437200, 103.831200), 
      name: "Stamford Outflow Patrol", 
      description: "This checkpoint is located at the outflow point of the Stamford Canal system. It is an area that monitors the discharge of water from the canal, ensuring that water quality standards are met before it enters the surrounding environment. It serves as a critical observation point for detecting any contaminants or changes in water composition.",
      severity: CheckpointSeverity.low,
      isReported: false,
      reportedTime: null,
      isFromDatabase: false,
    ),
    CheckPoint(
      id: 3, 
      position: LatLng(1.437210, 103.833210), 
      name: "Stamford Detection Tank", 
      description: "The Stamford Detection Tank is one of the primary points for water quality monitoring within the canal system. Situated along the waterway, it collects samples to analyze chemical, biological, and physical properties of the water.",
      severity: CheckpointSeverity.low,
      isReported: false,
      reportedTime: null,
      isFromDatabase: false,
    ),
    CheckPoint(
      id: 4, 
      position: LatLng(1.437210, 103.833910), 
      name: "Cuscaden Storm Drain", 
      description: "The Cuscaden Storm Drain serves as a crucial infrastructure point for managing surface water runoff and preventing flooding during heavy rainfall. This checkpoint monitors the flow of stormwater entering the canal system, ensuring that the drainage system is functioning properly and not causing obstructions.",
      severity: CheckpointSeverity.low,
      isReported: false,
      reportedTime: null,
      isFromDatabase: false,
    ),
    CheckPoint(
      id: 5, 
      position: LatLng(1.4291560, 103.8350825),  // Example coordinates
      name: "Yishun Storm Drain", 
      description: "Yishun drain; strategically located to monitor stormwater management in the region. It provides data on the flow of water in a critical section of the canal system.",
      severity: CheckpointSeverity.low,
      isReported: false,
      reportedTime: null,
      isFromDatabase: false,  // Hardcoded checkpoint
    ),
  ];

  final Set<int> _notifiedIncidents = {}; // Keep track of incidents we've notified about

 // Update your _checkProximityToHazards method to use notifications
  void _checkProximityToHazards() {
    // Skip if user location is unknown
    if (_currentPosition == null) return;
    
    // Check proximity to database incidents (blue checkpoints)
    for (var incident in _databaseIncidents) {
      final Distance distance = const Distance();
      final double distanceInMeters = distance(incident.position, _currentPosition!);
      
      // If within 20 meters of a database incident, show notification
      if (distanceInMeters <= 20) {
        // Avoid showing multiple notifications for the same incident
        // by checking if we've already notified the user about this one
        bool alreadyNotified = _notifiedIncidents.contains(incident.id);
        
        if (!alreadyNotified) {
          _sendIncidentProximityNotification(incident);
          _notifiedIncidents.add(incident.id); // Mark as notified
          
          // Also show UI alert for immediate awareness
          _showProximityAlert(incident);
        }
      }
    }
  }

    // Add this new method to trigger local notifications
  void _sendIncidentProximityNotification(CheckPoint incident) {
    _notificationService.showNearbyIncidentNotification(
      'Reported Hazard Alert',
      'Potential hazard detected near you. Please proceed with awareness!',
      payload: incident.id.toString(), // Pass the incident ID as payload
    );
  }
// Add this method to manually trigger a notification for testing
 // Update your test notification method to also send a local notification
  void _triggerTestNotification() {
    // Create a test incident near current location (slightly offset)
    if (_currentPosition != null) {
      print("DEBUG: Creating test incident for notification");
      
      // Create a test incident 15 meters from current location
      final testIncident = CheckPoint(
        id: 999, // Special ID for test incident
        position: LatLng(
          _currentPosition!.latitude + 0.0001, // Slightly offset
          _currentPosition!.longitude + 0.0001,
        ),
        name: "Test Incident Near You",
        description: "This is a test incident created near your location to test notifications.",
        severity: CheckpointSeverity.high,
        isReported: true,
        reportedTime: DateTime.now(),
        isFromDatabase: true,
      );
      
      setState(() {
        _databaseIncidents.add(testIncident);
      });
      
      // Show notification for this test incident
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showProximityAlert(testIncident);
          _sendIncidentProximityNotification(testIncident);
        }
      });
    } else {
      print("DEBUG: Cannot create test incident - no location or database incidents already exist");
    }
  }


 // Add a method to handle when a notification is tapped
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      int? incidentId = int.tryParse(payload);
      if (incidentId != null) {
        // Find the incident with this ID
        CheckPoint? incident = _databaseIncidents.firstWhere(
          (element) => element.id == incidentId,
          orElse: () => _checkPoints.firstWhere(
            (element) => element.id == incidentId,
            orElse: () => null as CheckPoint,
          ),
        );
        
        if (incident != null && mounted) {
          // Show the incident details
          _showCheckpointInfo(context, incident);
        }
      }
    }
  }
// Add this method to your _MainPageState class
void _showProximityAlert(CheckPoint incident) {
  // Skip if context is not available
  if (!mounted) return;
  
  // Show a snackbar notification
  // ScaffoldMessenger.of(context).showSnackBar(
  //   SnackBar(
  //     behavior: SnackBarBehavior.floating,
  //     margin: const EdgeInsets.only(bottom: 10.0, right: 10.0, left: 10.0),
  //     content: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.warning_amber_rounded, color: Colors.yellow),
  //             const SizedBox(width: 10),
  //             Expanded(
  //               child: Text(
  //                 'Heads up! There\'s an incident reported near your location.',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 5),
  //         Text(
  //           incident.name,
  //           style: TextStyle(fontSize: 14),
  //           textAlign: TextAlign.start,
  //         ),
  //       ],
  //     ),
  //     backgroundColor: Colors.red[700],
  //     duration: const Duration(seconds: 5),
  //     action: SnackBarAction(
  //       label: 'VIEW',
  //       textColor: Colors.white,
  //       onPressed: () {
  //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //         _showCheckpointInfo(context, incident);
  //       },
  //     ),
  //   ),
  // );
}

  // List to store incidents from the database
  List<CheckPoint> _databaseIncidents = [];

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
    _loadIncidentsFromDatabase();
    _loadSubmittedCheckpoints();
          // Initialize notification service
    _notificationService = NotificationService();
    _notificationService.init();
  
      // Add a delayed trigger for the test notification
  Future.delayed(const Duration(seconds: 5), () {
    _triggerTestNotification();
  }); 
    // Start the countdown timer that updates every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        // This will trigger a rebuild to update the countdown displays
        _checkReportedStatus();
      });
    });
  }

  // Add this function to your HomePage or equivalent class
void _refreshMapData() {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation1, animation2) => const MainPage(), // Replace with a valid widget or import MapPage
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}
  
  // Load any previously submitted checkpoints from shared preferences
  Future<void> _loadSubmittedCheckpoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Load the submitted count
    setState(() {
      _submittedCheckpointsCount = prefs.getInt('submitted_checkpoints_count') ?? 1;
    });
    
    // Load the status of each checkpoint
    for (var checkpoint in _checkPoints) {
      final isReported = prefs.getBool('checkpoint_${checkpoint.id}_reported') ?? checkpoint.isReported;
      
      if (isReported) {
        final reportTimeStr = prefs.getString('checkpoint_${checkpoint.id}_report_time');
        final reportTime = reportTimeStr != null ? DateTime.parse(reportTimeStr) : DateTime.now();
        
        setState(() {
          checkpoint.isReported = isReported;
          checkpoint.reportedTime = reportTime;
        });
      }
    }
  }
  
  // Save submitted checkpoint status to shared preferences
  Future<void> _saveSubmittedCheckpoint(CheckPoint checkpoint) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Save the checkpoint status
    await prefs.setBool('checkpoint_${checkpoint.id}_reported', true);
    await prefs.setString('checkpoint_${checkpoint.id}_report_time', checkpoint.reportedTime!.toIso8601String());
    
    // Save the updated count
    await prefs.setInt('submitted_checkpoints_count', _submittedCheckpointsCount);
  }
  
  Future<void> _loadIncidentsFromDatabase() async {
    try {
      // Query Firestore collection of incidents
      final querySnapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .limit(10) // Limit to 10 most recent incidents
          .get();
      
      // Process each document
      List<CheckPoint> loadedIncidents = [];
      int idCounter = 100; // Start ID counter for database incidents
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Check if latitude and longitude are available
        if (data['latitude'] != null && data['longitude'] != null) {
          loadedIncidents.add(
            CheckPoint(
              id: idCounter++,
              position: LatLng(data['latitude'], data['longitude']),
              name: data['title'] ?? 'Unknown Incident',
              description: data['description'] ?? 'No description',
              severity: CheckpointSeverity.high, // Set high severity for database incidents
              isReported: true, // Always treated as reported
              reportedTime: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isFromDatabase: true, // Mark as coming from database
            ),
          );
        }
      }
      
      // Update state with loaded incidents
      setState(() {
        _databaseIncidents = loadedIncidents;
      });
      
    } catch (e) {
      print('Error loading incidents from database: $e');
    }
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
            
            // Also decrease the counter when a checkpoint resets
            if (_submittedCheckpointsCount > 0) {
              _submittedCheckpointsCount--;
              _saveSubmittedCheckpointCount();
            }
          });
        }
      }
    }
  }
  
  // Helper method to save just the count
  Future<void> _saveSubmittedCheckpointCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('submitted_checkpoints_count', _submittedCheckpointsCount);
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
          'Welcome, John Doe!',
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
      if (_mapController != null) {
        _mapController.move(_currentPosition!, 15.0);
      }
    });
    
    // Check for nearby hazards immediately after getting initial location
    _checkProximityToHazards();

    // Set up the position stream for continuous updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 10
      )
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      // Check for nearby hazards on each location update
      _checkProximityToHazards();
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _currentPosition = LatLng(1.429387, 103.835090);
    });
  }
}

void _showCheckpointInfo(BuildContext context, CheckPoint checkpoint) {
  final AppLocalizations localizations = AppLocalizations.of(context)!;

  String distanceText = '';
  double? distanceInMeters;
  bool isNearby = false;

  if (_currentPosition != null) {
    final Distance distance = const Distance();
    distanceInMeters = distance(checkpoint.position, _currentPosition!);
    isNearby = distanceInMeters <= 30;

    if (distanceInMeters > 1000) {
      distanceText = '${(distanceInMeters / 1000).toStringAsFixed(2)} km away';
    } else {
      distanceText = '${distanceInMeters.toStringAsFixed(0)} m away';
    }
  }

  // Only calculate countdown if checkpoint is reported and NOT from database
  String countdownText = '';
  if (checkpoint.isReported && !checkpoint.isFromDatabase && checkpoint.reportedTime != null) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(checkpoint.reportedTime!);
    final int hoursRemaining = 24 - difference.inHours - 1;
    final int minutesRemaining = 60 - difference.inMinutes % 60;
    countdownText = 'Status resets in: $hoursRemaining hours, $minutesRemaining minutes';
  }
  

  Future<void> _verifyIncident(CheckPoint checkpoint) async {
    try {
      // Find the corresponding Firestore document based on location (or a better unique ID if you have it)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .where('latitude', isEqualTo: checkpoint.position.latitude)
          .where('longitude', isEqualTo: checkpoint.position.longitude)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;

        await docRef.update({
          'verificationCount': FieldValue.increment(1), // Increment verification count by 1
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for verifying this incident!'),
          ),
        );
      } else {
        print('Incident document not found.');
      }
    } catch (e) {
      print('Error verifying incident: $e');
    }
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
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!checkpoint.isFromDatabase && countdownText.isNotEmpty)
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
                Text(checkpoint.isFromDatabase ? 'Reported incident' : 'Checkpoint location'),
              ],
            ),
         // In home.dart
const SizedBox(height: 20),
Center(
  child: !checkpoint.isFromDatabase && isNearby && !checkpoint.isReported
      ? ElevatedButton(
          onPressed: () {
            // Pass the checkpoint to the next page
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReportIncidentPage(checkpoint: checkpoint),
              ),
            ).then((value) {
              // When returning from ReportIncidentPage, refresh the map
              // This will trigger a rebuild of the UI with the updated checkpoint status
              setState(() {
                // Refresh map data if needed
                _refreshMapData();
              });
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Submit Checkpoint',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        )
      : (checkpoint.isReported && !checkpoint.isFromDatabase)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Checkpoint Submitted',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Container(),
),


if (checkpoint.isFromDatabase)
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedReason = localizations.flagTypeMisreporting;
        TextEditingController detailsController = TextEditingController();

        return AlertDialog(
          title: Text(localizations.flagIncident),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  labelText: localizations.flagLabelReason,
                  border: OutlineInputBorder(),
                ),
                items: <String>[
                  localizations.flagTypeMisreporting,
                  localizations.flagTypeOffensiveContent,
                  localizations.flagTypeSpam,
                  localizations.flagTypeIncorrectLocation,
                  localizations.flagTypeOther
                ].map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    selectedReason = newValue;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: localizations.flagLabelAdditional,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                String reason = selectedReason;
                String details = detailsController.text;

                // TODO: Handle your reporting logic here
                print('Flagging with reason: $reason');
                print('Details: $details');

                Navigator.of(context).pop(); // Close the flagging popup

showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            localizations.flagReportSubmitted,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '${localizations.flagReportSuccess}.\n\n'
            '${localizations.flagReportThankYou}!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the confirmation popup
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  },
);

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(localizations.flagSubmit),
            ),
          ],
        );
      },
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text(
    localizations.flagIncident,
    style: TextStyle(color: Colors.white),
  ),
),

    ],
  ),]),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
        ],
      );
    },
  );
}

  // New method to submit a checkpoint directly
  void _submitCheckpoint(CheckPoint checkpoint) {
    setState(() {
      // Mark the checkpoint as reported
      checkpoint.isReported = true;
      checkpoint.reportedTime = DateTime.now();
      
      // Increment the counter if not already counted
      if (!checkpoint.isReported) {
        _submittedCheckpointsCount++;
      }
    });
    
    // Save the submitted checkpoint to shared preferences
    _saveSubmittedCheckpoint(checkpoint);
    
    // Show success notification
    _showSubmissionSuccessDialog();
  }
  
  // Show a success dialog after submitting a checkpoint
  void _showSubmissionSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Checkpoint Submitted!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your checkpoint observation has been recorded.\n\n'
                ,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the confirmation popup
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
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

    // Combine hardcoded checkpoints and database incidents
    final allMarkers = [..._checkPoints, ..._databaseIncidents];

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
    icon: const Icon(Icons.refresh),
    tooltip: 'Refresh',
    onPressed: _refreshMapData, // Call the refresh method
  ),
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
                            // Checkpoint and incident markers
MarkerLayer(
  markers: allMarkers.map((marker) {
    String countdownText = '';
    Duration? remainingTime;

    // Only show the timer for non-database (hardcoded) checkpoints
    if (!marker.isFromDatabase) {  // Ensure the marker is NOT from the database
      if (marker.isReported && marker.reportedTime != null) {
        final DateTime now = DateTime.now();
        final Duration elapsedTime = now.difference(marker.reportedTime!);

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
    }

    // Calculate distance between user and checkpoint if current position exists
    double? distanceInMeters;
    bool isNearby = false;

    if (_currentPosition != null) {
      final Distance distance = const Distance();
      distanceInMeters = distance(marker.position, _currentPosition!);
      isNearby = distanceInMeters <= 30;
    }

    

    // Set the appropriate icon size based on marker type
    double iconSize = marker.isFromDatabase ? 30.0 : 40.0; // Smaller icon for database incidents

    return Marker(
      width: 70.0,
      height: 100.0,
      point: marker.position,
      child: Column(
        children: [
          // Only show the countdown for non-database checkpoints
          if (!marker.isFromDatabase && marker.isReported)
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
          // Apply bobbing animation for nearby markers
          isNearby 
            ? TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: 2 * pi),
  duration: const Duration(seconds: 2),
  builder: (context, value, child) {
    double bobbing = sin(value) * 4; // 4 pixels up and down
    return Transform.translate(
      offset: Offset(0, bobbing),
      child: child,
    );
  },
  onEnd: () {
    // Manually trigger rebuild to "loop" (dirty trick)
    (context as Element).markNeedsBuild();
  },
  child: GestureDetector(
    onTap: () => _showCheckpointInfo(context, marker),
    child: Icon(
      Icons.location_on,
      color: marker.isFromDatabase 
          ? Colors.red
          : (marker.isReported 
              ? Colors.grey[700]
              : marker.getSeverityColor()),
      size: 40,
    ),
  ),
)
            : GestureDetector(
                onTap: () => _showCheckpointInfo(context, marker),
                child: Icon(
                  Icons.location_on,
                  color: marker.isFromDatabase 
                    ? Colors.red
                    : (marker.isReported 
                        ? Colors.grey[700]
                        : marker.getSeverityColor()),
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
              
_buildObservationCheckpointsCard(localizations),



ElevatedButton(
  onPressed: _resetSubmittedCheckpoints,
  child: Text('Reset All Checkpoints'),
),

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
Widget _buildObservationCheckpointsCard(AppLocalizations localizations) {
  int databaseIncidentCount = _databaseIncidents.length;
  List<CheckPoint> notCaptured = _checkPoints.where((cp) => !cp.isReported && !cp.isFromDatabase).toList();
  List<CheckPoint> captured = _checkPoints.where((cp) => cp.isReported && !cp.isFromDatabase).toList();

  int totalCheckpoints = notCaptured.length + captured.length;

  return Center( // <--- Wrap the Card in a Center widget
    child: Card(
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
              "${localizations.homeObservationCheckpoints} • (${captured.length}/$totalCheckpoints)",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Not Captured Section
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                for (var cp in notCaptured)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendItem(Colors.blue, "${cp.name} •"),
                      Text(
                        localizations.homeObservationNotLogged,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (captured.isNotEmpty) ...[
              const SizedBox(height: 5),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  for (var cp in captured)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendItem(Colors.grey[700]!, "${cp.name} •"),
                        Text(
                          localizations.homeObservationCaptured,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],

            if (databaseIncidentCount > 0) ...[
              const SizedBox(height: 20),
              _legendItem(Colors.red, "Recent Reported Incidents ($databaseIncidentCount) •"),
            ],
          ],
        ),
      ),
    ),
  );
}
Future<void> _resetSubmittedCheckpoints() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // This clears ALL shared preferences!
  
  setState(() {
    // Reset your local checkpoints too if needed
    for (var checkpoint in _checkPoints) {
      checkpoint.isReported = false;
      checkpoint.reportedTime = null;
    }
    _submittedCheckpointsCount = 0;
  });
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
  final bool isFromDatabase;    // Flag to indicate if this is from the database

  CheckPoint({
    required this.id,
    required this.position,
    required this.name,
    required this.description,
    required this.severity,
    required this.isReported,   // Made required to avoid null issues
    this.reportedTime,
    required this.isFromDatabase,
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

// You'll need to add this model class if it doesn't exist already
enum IncidentType {
  flood,
  fire,
  earthquake,
  landslide,
  storm,
  other,
}

class IncidentReport {
  final String title;
  final String location;
  final String date;
  final IncidentType type;
  final String description;
  final bool verified;
  final String? imageUrl;
  final List<String>? imageBase64List;
  final Timestamp timestamp;
  final double latitude;
  final double longitude;
  final int verificationCount;

  IncidentReport({
    required this.title,
    required this.location,
    required this.date,
    required this.type,
    required this.description,
    required this.verified,
    this.imageUrl,
    this.imageBase64List,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.verificationCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'date': date,
      'type': type.toString().split('.').last,
      'description': description,
      'verified': verified,
      'imageUrl': imageUrl,
      'imageBase64List': imageBase64List,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'verificationCount': verificationCount,
    };
  }
}