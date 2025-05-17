import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_layer/shared_scaffold.dart';

import 'dart:io';
import 'dart:convert'; // For Base64 encoding
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/incident_report.dart' as incident_model;
import '../services/incident_service.dart' as incident_service;
import 'package:firebase_storage/firebase_storage.dart'; // For image storage
import 'package:cloud_firestore/cloud_firestore.dart';
 import 'package:image_picker/image_picker.dart';
import 'l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_map/flutter_map.dart';
import 'home.dart';

// Import the IncidentReport model (assuming it's in a separate file)
// If it's not, you can remove this import since you've provided the model class
// import '../models/incident_report.dart';

class ReportIncidentPage extends StatefulWidget {

  final CheckPoint? checkpoint;  // Add this field to hold the passed checkpoint

  
  const ReportIncidentPage({Key? key, this.checkpoint}) : super(key: key);
  

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  String _location = '';
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  String? _selectedIncidentType;
  final List<String> _incidentTypes = ['Flood', 'Fire', 'Earthquake', 'Landslide', 'Storm', 'Other'];
  String? _otherIncidentType;
  double _latitude = 0.0;
  double _longitude = 0.0;
  List<String> _base64Images = [];


  // Map to convert string incident type to enum
  final Map<String, IncidentType> _incidentTypeMap = {
    'Flood': IncidentType.flood,
    'Fire': IncidentType.fire,
    'Earthquake': IncidentType.earthquake,
    'Landslide': IncidentType.landslide,
    'Storm': IncidentType.storm,
    'Other': IncidentType.other,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Add this function to your ReportIncidentPage class
Future<void> _showSuccessModal(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.checkpoint != null 
                  ? 'Checkpoint submitted successfully!'
                  : 'Report submitted successfully!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Thank you for your contribution.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


Future<void> _pickImage(ImageSource source, AppLocalizations localizations) async {
  try {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50, // Reduced quality to keep Base64 strings smaller
    );
    
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      
      // Convert to Base64
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      setState(() {
        _images.add(imageFile);
        _base64Images.add(base64String); // Add to the list
      });
      
      print("${localizations.riImageAddedTotal}: ${_images.length}");
    }
  } catch (e) {
    print('Error picking and encoding image: $e');
    _showError('${localizations.riImagePickFailed}: ${e.toString()}');
  }
}

  String _getMonthAbbreviation(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }

  Future<void> _takePhoto(AppLocalizations localizations) async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(camera: firstCamera),
        ),
      );

      if (result != null && result is File) {
        // Convert to Base64 if needed
        final bytes = await result.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
        _images.add(result);
        _base64Images.add(base64String); // Add to the list
        });
      }
    } catch (e) {
      _showError('${localizations.riCameraError}: ${e.toString()}');
    }
  }

  Future<void> _getCurrentLocation(AppLocalizations localizations) async {
    try {
      setState(() => _isGettingLocation = true);
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError(localizations.riLocationDenied);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showError(localizations.riLocationPermDenied);
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _location = '${place.street}, ${place.subLocality}, ${place.locality}';
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
      _showError('${localizations.riGetLocationFailed}: ${e.toString()}');
    }
  }

  

  Future<void> _submitReport(AppLocalizations localizations) async {


      // Get the checkpoint passed from the previous page
      CheckPoint? checkpoint = widget.checkpoint;

      print("Submit function called"); // Add this line


  if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
    print("Validation failed: empty title or description");
    _showError(localizations.riFillAllFieldsMsg);
    return;
  }

  if (_location.isEmpty) {
    print("Validation failed: empty location");
    _showError(localizations.riGetCurrentLocation);
    return;
  }

  if (_selectedIncidentType == null) {
    print("Validation failed: no incident type selected");
    _showError(localizations.riSelectIncidentTypeMsg);
    return;
  }

  if (_selectedIncidentType == 'Other' && (_otherIncidentType == null || _otherIncidentType!.isEmpty)) {
    print("Validation failed: 'Other' selected but not specified");
    _showError(localizations.riSpecifyIncidentTypeMsg);
    return;
  }

  if (_images.isEmpty) {
    print("Validation failed: no images uploaded");
    _showError(localizations.riUploadMin1ImageMsg);
    return;
  }

  print("All validations passed, proceeding to submit");

    setState(() => _isSubmitting = true);
