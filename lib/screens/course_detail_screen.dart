import 'package:flutter/material.dart';
import '../services/create_course_gemini_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String category;
  final String profession;

  CourseDetailScreen({required this.category, required this.profession});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CreateCourseGeminiService _geminiService = CreateCourseGeminiService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = [];
  String? _conversationId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  Future<void> _startConversation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String initialPrompt =
          'I am interested in creating a course for ${widget.profession} under ${widget.category}. I would like your assistance to customize this course based on my specific needs.';
      var result = await _geminiService.initiateConversation(initialPrompt);
      setState(() {
        _conversationId = result['conversationId'];
        _messages.add({'user': initialPrompt});
        _messages.add({'gemini': result['response']});
      });
    } catch (e) {
      // Handle error appropriately
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (_conversationId == null) return;
    setState(() {
      _messages.add({'user': message});
      _isLoading = true;
    });
    try {
      String response =
          await _geminiService.sendMessage(_conversationId!, message);
      setState(() {
        _messages.add({'gemini': response});
      });
    } catch (e) {
      // Handle error appropriately
      print(e);
      setState(() {
        _messages.add({'gemini': 'Sorry, there was an error processing your request.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message.containsKey('user');
    return Container(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Text(
          isUser ? message['user']! : message['gemini']!,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Course Details'),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessage(_messages[index]);
                      },
                    ),
            ),
            Divider(height: 1),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration:
                          InputDecoration.collapsed(hintText: 'Send a message'),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _sendMessage(value.trim());
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      String message = _controller.text.trim();
                      if (message.isNotEmpty) {
                        _sendMessage(message);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}