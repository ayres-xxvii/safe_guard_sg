import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Service for handling API calls to OpenRouter
class OpenRouterService {
  final String apiKey;
  // var incidents;

  OpenRouterService({
    required this.apiKey,
    // incidents = const [],
  });

  Future<String> generateNewsArticle() async {
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-r1:free',
          'messages': [
            {
              'role': 'user',
              'content': '''
                          You are analyzing recent incident reports (e.g. floods, fires) in Singapore submitted through a community reporting app. Based on the data provided, identify emerging trends such as repeated incidents in specific areas (e.g. "frequent flooding in Yishun and Jalan Kayu"). Summarize these trends in a short, informative report.
                            The report should:
                            - Highlight hotspots or clusters of incidents.
                            - Identify the type of incident most common in each area.
                            - Mention any unusual or noteworthy patterns.
                            - Provide actionable safety tips or precautions related to the trend (e.g. flood preparedness).
                            - Be clear, engaging, and easy to read (around 100–150 words, bullet points or short paragraphs).

                          Incidents: [Yishun - flood, Jalan Kayu - flood, Yishun - flood, Yishun - flood, Jalan Kayu - flood, Yishun - flood, Yishun - flood, Yishun - flood, Yishun - flood, Yishun - flood]
                          
                          The format of the response should be able to be directly used in a Text widget in Flutter.
                          Please consider including some emojis to make it more engaging.
                          Please only return the article, without any additional text or explanation or prompts.      
                          '''
            }
          ],
          'temperature': 0.7,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      print(data['choices'][0]['message']['content']);
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
    apiKey: dotenv.env["OPENROUTER_API_KEY"]!, // Replace with your actual API key
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
                          // Expanded(child: Markdown(data: _article)),
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