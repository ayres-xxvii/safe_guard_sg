// lib/services/user_points_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserPointsService {
  static const String _pointsKey = 'user_points';
  
  // Get current points
  static Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }
  
  // Add points and return new total
  static Future<int> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPoints = prefs.getInt(_pointsKey) ?? 0;
    final newTotal = currentPoints + points;
    await prefs.setInt(_pointsKey, newTotal);
    return newTotal;
  }

  // Deduct points and return new total
  static Future<int> deductPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPoints = prefs.getInt(_pointsKey) ?? 0;
    
    // Check if user has enough points
    if (currentPoints < points) {
      throw Exception('Insufficient points');
    }
    
    final newTotal = currentPoints - points;
    await prefs.setInt(_pointsKey, newTotal);
    return newTotal;
  }
  
  // Set points to a specific value
  static Future<int> setPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, points);
    return points;
  }
  
  // Reset points to zero
  static Future<void> resetPoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, 0);
  }
}