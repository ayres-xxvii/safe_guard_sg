import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentType {
  flood,
  fire,
  earthquake,
  landslide,
  storm,
  other,
}

class IncidentReport {
  final String? id;
  final String title;
  final String location;
  final String date;
  final IncidentType type;
  final String description;
  final bool verified;
  final String? imageUrl;
  final List<String>? imageBase64List; // Changed from String? to List<String>?  
  final Timestamp timestamp;
  final double latitude;
  final double longitude;
  final int verificationCount;

  IncidentReport({
    this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.type,
    required this.description,
    required this.verified,
    this.imageUrl,
    this.imageBase64List, // Changed parameter name
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
      'imageBase64List': imageBase64List, // Changed field name
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'verificationCount': verificationCount,
    };
  }

  // Static method to create an IncidentReport from a Firestore document
  static IncidentReport fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IncidentReport(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      type: _getTypeFromString(data['type']),
      description: data['description'] ?? '',
      verified: data['verified'] ?? false,
      imageUrl: data['imageUrl'],
      imageBase64List: data['imageBase64List'] != null 
        ? List<String>.from(data['imageBase64List']) 
        : null,
              timestamp: data['timestamp'] ?? Timestamp.now(),
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      verificationCount: data['verificationCount'] ?? 0,
    );
  }

  // Helper method to convert string to IncidentType enum
  static IncidentType _getTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'flood':
        return IncidentType.flood;
      case 'fire':
        return IncidentType.fire;
      case 'earthquake':
        return IncidentType.earthquake;
      case 'landslide':
        return IncidentType.landslide;
      case 'storm':
        return IncidentType.storm;
      case 'other':
        return IncidentType.other;
      default:
        return IncidentType.flood; // Default value
    }
  }
}