// lib/widgets/flood_dashboard.dart
import 'package:flutter/material.dart';
import '../models/flood_prediction.dart';

class FloodRiskDashboard extends StatelessWidget {
  final List<FloodPrediction> predictions;
  final Map<String, dynamic>? weatherData;
  final Map<String, dynamic>? modelMetadata;
  final bool isLoading;
  
  const FloodRiskDashboard({
    Key? key,
    required this.predictions,
    this.weatherData,
    this.modelMetadata,
    this.isLoading = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingDashboard();
    }
    
    if (predictions.isEmpty) {
      return const _EmptyDashboard();
    }
    
    // Calculate statistics
    final Map<FloodRiskLevel, int> riskCounts = _calculateRiskCounts(predictions);
    final double averageConfidence = _calculateAverageConfidence(predictions);
    final double riskScore = _calculateRiskScore(riskCounts);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(riskScore),
            const SizedBox(height: 16),
            _buildRiskDistribution(riskCounts),
            const SizedBox(height: 16),
            _buildWeatherData(),
            const SizedBox(height: 16),
            _buildModelInfo(averageConfidence),
            const SizedBox(height: 16),
            _buildActionItems(context, riskScore),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(double riskScore) {
    final Color scoreColor = _getRiskColor(riskScore);
    final String riskText = _getRiskText(riskScore);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Flood Risk Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scoreColor),
          ),
          child: Text(
            riskText,
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRiskDistribution(Map<FloodRiskLevel, int> riskCounts) {
    final int total = riskCounts.values.fold(0, (sum, count) => sum + count);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Risk Distribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRiskBar(
                FloodRiskLevel.high,
                riskCounts[FloodRiskLevel.high] ?? 0,
                total,
                Colors.red,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildRiskBar(
                FloodRiskLevel.medium,
                riskCounts[FloodRiskLevel.medium] ?? 0,
                total,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildRiskBar(
                FloodRiskLevel.low,
                riskCounts[FloodRiskLevel.low] ?? 0,
                total,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRiskLabel('High', Colors.red, riskCounts[FloodRiskLevel.high] ?? 0),
            _buildRiskLabel('Medium', Colors.orange, riskCounts[FloodRiskLevel.medium] ?? 0),
            _buildRiskLabel('Low', Colors.green, riskCounts[FloodRiskLevel.low] ?? 0),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRiskBar(FloodRiskLevel level, int count, int total, Color color) {
    final double percentage = total > 0 ? count / total : 0;
    
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight * percentage,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildRiskLabel(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildWeatherData() {
    // Default weather data if none provided
    final Map<String, dynamic> weather = weatherData ?? {
      'condition': 'Unknown',
      'temperature': 'N/A',
      'rainfall': 'N/A',
      'forecast': 'N/A',
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weather Conditions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWeatherItem(
              Icons.thermostat,
              'Temperature',
              weather['temperature'].toString(),
            ),
            _buildWeatherItem(
              Icons.water_drop,
              'Rainfall',
              weather['rainfall'].toString(),
            ),
            _buildWeatherItem(
              Icons.cloud,
              'Condition',
              weather['condition'].toString(),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildWeatherItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildModelInfo(double confidence) {
    final DateTime lastUpdated = predictions.isNotEmpty
        ? predictions.first.timestamp
        : DateTime.now();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Model Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoItem(
              'Confidence',
              '${(confidence * 100).toStringAsFixed(1)}%',
            ),
            _buildInfoItem(
              'Last Updated',
              '${lastUpdated.hour}:${lastUpdated.minute.toString().padLeft(2, '0')}',
            ),
            _buildInfoItem(
              'Areas Analyzed',
              predictions.length.toString(),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionItems(BuildContext context, double riskScore) {
    final List<Map<String, dynamic>> actions = _getActionItems(riskScore);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(action['text'] as String),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  // Helper methods
  Map<FloodRiskLevel, int> _calculateRiskCounts(List<FloodPrediction> predictions) {
    final Map<FloodRiskLevel, int> counts = {
      FloodRiskLevel.high: 0,
      FloodRiskLevel.medium: 0,
      FloodRiskLevel.low: 0,
    };
    
    for (final prediction in predictions) {
      counts[prediction.riskLevel] = (counts[prediction.riskLevel] ?? 0) + 1;
    }
    
    return counts;
  }
  
  double _calculateAverageConfidence(List<FloodPrediction> predictions) {
    if (predictions.isEmpty) return 0.0;
    
    final double total = predictions.fold(
      0.0,
      (sum, prediction) => sum + prediction.confidence,
    );
    
    return total / predictions.length;
  }
  
  double _calculateRiskScore(Map<FloodRiskLevel, int> riskCounts) {
    final int highCount = riskCounts[FloodRiskLevel.high] ?? 0;
    final int mediumCount = riskCounts[FloodRiskLevel.medium] ?? 0;
    final int lowCount = riskCounts[FloodRiskLevel.low] ?? 0;
    final int total = highCount + mediumCount + lowCount;
    
    if (total == 0) return 0.0;
    
    // Calculate weighted score (high: 3, medium: 2, low: 1)
    final double weightedScore = (highCount * 3 + mediumCount * 2 + lowCount) / total;
    
    // Normalize to 0-10 scale
    return (weightedScore / 3) * 10;
  }
  
  Color _getRiskColor(double score) {
    if (score >= 7) return Colors.red;
    if (score >= 4) return Colors.orange;
    return Colors.green;
  }
  
  String _getRiskText(double score) {
    if (score >= 7) return 'High Risk';
    if (score >= 4) return 'Medium Risk';
    return 'Low Risk';
  }
  
  List<Map<String, dynamic>> _getActionItems(double riskScore) {
    if (riskScore >= 7) {
      // High risk actions
      return [
        {
          'icon': Icons.warning,
          'color': Colors.red,
          'text': 'Avoid flood-prone areas and follow evacuation notices',
        },
        {
          'icon': Icons.home,
          'color': Colors.red,
          'text': 'Move valuables to higher levels and prepare for possible evacuation',
        },
        {
          'icon': Icons.notifications,
          'color': Colors.red,
          'text': 'Stay updated with emergency alerts and weather forecasts',
        },
      ];
    } else if (riskScore >= 4) {
      // Medium risk actions
      return [
        {
          'icon': Icons.warning,
          'color': Colors.orange,
          'text': 'Monitor weather updates and be prepared for changing conditions',
        },
        {
          'icon': Icons.home,
          'color': Colors.orange,
          'text': 'Check emergency supplies and have an evacuation plan ready',
        },
        {
          'icon': Icons.car_repair,
          'color': Colors.orange,
          'text': 'Avoid driving through potentially flooded areas',
        },
      ];
    } else {
      // Low risk actions
      return [
        {
          'icon': Icons.info,
          'color': Colors.green,
          'text': 'Stay informed of weather conditions in your area',
        },
        {
          'icon': Icons.home,
          'color': Colors.green,
          'text': 'Ensure your emergency kit is stocked and accessible',
        },
      ];
    }
  }
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();
  
  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading flood risk predictions...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 48,
                color: Colors.blue[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'No flood risk data available for this area',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Refresh Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}