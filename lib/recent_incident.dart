import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'incident_details.dart';


class RecentIncidentsPage extends StatefulWidget {
  const RecentIncidentsPage({super.key});

  @override
  State<RecentIncidentsPage> createState() => _RecentIncidentsPageState();
}

class _RecentIncidentsPageState extends State<RecentIncidentsPage> {
  final List<IncidentReport> _incidents = [
    IncidentReport(
      title: 'Flash Flood in Bukit Timah',
      location: 'Bukit Timah Road',
      date: 'Apr 5, 2025',
      type: IncidentType.flood,
      description: 'Heavy rainfall caused flash floods, affecting traffic and damaging some parked vehicles.',
      verified: true,
    ),
    IncidentReport(
      title: 'Flooded Basement Carpark',
      location: 'Toa Payoh',
      date: 'Apr 4, 2025',
      type: IncidentType.flood,
      description: 'Basement carpark was reported flooded due to blocked drainage system.',
      verified: true,
    ),
    IncidentReport(
      title: 'Severe Water Accumulation',
      location: 'Jurong West',
      date: 'Apr 3, 2025',
      type: IncidentType.flood,
      description: 'Water accumulation along main road led to minor accidents and road closures.',
      verified: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4DD0C7),
        foregroundColor: Colors.white,
        title: const Text('Recent Incidents'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Statistics card
          Container(
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
              children: [
                const Text(
                  'Flood Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatCard('Floods', '${_incidents.length}', Icons.water_damage, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Incident list
          Expanded(
            child: _incidents.isEmpty
                ? Center(
                    child: Text(
                      'No flood incidents reported',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _incidents.length,
                    itemBuilder: (context, index) {
                      final incident = _incidents[index];
                      return _buildIncidentCard(incident);
                    },
                  ),
          ),
        ],
      ),

    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentCard(IncidentReport incident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _incidentTypeIcon(incident.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    incident.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (incident.verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  incident.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  incident.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              incident.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
  
                TextButton.icon(
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View Details'),
                  onPressed: ()  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IncidentDetailsPage(incident: incident),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4DD0C7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _incidentTypeIcon(IncidentType type) {
    IconData icon = Icons.water_damage;
    Color color = Colors.blue;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// Updated enum for flood only
enum IncidentType {
  flood,
}

class IncidentReport {
  final String title;
  final String location;
  final String date;
  final IncidentType type;
  final String description;
  final bool verified;

  IncidentReport({
    required this.title,
    required this.location,
    required this.date,
    required this.type,
    required this.description,
    this.verified = false,
  });
}
