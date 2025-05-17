import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:safe_guard_sg/models/incident_report.dart';
import 'package:safe_guard_sg/services/open_router_service.dart';
import '../services/incident_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<String> _articleFuture;
  late OpenRouterService _openRouterService;

  @override
  void initState() {
    super.initState();
    // Initialize the service with API key from environment variables
    _openRouterService = OpenRouterService(
      apiKey: dotenv.env['OPENROUTER_API_KEY']!,
    );

    _articleFuture = _openRouterService.generateNewsArticle();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
      ),
      body: FutureBuilder<String>(
        future: _articleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading indicator while waiting for the article
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading news article...", 
                       style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            // Show error message if something went wrong
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading article: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else {
            // Show the article content as Markdown
            return Markdown(
                    data: snapshot.data ?? 'No content available',
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16),
                      h1: Theme.of(context).textTheme.headlineMedium,
                      h2: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
          }
        },
      ),
    );
  }
}


// // NewsPopup widget that appears as an overlay
// class NewsPopup extends StatefulWidget {
//   final Function() onClose;

//   const NewsPopup({
//     Key? key,
//     required this.onClose,
//   }) : super(key: key);

//   @override
//   State<NewsPopup> createState() => _NewsPopupState();
// }

// class _NewsPopupState extends State<NewsPopup> with SingleTickerProviderStateMixin {
//   bool _isLoading = false;
//   String _article = '';
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   final OpenRouterService _service = OpenRouterService(
//     apiKey: dotenv.env["OPENROUTER_API_KEY"]!, // Replace with your actual API key
//   );

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _animation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOut,
//     );
//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _generateArticle() async {
//     setState(() {
//       _isLoading = true;
//       _article = '';
//     });

//     final result = await _service.generateNewsArticle();
    
//     setState(() {
//       _article = result;
//       _isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: _animation,
//       child: Card(
//         margin: EdgeInsets.symmetric(
//           horizontal: MediaQuery.of(context).size.width * 0.1,
//           vertical: MediaQuery.of(context).size.height * 0.1,
//         ),
//         elevation: 10,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Container(
//           width: MediaQuery.of(context).size.width * 0.8,
//           height: MediaQuery.of(context).size.height * 0.7,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Incident News Article',
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () {
//                       _controller.reverse().then((_) {
//                         widget.onClose();
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               const Divider(),
//               Expanded(
//                 child: _isLoading
//                   ? const Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(),
//                           SizedBox(height: 16),
//                           Text('Generating article...'),
//                         ],
//                       ),
//                     )
//                   : _article.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text('Generate an article about recent incidents and trends'),
//                             const SizedBox(height: 16),
//                             ElevatedButton(
//                               onPressed: _generateArticle,
//                               child: const Text('Generate Article'),
//                             ),
//                           ],
//                         ),
//                       )
//                     : Column(
//                         children: [
//                           Expanded(
//                             child: SingleChildScrollView(
//                               child: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(_article),
//                               ),
//                             ),
//                           ),
//                           // Expanded(child: Markdown(data: _article)),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 ElevatedButton(
//                                   onPressed: _generateArticle,
//                                   child: const Text('Regenerate'),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Function to show the news popup
// void showNewsPopup(BuildContext context) {
  
//   OverlayState? overlayState = Overlay.of(context);
//   OverlayEntry? overlayEntry;
  
//   overlayEntry = OverlayEntry(
//     builder: (context) => Stack(
//       children: [
//         // Semi-transparent background
//         Positioned.fill(
//           child: GestureDetector(
//             onTap: () {
//               overlayEntry?.remove();
//             },
//             child: Container(
//               color: Colors.black.withOpacity(0.5),
//             ),
//           ),
//         ),
//         // Centered popup
//         Positioned.fill(
//           child: Material(
//             color: Colors.transparent,
//             child: NewsPopup(
//               onClose: () {
//                 overlayEntry?.remove();
//               },
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
  
//   overlayState.insert(overlayEntry);
// }