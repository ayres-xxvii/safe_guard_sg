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
  final String? imageBase64;
  final Timestamp timestamp; // Add this field


  IncidentReport({
    this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.type,
    required this.description,
    required this.verified,
    this.imageUrl,
    this.imageBase64,
    required this.timestamp, // Make it required

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
      'imageBase64': imageBase64,
      'timestamp': timestamp, // Include in map

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
    imageBase64: data['imageBase64'],
    timestamp: data['timestamp'] ?? Timestamp.now(), // Extract timestamp or use default

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