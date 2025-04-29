import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/flood_prediction_service.dart';
import 'shared_layer/shared_scaffold.dart';

class HeatMapPage extends StatefulWidget {
  const HeatMapPage({Key? key}) : super(key: key);
  
  @override
  State<HeatMapPage> createState() => _HeatMapPageState();
}

class _HeatMapPageState extends State<HeatMapPage> {
  final MapController _mapController = MapController();
  List<HeatZone> _heatZones = [];
  List<Incident> _recentIncidents = _createRecentIncidents();
  final FloodPredictionService _predictionService = FloodPredictionService();
  
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isLoadingPredictions = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeFrame = 'Day';
  String _selectedIncidentType = 'All';
  bool _showFloodPredictions = true;
  
  // Singapore's bounding coordinates
  static final LatLngBounds singaporeBounds = LatLngBounds(
    const LatLng(1.15, 103.6), // Southwest
    const LatLng(1.47, 104.05), // Northeast
    
  );
  
  // Statistics for dashboard
  int _highRiskZones = 0;
  int _mediumRiskZones = 0;
  int _lowRiskZones = 0;
  double _safetyScore = 0.0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitBounds(singaporeBounds, options: const FitBoundsOptions(padding: EdgeInsets.all(16)));
    });
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      final permission = await _checkLocationPermission();
      if (!permission) return;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
          if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
          
      _mapController.move(_currentPosition!, 15.0);
      _setupLocationUpdates();
      _loadFloodPredictions();
          }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPosition = const LatLng(1.429387, 103.835090); // Default
      });
      _loadFloodPredictions();
    }
  }
  
 // Update the _loadFloodPredictions method in _HeatMapPageState class
