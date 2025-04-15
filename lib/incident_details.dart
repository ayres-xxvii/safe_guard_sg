import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/incident_report.dart';
import '../services/incident_service.dart';
import 'dart:convert'; // For base64Decode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class IncidentDetailsPage extends StatefulWidget {
  final IncidentReport incident;

  const IncidentDetailsPage({super.key, required this.incident});

  @override
  State<IncidentDetailsPage> createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  final IncidentService _incidentService = IncidentService();
  late int verificationCount;
  bool _isLoading = false;
  int _currentImageIndex = 0; // Track current image index for the carousel
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    verificationCount = widget.incident.verificationCount;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openInExternalMap() async {
    // Open in external map app
    final url = 'https://www.openstreetmap.org/?mlat=${widget.incident.latitude}&mlon=${widget.incident.longitude}&zoom=16';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4DD0C7),
        foregroundColor: Colors.white,
        title: const Text('Incident Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Title
            Text(
              widget.incident.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Verification Status
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: verificationCount > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        verificationCount > 0 ? Icons.verified : Icons.pending,
                        size: 16,
                        color: verificationCount > 0 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        verificationCount > 0
                            ? '$verificationCount verification${verificationCount > 1 ? 's' : ''}'
                            : 'Pending verification',
                        style: TextStyle(
                          color: verificationCount > 0
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
      
            // Display the image(s) if available
            if ((widget.incident.imageUrl != null && widget.incident.imageUrl!.isNotEmpty) || 
                (widget.incident.imageBase64List != null && widget.incident.imageBase64List!.isNotEmpty))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Incident Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.incident.imageBase64List != null && widget.incident.imageBase64List!.length > 1)
                        Text(
                          '${_currentImageIndex + 1}/${widget.incident.imageBase64List!.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Handle multiple images with PageView or single image based on available data
                  if (widget.incident.imageBase64List != null && widget.incident.imageBase64List!.length > 1)
                    // Multiple images - use PageView
                    Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.incident.imageBase64List!.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    base64Decode(widget.incident.imageBase64List![index]),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.error, color: Colors.red),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Image indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.incident.imageBase64List!.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? const Color(0xFF4DD0C7)
                                      : Colors.grey[300],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    )
                  else
                    // Single image case - either from base64List[0] or from imageUrl
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.incident.imageBase64List != null && widget.incident.imageBase64List!.isNotEmpty
                        ? Image.memory(
                            base64Decode(widget.incident.imageBase64List![0]),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            },
                          )
                        : Image.network(
                            widget.incident.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            },
                          ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),

            // Incident Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    widget.incident.location,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date Reported',
                    widget.incident.date,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.category,
                    'Type',
                    widget.incident.type.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.incident.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            if (widget.incident.latitude != null && widget.incident.longitude != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Location Map',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in Maps'),
                        onPressed: _openInExternalMap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(widget.incident.latitude!, widget.incident.longitude!),
                          zoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          MarkerLayer(
                            markers: [
                             Marker(
                                point: LatLng(widget.incident.latitude!, widget.incident.longitude!),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Display coordinates text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pin_drop, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Lat: ${widget.incident.latitude!.toStringAsFixed(6)}, Lon: ${widget.incident.longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Add delete button for admin or the user who created the incident
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mark as Verified/Unverified Button
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          icon: Icon(
                            verificationCount > 0 ? Icons.cancel : Icons.check_circle,
                            color: Colors.white,
                          ),
                          label: Text(
                            verificationCount > 0 ? 'Mark as Unverified' : 'Mark as Verified',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: verificationCount > 0 ? Colors.deepOrange : Colors.green[700],
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              if (widget.incident.id != null) {
                                final newCount = verificationCount > 0
                                    ? verificationCount - 1
                                    : verificationCount + 1;

                                await _incidentService.updateIncident(
                                  widget.incident.id!,
                                  IncidentReport(
                                    id: widget.incident.id,
                                    title: widget.incident.title,
                                    location: widget.incident.location,
                                    date: widget.incident.date,
                                    type: widget.incident.type,
                                    description: widget.incident.description,
                                    verified: newCount > 0, // Update verified status
                                    imageUrl: widget.incident.imageUrl,
                                    imageBase64List: widget.incident.imageBase64List,
                                    timestamp: Timestamp.now(),
                                    latitude: widget.incident.latitude,
                                    longitude: widget.incident.longitude,
                                    verificationCount: newCount < 0 ? 0 : newCount,
                                  ),
                                );

                                setState(() {
                                  verificationCount = newCount < 0 ? 0 : newCount;
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error updating status: $e')),
                              );
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        ),

                  const SizedBox(width: 16), // Add some space between buttons

                  // Delete Incident Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Incident'),
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Incident'),
                          content: const Text('Are you sure you want to delete this incident report?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              onPressed: () async {
                                // Only delete if we have a document ID
                                if (widget.incident.id != null) {
                                  try {
                                    await _incidentService.deleteIncident(widget.incident.id!);
                                    Navigator.of(context).pop(); // Close dialog
                                    Navigator.of(context).pop(); // Return to list page
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Incident deleted successfully')),
                                    );
                                  } catch (e) {
                                    Navigator.of(context).pop(); // Close dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error deleting incident: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}