import 'package:flutter/material.dart';
import '../models/incident_report.dart';
import '../services/incident_service.dart';
import 'dart:convert'; // For base64Decode
import 'package:cloud_firestore/cloud_firestore.dart';


class IncidentDetailsPage extends StatefulWidget {
  final IncidentReport incident;

  const IncidentDetailsPage({super.key, required this.incident});

  @override
  State<IncidentDetailsPage> createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  final IncidentService _incidentService = IncidentService();
  late bool _isVerified;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.incident.verified;
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isVerified ? Icons.verified : Icons.pending,
                        size: 16,
                        color: _isVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isVerified ? 'Verified' : 'Pending Verification',
                        style: TextStyle(
                          color: _isVerified ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Only show this for admins or authorized users in a real app
                const SizedBox(width: 16),
                _isLoading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
  icon: Icon(_isVerified ? Icons.cancel : Icons.check_circle),
  label: Text(_isVerified ? 'Mark as Unverified' : 'Mark as Verified'),
  onPressed: () async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Only update if we have a document ID
      if (widget.incident.id != null) {
        await _incidentService.updateIncident(
          widget.incident.id!,
          IncidentReport(
            id: widget.incident.id,
            title: widget.incident.title,
            location: widget.incident.location,
            date: widget.incident.date,
            type: widget.incident.type,
            description: widget.incident.description,
            verified: !_isVerified,
            imageUrl: widget.incident.imageUrl,
            imageBase64: widget.incident.imageBase64, // Preserve the Base64 image
            timestamp: Timestamp.now(), // 🛠️ Fix: add this

          ),
        );
        
        setState(() {
          _isVerified = !_isVerified;
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
  },
),
              ],
            ),
            const SizedBox(height: 24),

            // Display the image if available
          // Display the image if available (either URL or Base64)
if ((widget.incident.imageUrl != null && widget.incident.imageUrl!.isNotEmpty) || 
    (widget.incident.imageBase64 != null && widget.incident.imageBase64!.isNotEmpty))
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Incident Image',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.incident.imageBase64 != null && widget.incident.imageBase64!.isNotEmpty
          // Display Base64 image
          ? Image.memory(
              base64Decode(widget.incident.imageBase64!),
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
          // Display URL image (as a fallback for existing records)
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
                    'Flood',
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

            // Add delete button for admin or the user who created the incident
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