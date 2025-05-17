import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Service for handling API calls to OpenRouter
class OpenRouterService {
  final String apiKey;

  OpenRouterService({
    required this.apiKey,
  });

  Future<String> generateNewsArticle() async {
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-coder',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI that generates news articles based on recent incident data.'
            },
            {
              'role': 'user',
              'content': 'Generate a news article about recently reported incidents. Include analysis of latest trends and potential upcoming incidents. Use a formal journalistic style suitable for a news publication. Keep it under 500 words.'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data['choices'][0]['message']['content'];
      } else {
        return 'Error: ${data['error']['message'] ?? 'Failed to generate article'}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}

// NewsPopup widget that appears as an overlay
class NewsPopup extends StatefulWidget {
  final Function() onClose;

  const NewsPopup({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<NewsPopup> createState() => _NewsPopupState();
}

class _NewsPopupState extends State<NewsPopup> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _article = '';
  late AnimationController _controller;
  late Animation<double> _animation;
  final OpenRouterService _service = OpenRouterService(
    apiKey: dotenv.env["OPENROUTER_API_KEY"], // Replace with your actual API key
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateArticle() async {
    setState(() {
      _isLoading = true;
      _article = '';
    });

    final result = await _service.generateNewsArticle();
    
    setState(() {
      _article = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.1,
          vertical: MediaQuery.of(context).size.height * 0.1,
        ),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Incident News Article',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.reverse().then((_) {
                        widget.onClose();
                      });
                    },
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating article...'),
                        ],
                      ),
                    )
                  : _article.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Generate an article about recent incidents and trends'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _generateArticle,
                              child: const Text('Generate Article'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_article),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: _generateArticle,
                                  child: const Text('Regenerate'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Function to show the news popup
void showNewsPopup(BuildContext context) {
  OverlayState? overlayState = Overlay.of(context);
  OverlayEntry? overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Semi-transparent background
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              overlayEntry?.remove();
            },
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        // Centered popup
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: NewsPopup(
              onClose: () {
                overlayEntry?.remove();
              },
            ),
          ),
        ),
      ],
    ),
  );
  
  overlayState.insert(overlayEntry);
}