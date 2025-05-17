import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Added for timer functionality
import 'dart:math' show sin; // Added for bobbing animation
import 'dart:convert'; // Added for base64 decoding
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for database access
import 'heatmap.dart';
import 'report_incident.dart';
import 'recent_incident.dart';
import 'languages.dart';
import 'incident_details.dart';
import 'shared_layer/shared_scaffold.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_report.dart'; // Add this import for the IncidentReport model
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
// Add this import at the top of your file
import '../services/notification_service.dart';


class ImageGalleryPage extends StatefulWidget {
  final List<String> images;
  final String title;

  const ImageGalleryPage({
    Key? key,
    required this.images,
    required this.title,
  }) : super(key: key);

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Main image viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.memory(
                    base64Decode(widget.images[index]),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, color: Colors.white60, size: 60),
                              SizedBox(height: 16),
                              Text(
                                'Image could not be loaded',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // Image counter indicator
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation arrows
          if (widget.images.length > 1)
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  GestureDetector(
                    onTap: _currentIndex > 0 
                        ? () {
                            _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Container(
                      width: 60,
                      color: Colors.transparent,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: _currentIndex > 0 ? Colors.white : Colors.transparent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  // Next button
                  GestureDetector(
                    onTap: _currentIndex < widget.images.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Container(
                      width: 60,
                      color: Colors.transparent,
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: _currentIndex < widget.images.length - 1 ? Colors.white : Colors.transparent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

