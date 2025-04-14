import 'dart:convert'; // For Base64 decoding
import 'package:flutter/material.dart';
import '../models/incident_report.dart';
import '../services/incident_service.dart';
import 'incident_details.dart';

class RecentIncidentsPage extends StatefulWidget {
  const RecentIncidentsPage({super.key});

  @override
  State<RecentIncidentsPage> createState() => _RecentIncidentsPageState();
}

class _RecentIncidentsPageState extends State<RecentIncidentsPage> {
  final IncidentService _incidentService = IncidentService();

  // Helper method to determine which image widget to display based on available data
Widget _getImageWidget(IncidentReport incident) {
  // Try Base64 first (from the list)
  if (incident.imageBase64List != null && incident.imageBase64List!.isNotEmpty) {
    try {
      final imageBytes = base64Decode(incident.imageBase64List!.first); // Use first image
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading Base64 image: $error');
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      );
    } catch (e) {
      print('Error decoding Base64 image: $e');
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Color.fromARGB(255, 117, 117, 117)),
      );
    }
  }

  // Then fallback to imageUrl
  else if (incident.imageUrl != null && incident.imageUrl!.isNotEmpty) {
    return Image.network(
      incident.imageUrl!,
      fit: BoxFit.cover,
      width: 100,
      height: 100,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF73D3D0),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.red),
        );
      },
    );
  }

  // Default fallback
  else {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, color: Color.fromARGB(255, 123, 122, 122)),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Incidents'),
        backgroundColor: const Color(0xFF73D3D0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Trigger UI refresh manually if needed
            },
          ),
        ],
      ),
      body: StreamBuilder<List<IncidentReport>>(
        stream: _incidentService.getIncidents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF73D3D0)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load incidents: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No incidents reported yet'));
          }

          final incidents = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Trigger refresh to load data again
            },
            color: const Color(0xFF73D3D0),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IncidentDetailsPage(incident: incident),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _getImageWidget(incident),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                               Row(
  children: [
    Expanded(
      child: Text(
        incident.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    if (incident.verified)
      Row(
        children: [
          const Icon(
            Icons.verified,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '${incident.verificationCount} ',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ],
      ),
  ],
),

                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        incident.location,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      incident.date,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],


                                        
                                      ),
                                    ),
                                  ],

                                  
                                ),
// ✅ Add this:
const SizedBox(height: 4),
Text(
  '${incident.verificationCount} user(s) verified this report',
  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
),

                                const SizedBox(height: 8),
                                Text(
                                  incident.description,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
