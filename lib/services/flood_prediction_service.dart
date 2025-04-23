// lib/services/flood_prediction_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class FloodPredictionService {
  // Update this URL to your actual Flask API endpoint
  final String apiUrl = 'http://10.0.2.2:5000'; // For Android Emulator
  // Use 'http://127.0.0.1:5000' for iOS simulator or local testing

  // Single point prediction
  Future<Map<String, dynamic>> predict(LatLng location) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': location.latitude,
          'longitude': location.longitude,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get prediction: ${response.body}');
      }
    } catch (e) {
      print('Error making prediction: $e');
      throw Exception('Prediction error: $e');
    }
  }

  // Batch prediction for multiple locations
  Future<List<Map<String, dynamic>>> batchPredict(List<LatLng> locations) async {
    try {
      print('Sending batch prediction request for ${locations.length} locations');
      
      // Convert locations to list of lat/lng maps
      final locationsList = locations.map((loc) => {
        'latitude': loc.latitude,
        'longitude': loc.longitude,
      }).toList();

      final response = await http.post(
        Uri.parse('$apiUrl/batch_predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'locations': locationsList,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Check if the response is a list or has a 'predictions' key
        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map && responseData.containsKey('predictions')) {
          return List<Map<String, dynamic>>.from(responseData['predictions']);
        } else if (responseData is Map && responseData.containsKey('error')) {
          throw Exception('Failed to get batch predictions: $responseData');
        } else {
          // Convert to expected format if needed
          return [responseData];
        }
      } else {
        throw Exception('Failed to get batch predictions: ${response.body}');
      }
    } catch (e) {
      print('Error making batch prediction: $e');
      throw Exception('Batch prediction error: $e');
    }
  }
}