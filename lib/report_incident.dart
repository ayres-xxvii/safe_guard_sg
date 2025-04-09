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

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({Key? key}) : super(key: key);

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
  final List<String> _incidentTypes = ['Fire', 'Flood', 'Accident', 'Crime', 'Others'];
  String? _otherIncidentType;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      _showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
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
        setState(() {
          _images.add(result);
        });
      }
    } catch (e) {
      _showError('Camera error: ${e.toString()}');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isGettingLocation = true);
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
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
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
      _showError('Failed to get location: ${e.toString()}');
    }
  }

  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showError('Please fill out all required fields');
      return;
    }

    if (_location.isEmpty) {
      _showError('Please get your current location');
      return;
    }

    if (_selectedIncidentType == null) {
      _showError('Please select an incident type');
      return;
    }

    if (_selectedIncidentType == 'Others' && (_otherIncidentType == null || _otherIncidentType!.isEmpty)) {
      _showError('Please specify the incident type');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload images to Firebase Storage and get URLs
      List<String> imageUrls = [];
      for (var image in _images) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('incident_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Create incident document in Firestore
      await FirebaseFirestore.instance.collection('incidents').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _location,
        'type': _selectedIncidentType == 'Others' ? _otherIncidentType : _selectedIncidentType,
        'images': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
        'verified': false,
      });

      // Clear form after successful submission
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _images.clear();
        _location = '';
        _selectedIncidentType = null;
        _otherIncidentType = null;
      });

      _showSuccess('Incident reported successfully!');
    } catch (e) {
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

  void _showImagePreview(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(_images[index]),
            TextButton(
              onPressed: () {
                setState(() => _images.removeAt(index));
                Navigator.pop(context);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentIndex: 2,
      appBar: AppBar(
        title: const Text(
          "Report Incidents",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Type Selection
            const Text(
              'Incident Type*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _incidentTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _selectedIncidentType == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedIncidentType = selected ? type : null;
                      if (type != 'Others') _otherIncidentType = null;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedIncidentType == 'Others')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  onChanged: (value) => _otherIncidentType = value,
                  decoration: const InputDecoration(
                    hintText: 'Please specify the incident type',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Location Section
            const Text(
              'Current Location*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
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
                      : const Text('Get Current Location'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                    _isGettingLocation
                      ? 'Getting location...'
                      : (_location.isEmpty ? 'No location found...' : _location),
                    style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ],
                ),
                const SizedBox(height: 20),

            // Title Section
            const Text(
              'Incident Title*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Brief title of the incident',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Description Section
            const Text(
              'Incident Description*',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Detailed description of what happened',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Image Upload Section
            const Text(
              'Upload Evidence (Images)*',
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
                        onTap: () => _showImagePreview(index),
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
                  onPressed: () => _takePhoto(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Take Photo'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library, size: 20),
                      SizedBox(width: 8),
                      Text('From Gallery'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
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
                    : const Text(
                        'SUBMIT REPORT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                '*False reports may result in penalties',
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
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
              SnackBar(content: Text('Error taking photo: ${e.toString()}')),
            );
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}






// import 'dart:io';
// import 'dart:convert'; // For Base64 encoding
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart'; 
// import '../models/incident_report.dart';
// import '../services/incident_service.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // For image storage
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import 'shared_layer/shared_scaffold.dart';


// class ReportIncidentPage extends StatefulWidget {
//   const ReportIncidentPage({Key? key}) : super(key: key);

//   @override
//   State<ReportIncidentPage> createState() => _ReportIncidentPageState();
// }

// class _ReportIncidentPageState extends State<ReportIncidentPage> {
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   String? _base64Image;
//   final _picker = ImagePicker();
//   final IncidentService _incidentService = IncidentService();
  
//   File? _image;
//   String _location = '';
//   bool _isSubmitting = false;

//   int _currentIndex = 2; // Since this is the Report tab

//   // Method to handle BottomNavigationBar tap
//   void _onItemTapped(int index) {
//     if (index == _currentIndex) return;
    
//     setState(() {
//       _currentIndex = index;
//     });

//     switch (index) {
//       case 0:
//         Navigator.pushReplacementNamed(context, '/home');
//         break;
//       case 1:
//         Navigator.pushReplacementNamed(context, '/heatmap');
//         break;
//       case 2:
//         // Already on report page
//         break;
//       case 3:
//         Navigator.pushReplacementNamed(context, '/settings');
//         break;
//     }
//   }

//   // Function to pick image and upload it to Firebase Storage


// Future<void> _pickImage(ImageSource source) async {
//   try {
//     final pickedFile = await _picker.pickImage(
//       source: source,
//       // Consider adding compression to reduce file size
//       imageQuality: 70, 
//     );
    
//     if (pickedFile != null) {
//       final File imageFile = File(pickedFile.path);
      
//       // Convert to Base64
//       final bytes = await imageFile.readAsBytes();
//       final base64String = base64Encode(bytes);
      
//       setState(() {
//         _image = imageFile;
//         _base64Image = base64String;
//       });
      
//       print("Image converted to Base64 successfully");
//     }
//   } catch (e) {
//     print('Error picking and encoding image: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to process image: $e')),
//     );
//   }
// }


  

//   // Submit the incident report to Firestore
// Future<void> _submitReport() async {
//   if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Please fill out all required fields')),
//     );
//     return;
//   }

//   if (_location.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Please get your current location')),
//     );
//     return;
//   }

//   setState(() {
//     _isSubmitting = true;
//   });

//   try {
//     final now = DateTime.now();
//     final dateStr = '${_getMonthAbbreviation(now.month)} ${now.day}, ${now.year}';
    
//     // Create incident report with Base64 image instead of URL
//     final newIncident = IncidentReport(
//       title: _titleController.text,
//       location: _location,
//       date: dateStr,
//       type: IncidentType.flood, 
//       description: _descriptionController.text,
//       verified: false,
//       imageUrl: null, // Not using this field anymore
//       imageBase64: _base64Image, // Add this field to your IncidentReport model
//       timestamp: Timestamp.now()
//     );
    
//     // Submit to Firestore
// Stream<List<IncidentReport>> getIncidents() {
//   return FirebaseFirestore.instance
//       .collection('incidents')  // Ensure this is the correct collection name in Firestore
//       .orderBy('timestamp', descending: true)
//       .snapshots()
//       .map((snapshot) => snapshot.docs
//           .map((doc) => IncidentReport.fromFirestore(doc))  // Ensure you are correctly mapping Firestore data to IncidentReport
//           .toList());
// }


//   print("Submitting incident with Base64 data: ${_base64Image != null ? 'Present (${_base64Image!.length} chars)' : 'Missing'}");
//   String docId = await _incidentService.addIncident(newIncident);
//   print("Document added with ID: $docId");

//     // Clear form
//     _titleController.clear();
//     _descriptionController.clear();
//     setState(() {
//       _image = null;
//       _base64Image = null;
//       _location = '';
//     });
    
//   } catch (e) {
//     print("Error submitting incident: $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error submitting report: ${e.toString()}')),
//     );
//   } finally {
//     setState(() {
//       _isSubmitting = false;
//     });
//   }
// }
//   // Get current location method
//   Future<void> _getCurrentLocation() async {
//     try {
//       // Request location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Location permissions are denied')),
//           );
//           return;
//         }
//       }
      
//       if (permission == LocationPermission.deniedForever) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Location permissions are permanently denied, we cannot request permissions.'),
//           ),
//         );
//         return;
//       }
      
//       // Show loading indicator
//       setState(() {
//         _location = 'Getting location...';
//       });
      
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       // Get address from coordinates using geocoding
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude, position.longitude);

//       // Extract address from the placemarks
//       Placemark place = placemarks[0];
//       setState(() {
//         _location = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
//       });
//     } catch (e) {
//       setState(() {
//         _location = 'Unable to fetch location';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to get location: $e')),
//       );
//     }
//   }

//   // Helper method to get month abbreviation (copied from RecentIncidentsPage)
//   String _getMonthAbbreviation(int month) {
//     switch (month) {
//       case 1: return 'Jan';
//       case 2: return 'Feb';
//       case 3: return 'Mar';
//       case 4: return 'Apr';
//       case 5: return 'May';
//       case 6: return 'Jun';
//       case 7: return 'Jul';
//       case 8: return 'Aug';
//       case 9: return 'Sep';
//       case 10: return 'Oct';
//       case 11: return 'Nov';
//       case 12: return 'Dec';
//       default: return '';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SharedScaffold(
//       currentIndex: 2,
//       appBar: AppBar(
//         title: const Text(
//           "Report Incidents",
//           style: TextStyle(
//                 fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Current Location',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               Row(
//                 children: [
//                   ElevatedButton(
//                     onPressed: _getCurrentLocation,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey[300],
//                       padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                       textStyle: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       foregroundColor: Colors.black,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                     child: const Text('Get Current Location'),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Text(
//                       _location.isEmpty ? 'No location available' : _location,
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),

//               const Text(
//                 'Incident Title',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               TextField(
//                 controller: _titleController,
//                 decoration: const InputDecoration(
//                   hintText: 'Enter incident title',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               const Text(
//                 'Incident Description',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               TextField(
//                 controller: _descriptionController,
//                 maxLines: 5,
//                 decoration: const InputDecoration(
//                   hintText: 'Enter incident description',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               const Text(
//                 'Upload Evidence (Images)',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               GestureDetector(
//                 onTap: () {
//                   showModalBottomSheet(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return Wrap(
//                         children: [
//                           ListTile(
//                             leading: const Icon(Icons.camera_alt),
//                             title: const Text('Take a Photo'),
//                             onTap: () {
//                               Navigator.pop(context);
//                               _pickImage(ImageSource.camera);
//                             },
//                           ),
//                           ListTile(
//                             leading: const Icon(Icons.photo),
//                             title: const Text('Choose from Gallery'),
//                             onTap: () {
//                               Navigator.pop(context);
//                               _pickImage(ImageSource.gallery);
//                             },
//                           ),
//                         ],
//                       );
//                     },
//                   );
//                 },
//                 child: _image == null
//                     ? Container(
//                         height: 200,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[200],
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: const Center(
//                           child: Icon(
//                             Icons.camera_alt,
//                             size: 50,
//                             color: Colors.black,
//                           ),
//                         ),
//                       )
//                     : ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: Image.file(
//                           _image!,
//                           fit: BoxFit.cover,
//                           height: 200,
//                           width: double.infinity,
//                         ),
//                       ),
//               ),
//               const SizedBox(height: 20),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   ElevatedButton(
//                     onPressed: _isSubmitting ? null : _submitReport,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF73D3D0),
//                       padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
//                       textStyle: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       foregroundColor: Colors.black,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                     child: _isSubmitting 
//                         ? const CircularProgressIndicator(color: Colors.black)
//                         : const Text('Submit Report'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//       // bottomNavigationBar: BottomNavigationBar(
//       //   currentIndex: 2,
//       //   onTap: _onItemTapped,
//       //   type: BottomNavigationBarType.fixed,
//       //   backgroundColor: const Color(0xFF73D3D0),
//       //   selectedItemColor: Colors.black,
//       //   unselectedItemColor: Colors.white,
//       //   items: const [
//       //     BottomNavigationBarItem(
//       //       icon: Icon(Icons.home),
//       //       label: 'Home',
//       //     ),
//       //     BottomNavigationBarItem(
//       //       icon: Icon(Icons.local_fire_department),
//       //       label: 'Heat Map',
//       //     ),
//       //     BottomNavigationBarItem(
//       //       icon: Icon(Icons.report_problem),
//       //       label: 'Report Incident',
//       //     ),
//       //     BottomNavigationBarItem(
//       //       icon: Icon(Icons.settings),
//       //       label: 'Settings',
//       //     ),
//       //   ],
//       // ),
//     );
//   }
// }