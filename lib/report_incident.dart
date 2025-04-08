import 'dart:io';
import 'dart:convert'; // For Base64 encoding
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/incident_report.dart';
import '../services/incident_service.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For image storage
import 'package:cloud_firestore/cloud_firestore.dart';
 import 'package:image_picker/image_picker.dart';


class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _base64Image;
  final _picker = ImagePicker();
  final IncidentService _incidentService = IncidentService();
  
  File? _image;
  String _location = '';
  bool _isSubmitting = false;

  int _currentIndex = 2; // Since this is the Report tab

  // Method to handle BottomNavigationBar tap
  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/heatmap');
        break;
      case 2:
        // Already on report page
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  // Function to pick image and upload it to Firebase Storage


Future<void> _pickImage(ImageSource source) async {
  try {
    final pickedFile = await _picker.pickImage(
      source: source,
      // Consider adding compression to reduce file size
      imageQuality: 70, 
    );
    
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      
      // Convert to Base64
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      setState(() {
        _image = imageFile;
        _base64Image = base64String;
      });
      
      print("Image converted to Base64 successfully");
    }
  } catch (e) {
    print('Error picking and encoding image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to process image: $e')),
    );
  }
}


  

  // Submit the incident report to Firestore
Future<void> _submitReport() async {
  if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill out all required fields')),
    );
    return;
  }

  if (_location.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please get your current location')),
    );
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  try {
    final now = DateTime.now();
    final dateStr = '${_getMonthAbbreviation(now.month)} ${now.day}, ${now.year}';
    
    // Create incident report with Base64 image instead of URL
    final newIncident = IncidentReport(
      title: _titleController.text,
      location: _location,
      date: dateStr,
      type: IncidentType.flood, 
      description: _descriptionController.text,
      verified: false,
      imageUrl: null, // Not using this field anymore
      imageBase64: _base64Image, // Add this field to your IncidentReport model
      timestamp: Timestamp.now()
    );
    
    // Submit to Firestore
Stream<List<IncidentReport>> getIncidents() {
  return FirebaseFirestore.instance
      .collection('incidents')  // Ensure this is the correct collection name in Firestore
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => IncidentReport.fromFirestore(doc))  // Ensure you are correctly mapping Firestore data to IncidentReport
          .toList());
}


  print("Submitting incident with Base64 data: ${_base64Image != null ? 'Present (${_base64Image!.length} chars)' : 'Missing'}");
  String docId = await _incidentService.addIncident(newIncident);
  print("Document added with ID: $docId");

    // Clear form
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _image = null;
      _base64Image = null;
      _location = '';
    });
    
  } catch (e) {
    print("Error submitting incident: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error submitting report: ${e.toString()}')),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}
  // Get current location method
  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied, we cannot request permissions.'),
          ),
        );
        return;
      }
      
      // Show loading indicator
      setState(() {
        _location = 'Getting location...';
      });
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates using geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);

      // Extract address from the placemarks
      Placemark place = placemarks[0];
      setState(() {
        _location = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
      });
    } catch (e) {
      setState(() {
        _location = 'Unable to fetch location';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  // Helper method to get month abbreviation (copied from RecentIncidentsPage)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Incident"),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black,
        ),
        backgroundColor: const Color(0xFF73D3D0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Get Current Location'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _location.isEmpty ? 'No location available' : _location,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Incident Title',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter incident title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Incident Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter incident description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Upload Evidence (Images)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take a Photo'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: _image == null
                    ? Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF73D3D0),
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('Submit Report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF73D3D0),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Heat Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Report Incident',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
