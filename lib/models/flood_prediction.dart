// lib/models/flood_prediction.dart
import 'package:latlong2/latlong.dart';

enum FloodRiskLevel {
  low,
  medium,
  high,
}

class FloodPrediction {
  final LatLng location;
  final FloodRiskLevel riskLevel;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;
  
  const FloodPrediction({
    required this.location,
    required this.riskLevel,
    required this.confidence,
    required this.timestamp,
    this.additionalData,
  });
  
  factory FloodPrediction.fromJson(Map<String, dynamic> json) {
    return FloodPrediction(
      location: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      riskLevel: _parseRiskLevel(json['prediction']),
      confidence: json['probability'] as double? ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      additionalData: json['additional_data'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'prediction': riskLevel.toString().split('.').last,
      'probability': confidence,
      'timestamp': timestamp.toIso8601String(),
      'additional_data': additionalData,
    };
  }
  
  static FloodRiskLevel _parseRiskLevel(dynamic value) {
    if (value is int) {
      // If it's a numeric value
      switch (value) {
        case 0: return FloodRiskLevel.low;
        case 1: return FloodRiskLevel.medium;
        case 2: return FloodRiskLevel.high;
        default: return FloodRiskLevel.low;
      }
    } else if (value is String) {
      // If it's a string value
      final normalized = value.toLowerCase();
      if (normalized.contains('high')) return FloodRiskLevel.high;
      if (normalized.contains('medium')) return FloodRiskLevel.medium;
      return FloodRiskLevel.low;
    }
    return FloodRiskLevel.low;
  }
}

class FloodRiskZone {
  final LatLng center;
  final double radius; // in meters
  final FloodRiskLevel riskLevel;
  final double confidence;
  final DateTime lastUpdated;
  
  const FloodRiskZone({
    required this.center,
    required this.radius,
    required this.riskLevel,
    required this.confidence,
    required this.lastUpdated,
  });
  
  // Convert a prediction into a risk zone
  factory FloodRiskZone.fromPrediction(
    FloodPrediction prediction, {
    double radius = 200.0,
  }) {
    return FloodRiskZone(
      center: prediction.location,
      radius: radius,
      riskLevel: prediction.riskLevel,
      confidence: prediction.confidence,
      lastUpdated: prediction.timestamp,
    );
  }
}