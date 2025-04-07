import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:safe_guard_sg/recent_incident.dart'; // Import from your file containing IncidentReport

class IncidentDetailsPage extends StatelessWidget {
  final IncidentReport? incident;

  const IncidentDetailsPage({
    super.key,
    this.incident,
  });

  @override
  Widget build(BuildContext context) {
    // Use a default incident if none provided
    final IncidentReport displayIncident = incident ?? IncidentReport(
      title: 'No Incident Selected',
      location: 'N/A',
      date: 'N/A',
      type: IncidentType.flood,
      description: 'Please select an incident from the list to view details.',
      verified: false,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4DD0C7),
        foregroundColor: Colors.white,
        title: const Text('Incident Details'),
        elevation: 0,
      ),
      body: incident == null
          ? _buildNoIncidentView(context)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image or map placeholder
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.blue.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        Icons.water_damage,
                        size: 80,
                        color: Colors.blue.withOpacity(0.6),
                      ),
                    ),
                  ),
                  
                  // Incident title and verification badge
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayIncident.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (displayIncident.verified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Incident metadata
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.location_on, 'Location', displayIncident.location),
                            const Divider(height: 24),
                            _buildInfoRow(Icons.calendar_today, 'Date Reported', displayIncident.date),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.category, 
                              'Incident Type', 
                              _formatIncidentType(displayIncident.type),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Description section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayIncident.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Safety tips
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.amber[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Safety Tips',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSafetyTip('Avoid driving through flooded areas'),
                        _buildSafetyTip('Stay away from electrical equipment in flooded areas'),
                        _buildSafetyTip('Follow instructions from emergency services'),
                        _buildSafetyTip('Move to higher ground if necessary'),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4DD0C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.report),
                            label: const Text('Report Update'),
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4DD0C7),
                              side: const BorderSide(color: Color(0xFF4DD0C7)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // View to show when no incident is provided
  Widget _buildNoIncidentView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_damage,
            size: 80,
            color: Colors.blue.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Incident Selected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please select an incident from the list to view its details.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.list),
            label: const Text('View All Incidents'),
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DD0C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
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
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.amber[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatIncidentType(IncidentType type) {
    switch (type) {
      case IncidentType.flood:
        return 'Flood';
      default:
        return 'Unknown';
    }
  }
}