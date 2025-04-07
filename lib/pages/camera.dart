import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<CameraPage> createState() => _TakePictureState();
}

class _TakePictureState extends State<CameraPage> {

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  
  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();

            if (!context.mounted) return;

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => DisplayPictureScreen(
                      // Pass the automatically generated path to
                      // the DisplayPictureScreen widget.
                      imagePath: image.path,
                    ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}


// A widget that displays the picture taken with a report form overlay
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  String? selectedCategory;
  TextEditingController otherController = TextEditingController();

  @override
  void dispose() {
    otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Report')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image - the captured photo
          Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
          ),
          
          // Semi-transparent overlay for better contrast
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          
          // Centered report form
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fire option
                  CheckboxListTile(
                    title: const Text('Fire'),
                    value: selectedCategory == 'Fire',
                    onChanged: (bool? value) {
                      setState(() {
                        selectedCategory = value! ? 'Fire' : null;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  // Flood option
                  CheckboxListTile(
                    title: const Text('Flood'),
                    value: selectedCategory == 'Flood',
                    onChanged: (bool? value) {
                      setState(() {
                        selectedCategory = value! ? 'Flood' : null;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  // Others option
                  CheckboxListTile(
                    title: const Text('Others'),
                    value: selectedCategory == 'Others',
                    onChanged: (bool? value) {
                      setState(() {
                        selectedCategory = value! ? 'Others' : null;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  // Text field for Others
                  if (selectedCategory == 'Others')
                    Padding(
                      padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
                      child: TextField(
                        controller: otherController,
                        decoration: const InputDecoration(
                          hintText: 'Type here',
                          hintStyle: TextStyle(fontStyle: FontStyle.italic),
                          isDense: true,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Warning text
                  Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prank reports will be fined',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Report button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: selectedCategory != null ? _submitReport : null,
                      child: const Text('Report'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitReport() {
    // Create the final category string
    final category = selectedCategory == 'Others' && otherController.text.isNotEmpty
        ? otherController.text
        : selectedCategory;
    
    // Here you would handle the report submission
    // For example, send to server, save locally, etc.
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reported as $category successfully')),
    );
    
    // Return to previous screen
    Navigator.pop(context);
  }
}