try {
  print("Starting form submission process...");
  
  // Skip Firebase Storage upload
  String? imageUrl = null; // We won't use this
  
  print("Using Base64 encoded image data...");
  
  final now = DateTime.now();
  final dateStr = '${_getMonthAbbreviation(now.month)} ${now.day}, ${now.year}';
  
  // Determine incident type
  print("Selected incident type: $_selectedIncidentType");
  IncidentType incidentType = _incidentTypeMap[_selectedIncidentType]!;
  
  print("Creating incident report object...");
  // Create IncidentReport object
  final newIncident = IncidentReport(
    title: _titleController.text,
    location: _location,
    date: dateStr,
    type: incidentType,
    description: _descriptionController.text,
    verified: false,
    imageUrl: null, // Set to null since we're not using Storage
    imageBase64List: _base64Images.isNotEmpty ? _base64Images : null, // Use the list
    timestamp: Timestamp.now(),
    latitude: _latitude,
    longitude: _longitude,
    verificationCount: 0,
  );
  
  print("Incident object created with Base64 image, preparing to save to Firestore...");
  
  // Test printing some info (not the entire Base64 as it would be too large)
  print("Base64 image length: ${_base64Images?.length ?? 0} chars");
  
  // Add to Firestore
  print("Adding to Firestore collection 'incidents'...");
  await FirebaseFirestore.instance.collection('incidents').add(newIncident.toMap());
  
  print("Successfully saved to Firestore.");
  
  // Clear form after successful submission
  _titleController.clear();
  _descriptionController.clear();
  setState(() {
    _images.clear();
    _location = '';
    _selectedIncidentType = null;
    _otherIncidentType = null;
    _base64Images = [];
  });

  _showSuccess(localizations.riReportSubmittedSuccess);
} catch (e) {
  print("ERROR in submission process: ${e.toString()}");
  print("Stack trace: ${StackTrace.current}");
  _showError('Failed to submit report: ${e.toString()}');
} finally {
  setState(() => _isSubmitting = false);
}
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showImagePreview(int index, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(_images[index]),
            TextButton(
              onPressed: () {
            setState(() {
              _base64Images.removeAt(index); // Remove the corresponding Base64 string
              _images.removeAt(index);
            });
              },
              child: Text(localizations.remove, style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markCheckpointAsReported(CheckPoint checkpoint) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Mark the checkpoint as reported in SharedPreferences
  await prefs.setBool('checkpoint_${checkpoint.id}_reported', true);
}


  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    final Map<String, String> _incidentTypeLocalizations = {
      'Flood': localizations.riFlood,
      'Fire': localizations.hmTypeFire,
      'Earthquake': localizations.riEarthquake,
      'Landslide': localizations.riLandslide,
      'Storm': localizations.riStorm,
      'Other': localizations.riOther,
    };

    return SharedScaffold(
      currentIndex: 2,
      appBar: AppBar(
        title: Text(
          localizations.riBarTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Type Selection
            Text(
              '${localizations.riIncidentType}*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _incidentTypes.map((type) {
                return ChoiceChip(
                  label: Text(_incidentTypeLocalizations[type]!),
                  selected: _selectedIncidentType == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedIncidentType = selected ? type : null;
                      if (type != 'Other') _otherIncidentType = null;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedIncidentType == 'Other')
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: TextField(
                  onChanged: (value) => _otherIncidentType = value,
                  decoration: InputDecoration(
                    hintText: localizations.riSpecifyIncidentTypeMsg,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Location Section
            Text(
              '${localizations.riCurrentLocation}*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
              onPressed: _isGettingLocation ? null : () => _getCurrentLocation(localizations),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                    child: _isGettingLocation
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(localizations.riGetCurrentLocation),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                    _isGettingLocation
                      ? '${localizations.riGetLocationLoading}...'
                      : (_location.isEmpty ? '${localizations.riNoLocation}...' : _location),
                    style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ],
                ),
                const SizedBox(height: 20),

            // Title Section
            Text(
              '${localizations.riIncidentTitle}*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: localizations.riIncidentTitlePrompt,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Description Section
            Text(
              '${localizations.riIncidentDescription}*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: localizations.riIncidentDescriptionPrompt,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Image Upload Section
            Text(
              '${localizations.riUploadEvidence}*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _showImagePreview(index, localizations),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _images[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _takePhoto(localizations),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt, size: 20),
                      const SizedBox(width: 8),
                      Text(localizations.riTakePhoto),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery, localizations),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library, size: 20),
                      const SizedBox(width: 8),
                      Text(localizations.riFromGallery),
                      // Text('Checkpoint: ${widget.checkpoint?.name}'),
                      
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

          SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _isSubmitting
        ? null
        : () async {
            setState(() {
              _isSubmitting = true;
            });

            try {
              // If it is a checkpoint, then dont submit
              // Call your report submission function (for example, to Firebase)

              // After submitting, mark the checkpoint as reported
              if (widget.checkpoint != null) {
                await _markCheckpointAsReported(widget.checkpoint!);
              } else {
                await _submitReport(localizations);
              }

              // Show success modal before navigating back
              await _showSuccessModal(context);
              
              // Navigate back to the previous page
              Navigator.pop(context);  // Close the ReportIncidentPage
            } catch (e) {
              // Handle error (if submission failed)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
              setState(() {
                _isSubmitting = false;
              });
            }
          },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF5252),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    child: _isSubmitting
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Text(
            localizations.riSubmitReportBtnText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
  ),
),
            
          ],
        ),
      ),
    );
  }
}

// Camera Page for taking photos
class CameraPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraPage({super.key, required this.camera});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            if (!mounted) return;
            Navigator.pop(context, File(image.path));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localizations.riPhotoTakingErr}: ${e.toString()}')),
            );
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}