Future<void> _loadFloodPredictions() async {
  if (!_showFloodPredictions) return;
  
  setState(() {
    _isLoadingPredictions = true;
  });
  
  try {
    // Generate a grid of points across Singapore
    final List<LatLng> grid = _generateGridPoints(
      singaporeBounds.southWest, 
      singaporeBounds.northEast,
      gridSize: 0.02, // Adjust based on your needs
    );
    
    // Get flood predictions for these points
print('Attempting to fetch predictions...');
final predictions = await _predictionService.batchPredict(grid);
print('Received predictions: ${predictions.length}');    
    // Convert predictions to heat zones
    final List<HeatZone> predictionZones = [];
    int highRisk = 0, mediumRisk = 0, lowRisk = 0;
    
    for (final prediction in predictions) {
      // print(prediction);
      final lat = prediction['latitude'];
      final lng = prediction['longitude'];
      final severity = _parseSeverity(prediction['severity']);
      
      // Update counters
      if (severity == SeverityLevel.high) highRisk++;
      else if (severity == SeverityLevel.medium) mediumRisk++;
      else if (severity == SeverityLevel.low) lowRisk++;
      
      predictionZones.add(HeatZone(
        center: LatLng(lat, lng),
        radius: 100, // Adjust radius as needed
        severity: severity,
        incidentCount: 1,
        incidentType: 'Flood',
      ));
    }
    
    // Calculate safety score (simple algorithm - can be improved)
    final totalZones = highRisk + mediumRisk + lowRisk;
    if (totalZones > 0) {
      final weightedScore = (lowRisk * 5 + mediumRisk * 3 + highRisk * 1) / totalZones;
      final safetyScore = (weightedScore / 5) * 5; // Scale to 5
      


      setState(() {
        _safetyScore = safetyScore;
      });
    }
    
    setState(() {
      _heatZones.clear();
      _heatZones.addAll(predictionZones);
      _highRiskZones = highRisk;
      _mediumRiskZones = mediumRisk;
      _lowRiskZones = lowRisk;
      _isLoadingPredictions = false;
    });
  } catch (e) {
    print('Error loading predictions: $e');
    setState(() {
      _isLoadingPredictions = false;
    });
  }
}
  
  List<LatLng> _generateGridPoints(LatLng southwest, LatLng northeast, {double gridSize = 0.01}) {
    final List<LatLng> points = [];
    
    for (double lat = southwest.latitude; lat <= northeast.latitude; lat += gridSize) {
      for (double lng = southwest.longitude; lng <= northeast.longitude; lng += gridSize) {
        points.add(LatLng(lat, lng));
      }
    }
    
    return points;
  }
  
  SeverityLevel _parseSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return SeverityLevel.high;
      case 'medium':
        return SeverityLevel.medium;
      case 'low':
        return SeverityLevel.low;
      default:
        return SeverityLevel.low;
    }
  }
  
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return false;
    }
    return true;
  }
  
  void _setupLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      )
    ).listen((position) {
      if (mounted) {
        setState(() => _currentPosition = LatLng(position.latitude, position.longitude));
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    _selectedIncidentType = localizations.hmTypeAll;
    _selectedTimeFrame = localizations.hmDurationDay;

    _heatZones = _createHeatZones(localizations);
    _recentIncidents = _createRecentIncidents();

    final filteredHeatZones = _selectedIncidentType == localizations.hmTypeAll
        ? _heatZones
        : _heatZones.where((zone) => zone.incidentType == _selectedIncidentType).toList();
    
    return SharedScaffold(
      currentIndex: 1,
      appBar: AppBar(
        title: Text(
          localizations.hmBarTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            _buildLegend(localizations),
            const SizedBox(height: 15),
            _isLoadingPredictions
                ? Center(
                    child: Column(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Loading flood predictions...'),
                      ],
                    ),
                  )
                : _buildMap(filteredHeatZones),
            const SizedBox(height: 20),
            _buildStatsCard(localizations),
            const SizedBox(height: 20),
            // _buildRecentIncidents(localizations)
          ],
        ),
      ),
    );
  }

  // Widget _buildFilterControls(AppLocalizations localizations) {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       children: [
  //         DropdownButton<String>(
  //           value: _selectedIncidentType,
  //           items: [
  //             localizations.hmTypeAll,
  //             localizations.hmTypeFire,
  //             localizations.hmTypeCrime,
  //             localizations.hmTypeAccident
  //           ].map((value) {
  //             return DropdownMenuItem<String>(
  //               value: value,
  //               child: Text(value),
  //             );
  //           }).toList(),
  //           onChanged: (newValue) => setState(() => _selectedIncidentType = newValue!),
  //         ),
  //         const SizedBox(width: 20),
  //         DropdownButton<String>(
  //           value: _selectedTimeFrame,
  //           items: [
  //             localizations.hmDurationDay,
  //             localizations.hmDurationWeek,
  //             localizations.hmDurationMonth
  //           ].map((value) {
  //             return DropdownMenuItem<String>(
  //               value: value,
  //               child: Text(value),
  //             );
  //           }).toList(),
  //           onChanged: (newValue) => setState(() => _selectedTimeFrame = newValue!),
  //         ),

  //         const SizedBox(width: 20),
  //         // Toggle for flood predictions
  //         Row(
  //           children: [
  //             const Text('Flood Predictions'),
  //             Switch(
  //               value: _showFloodPredictions,
  //               onChanged: (value) {
  //                 setState(() => _showFloodPredictions = value);
  //                 if (value) {
  //                   _loadFloodPredictions();
  //                 } else {
  //                   setState(() => _heatZones.clear());
  //                 }
  //               },
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadFloodPredictions(); // Reload predictions for new date
    }
  }

  Widget _buildLegend(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Colors.red.withOpacity(0.6), label: localizations.hmHighRisk),
        const SizedBox(width: 15),
        _LegendItem(color: Colors.orange.withOpacity(0.6), label: localizations.hmMediumRisk),
        const SizedBox(width: 15),
        _LegendItem(color: Colors.yellow.withOpacity(0.5), label: localizations.hmLowRisk),
      ],
    );
  }
  
  Widget _buildMap(List<HeatZone> heatZones) {
    return SizedBox(
      height: 350,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentPosition ?? const LatLng(1.3521, 103.8198),
                zoom: 10.5,
                maxZoom: 18,
                minZoom: 5,
                interactiveFlags: InteractiveFlag.all,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safe_guard_sg',
                ),
                _buildHeatZonesLayer(heatZones),
                _buildUserLocationMarker(),
                _buildMapControls(),
              ],
            ),
      ),
    );
  }
  
  CircleLayer _buildHeatZonesLayer(List<HeatZone> zones) {
    return CircleLayer(
      circles: zones.map((zone) => CircleMarker(
        point: zone.center,
        color: _getSeverityColor(zone.severity),
        borderColor: _getSeverityBorderColor(zone.severity),
        borderStrokeWidth: 2,
        radius: zone.radius.toDouble(),
        useRadiusInMeter: true,
      )).toList(),
    );
  }
  
  MarkerLayer _buildUserLocationMarker() {
    return MarkerLayer(
      markers: _currentPosition != null
          ? [
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
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8)
                        ],
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
            ]
          : [],
    );
  }
  
  Widget _buildMapControls() {
    return Stack(
      children: [
        Positioned(
          bottom: 10,
          right: 10,
          child: Column(
            children: [
              _buildMapControlButton(
                icon: Icons.zoom_in,
                heroTag: 'zoom_in',
                onPressed: () => _mapController.move(_mapController.center, _mapController.zoom + 1),
              ),
              const SizedBox(height: 8),
              _buildMapControlButton(
                icon: Icons.zoom_out,
                heroTag: 'zoom_out',
                onPressed: () => _mapController.move(_mapController.center, _mapController.zoom - 1),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 10,
          left: 10,
          child: _buildMapControlButton(
            icon: Icons.my_location,
            heroTag: 'recenter',
            color: Colors.blue,
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(_currentPosition!, 14.0);
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildMapControlButton({
    required IconData icon,
    required String heroTag,
    required VoidCallback onPressed,
    Color color = Colors.black,
  }) {
    return FloatingActionButton(
      mini: true,
      heroTag: heroTag,
      backgroundColor: Colors.white,
      foregroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color),
      ),
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  Widget _buildStatsCard(AppLocalizations localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.hmSafetyStatistics,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(title: localizations.hmHighRisk, value: '2', color: Colors.red),
                _StatItem(title: localizations.hmMediumRisk, value: '2', color: Colors.orange),
                _StatItem(title: localizations.hmLowRisk, value: '2', color: Colors.yellow),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.hmAISafetyScore,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star, color: Colors.amber),
                    Icon(_safetyScore >= 4.0 ? Icons.star : Icons.star_half, color: Colors.amber),
                    Icon(_safetyScore >= 4.5 ? Icons.star : Icons.star_border, color: Colors.amber),
                    const SizedBox(width: 5),
                    Text(
                      '${_safetyScore.toStringAsFixed(1)}/5',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFloodRiskDashboard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flood Risk Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Simple bar chart
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBarChartBar('High', _highRiskZones, Colors.red),
                  _buildBarChartBar('Medium', _mediumRiskZones, Colors.orange),
                  _buildBarChartBar('Low', _lowRiskZones, Colors.yellow),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Weather and prediction info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Weather:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Rainy, 28°C'),
                    const SizedBox(height: 8),
                    const Text('Rainfall Prediction:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Heavy rain expected in next 12 hours'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Model Confidence:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('89%'),
                    const SizedBox(height: 8),
                    const Text('Last Updated:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${DateTime.now().hour}:${DateTime.now().minute}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // General advice
            const Text(
              'Safety Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedIncidentType == 'Flood' ? 
                'Avoid low-lying areas. Keep emergency supplies ready. Stay tuned to weather updates.' :
                'Follow standard safety protocols for the selected incident type.',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBarChartBar(String label, int value, Color color) {
    // Calculate height based on value (with min and max)
    final int maxValue = [_highRiskZones, _mediumRiskZones, _lowRiskZones, 1].reduce((a, b) => a > b ? a : b);
    final double height = value > 0 ? (value / maxValue) * 100 : 10;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }
  
  Widget _buildRecentIncidents(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.hmRecentIncidents,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...filteredIncidents(localizations).map((incident) => _IncidentCard(incident: incident)).toList(),
      ],
    );
  }

  List<Incident> filteredIncidents(AppLocalizations localizations) {
    return _selectedIncidentType == localizations.hmTypeAll
        ? _recentIncidents
        : _recentIncidents.where((incident) => incident.type == _selectedIncidentType).toList();
  }

  static List<HeatZone> _createHeatZones(AppLocalizations localizations) {
    return [
      // High risk zones (red) - North
      HeatZone(
        center: const LatLng(1.4400, 103.8040), // Sembawang
        radius: 250,
        severity: SeverityLevel.high,
        incidentCount: 10,
        incidentType: 'Fire',
      ),
      // ... other zones
    ];
  }

  static List<Incident> _createRecentIncidents() {
    return [
      Incident(
        id: 1,
        position: const LatLng(1.432700, 103.839400),
        type: 'Fire',
        severity: SeverityLevel.high,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        description: 'Kitchen fire in HDB block',
      ),
      // Add a flood incident
      Incident(
        id: 2,
        position: const LatLng(1.3521, 103.8198),
        type: 'Flood',
        severity: SeverityLevel.medium,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        description: 'Flash flooding in downtown area after heavy rainfall',
      ),
    ];
  }
}

// Helper Widgets
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  
  @override
  Widget build(BuildContext context) {
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
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatItem({
    required this.title,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;
  const _IncidentCard({required this.incident});
  
  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        leading: _getSeverityIcon(incident.severity),
        title: Text(_getLocalizedIncidentType(context, incident.type)),
        subtitle: Text(_formatDateTime(incident.timestamp)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showIncidentInfo(context, incident, localizations),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
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

  void _showIncidentInfo(BuildContext context, Incident incident, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getSeverityIcon(incident.severity),
            const SizedBox(width: 10),
            Text(_getLocalizedIncidentType(context, incident.type)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${localizations.hmSeverity}: ${_getLocalizedSeverityLevel(context, incident.severity, true)}'),
            const SizedBox(height: 5),
            Text('${localizations.time}: ${_formatDateTime(incident.timestamp)}'),
            const SizedBox(height: 10),
            Text(incident.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Data Models
class HeatZone {
  final LatLng center;
  final double radius;
  final SeverityLevel severity;
  final int incidentCount;
  final String incidentType;
  const HeatZone({
    required this.center,
    required this.radius,
    required this.severity,
    required this.incidentCount,
    required this.incidentType,
  });
}

class Incident {
  final int id;
  final LatLng position;
  final String type;
  final SeverityLevel severity;
  final DateTime timestamp;
  final String description;
  const Incident({
    required this.id,
    required this.position,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.description,
  });
}

enum SeverityLevel { high, medium, low }

// Helper Functions
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

String _getLocalizedSeverityLevel(BuildContext context, SeverityLevel severityLevel, bool toupper) {
  final AppLocalizations localizations = AppLocalizations.of(context)!;

  final key = severityLevel.name;
  String translation = '';
  
  switch (key) {
    case 'low':
      translation = localizations.low;
    case 'medium':
      translation = localizations.medium;
    case 'high':
      translation = localizations.high;
    default:
      translation = localizations.low;
  }

  if (toupper && ['en', 'ms'].contains(Localizations.localeOf(context).languageCode)) {
    return translation.toUpperCase();
  }
  return translation;
}

String _getLocalizedIncidentType(BuildContext context, String type) {
  final AppLocalizations localizations = AppLocalizations.of(context)!;

  String translation = '';
  
  switch (type) {
    case 'All':
      translation = localizations.hmTypeAll;
    case 'Crime':
      translation = localizations.hmTypeCrime;
    case 'Fire':
      translation = localizations.hmTypeFire;
    case 'Accident':
      translation = localizations.hmTypeAccident;
    default:
      translation = 'Unknown';
  }

  return translation;
}
