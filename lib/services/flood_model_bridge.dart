// lib/services/flood_model_bridge.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:safe_guard_sg/models/flood_prediction.dart';

class FloodModelBridge {
  final String apiUrl;
  
  FloodModelBridge({this.apiUrl = 'http://your-api-url:5000'});
  
  // Get prediction for a specific location
  Future<FloodPrediction> getPredictionForLocation(LatLng location, {
    Map<String, dynamic>? weatherData,
  }) async {
    try {
      final requestData = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'weather_data': weatherData ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final response = await http.post(
        Uri.parse('$apiUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FloodPrediction.fromJson(data);
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Get predictions for multiple locations (optimized API call)
  Future<List<FloodPrediction>> getPredictionsForArea(
    LatLngBounds bounds, {
    double gridSpacing = 0.01, // Grid spacing in degrees
    Map<String, dynamic>? weatherData,
  }) async {
    try {
      // Create a grid of points within the bounds
      final List<Map<String, dynamic>> locationPoints = [];
      
      for (double lat = bounds.southWest.latitude; 
           lat <= bounds.northEast.latitude; 
           lat += gridSpacing) {
        for (double lng = bounds.southWest.longitude; 
             lng <= bounds.northEast.longitude; 
             lng += gridSpacing) {
          locationPoints.add({
            'latitude': lat,
            'longitude': lng,
          });
        }
      }
      
      final requestData = {
        'locations': locationPoints,
        'weather_data': weatherData ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final response = await http.post(
        Uri.parse('$apiUrl/batch_predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = (data['predictions'] as List)
            .map((item) => FloodPrediction.fromJson(item))
            .toList();
        return predictions;
      } else {
        throw Exception('Failed to get batch predictions: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Get historical prediction data for time series analysis
  Future<List<FloodPrediction>> getHistoricalPredictions(LatLng location, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final requestData = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };
      
      final response = await http.post(
        Uri.parse('$apiUrl/historical_predictions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = (data['predictions'] as List)
            .map((item) => FloodPrediction.fromJson(item))
            .toList();
        return predictions;
      } else {
        throw Exception('Failed to get historical predictions: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Get model metadata and performance metrics
  Future<Map<String, dynamic>> getModelMetadata() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/model_info'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get model metadata: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}