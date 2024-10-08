import 'package:flutter/material.dart';
import '../services/create_course_gemini_service.dart';
import '../services/medlm_service.dart';
import 'course_list_screen.dart'; // CourseListScreenをインポート
import '../generated/app_localizations.dart'; // ローカライズをインポート

class CourseDetailScreen extends StatefulWidget {
  final String category;
  final String profession;
  final String language; // 言語を追加

  CourseDetailScreen({required this.category, required this.profession, required this.language});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CreateCourseGeminiService _geminiService = CreateCourseGeminiService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  int _userResponseCount = 0;
  List<String> _userResponses = [];
  final MedlmService _medlmService = MedlmService();

  bool _isCourseCreated = false;

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
          'I am interested in creating a course for ${widget.profession} under the category of ${widget.category}. I would like your assistance to customize this course based on my specific needs.';
      var result = await _geminiService.initiateConversation(initialPrompt, widget.language);
      setState(() {
        _messages.add({'gemini': result['response']});
      });
      await _generateAndAddSuggestedResponses(result['response']);
    } catch (e) {
      print(e);
      setState(() {
        _messages.add({'gemini': 'Sorry, there was an error starting the conversation.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (_isCourseCreated) return;

    setState(() {
      _messages.add({'user': message});
      _isLoading = true;
      _userResponseCount++;
      _userResponses.add(message);
    });
    try {
      if (_userResponseCount >= 2) {
        await _createCustomCourse();
        return;
      }

      String response = await _geminiService.sendMessage(message, widget.language);
      setState(() {
        _messages.add({'gemini': response});
      });
      await _generateAndAddSuggestedResponses(response);
    } catch (e) {
      print(e);
      setState(() {
        _messages.add({
          'gemini': 'Sorry, there was an error processing your request.'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createCustomCourse() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _medlmService.createCourse(_userResponses, widget.language);
      setState(() {
        _isCourseCreated = true;
        _messages.add({
          'gemini': AppLocalizations.of(context)!.courseCreatedMessage // ローカライズされたメッセージ
        });
        _messages.add({
          'navigateButton': AppLocalizations.of(context)!.viewCourseListButton // ローカライズされたボタンテキスト
        });
      });
    } catch (e) {
      print('Error creating custom course: $e');
      setState(() {
        _messages.add({
          'gemini': 'Sorry, there was an error creating your custom course.'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndAddSuggestedResponses(String aiMessage) async {
    try {
      List<String> suggestions = await _geminiService.generateSuggestedResponses(aiMessage, widget.language);
      setState(() {
        _messages.add({'suggestions': suggestions});
      });
    } catch (e) {
      print('Failed to generate suggested responses: $e');
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    if (message.containsKey('user')) {
      return _buildUserMessage(message['user']);
    } else if (message.containsKey('gemini')) {
      return _buildGeminiMessage(message['gemini']);
    } else if (message.containsKey('suggestions')) {
      return _buildSuggestedResponses(message['suggestions']);
    } else if (message.containsKey('navigateButton')) {
      return _buildNavigateButton(message['navigateButton']);
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildUserMessage(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          _buildAvatar(isUser: true),
        ],
      ),
    );
  }

  Widget _buildGeminiMessage(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSuggestedResponses(List<String> suggestions) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () => _handleSubmit(suggestion),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: Text(
                suggestion,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.left,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigateButton(String buttonText) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseListScreen()),
          );
        },
        child: Text(buttonText),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAvatar({bool isUser = false}) {
    return CircleAvatar(
      backgroundColor: isUser ? Colors.blue[100] : Colors.grey[300],
      radius: 20,
      child: Icon(
        isUser ? Icons.person : Icons.person_search,
        color: isUser ? Colors.blue : Colors.grey[700],
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customize Your Course'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.only(top: 16, bottom: 80),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessage(_messages[index]);
                      },
                    ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.message, color: Theme.of(context).colorScheme.primary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSubmit,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSubmit(_controller.text),
            ),
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
}