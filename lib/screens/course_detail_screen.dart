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
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUser ? message['user']! : message['gemini']!,
                style: TextStyle(color: isUser ? Colors.white : Colors.black87),
              ),
            ),
          ),
          SizedBox(width: 8),
          if (isUser) _buildAvatar(isUser: true),
        ],
      ),
    );
  }

  Widget _buildAvatar({bool isUser = false}) {
    return CircleAvatar(
      backgroundColor: isUser ? Colors.blue[100] : Colors.grey[300],
      child: Icon(
        isUser ? Icons.person : Icons.android,
        color: isUser ? Colors.blue : Colors.grey[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSubmit,
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => _handleSubmit(_controller.text),
            child: Icon(Icons.send),
            mini: true,
          ),
        ],
      ),
    );
  }

  void _handleSubmit(String value) {
    if (value.trim().isNotEmpty) {
      _sendMessage(value.trim());
      _controller.clear();
    }
  }

  // ... existing methods ...
}