// lib/services/incident_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_report.dart';

class IncidentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'incidents';

  // Add a new incident to Firestore
Future<String> addIncident(IncidentReport incident) async {
  try {
    // Convert incident to a map
    Map<String, dynamic> incidentData = incident.toMap();
    
    // Add to Firestore
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('incidents')
        .add(incidentData);
    
    return docRef.id;
  } catch (e) {
    print('Error adding incident: $e');
    throw e; // Re-throw to handle in UI
  }
}

  // Get all incidents from Firestore
  Stream<List<IncidentReport>> getIncidents() {
    return _db
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentReport.fromFirestore(doc))
            .toList());
  }

  // Get a specific incident by ID
  Future<IncidentReport?> getIncidentById(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection(_collection).doc(id).get();
      if (doc.exists) {
        return IncidentReport.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting incident: $e');
      throw e;
    }
  }

  // Update an incident
Future<void> updateIncident(String id, IncidentReport incident) async {
  try {
    await _db.collection(_collection).doc(id).update({
      'title': incident.title,
      'location': incident.location,
      'date': incident.date,
      'type': incident.type.toString().split('.').last,
      'description': incident.description,
      'verified': incident.verified,
      'imageUrl': incident.imageUrl,
      'imageBase64List': incident.imageBase64List,
      'timestamp': incident.timestamp,
      'latitude': incident.latitude,
      'longitude': incident.longitude,
      'verificationCount': incident.verificationCount,
    });
  } catch (e) {
    print('Error updating incident: $e');
    throw e;
  }
}


  // Delete an incident
  Future<void> deleteIncident(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting incident: $e');
      throw e;
    }
  }
}