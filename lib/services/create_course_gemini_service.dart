import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authをインポート

class CreateCourseGeminiService {
  final GenerativeModel _model;

  CreateCourseGeminiService()
      : _model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

  Future<String> _getApiKey() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      IdTokenResult tokenResult = await user.getIdTokenResult();
      return tokenResult.token ?? '';
    } else {
      throw Exception('User not authenticated');
    }
  }

  Future<Map<String, dynamic>> initiateConversation(String initialPrompt) async {
    final String apiKey = await _getApiKey();
    final content = [Content.text('''
You are an AI assistant helping a user customize a learning course. The user is interested in creating a course for the following profession:

Profession: ${initialPrompt}

Begin by greeting the user and asking questions to understand their goals, experience level, and specific needs. Use the following guidelines:

- Ask open-ended questions to understand the user's objectives.
- Inquire about their current knowledge level.
- Find out any specific topics they want to focus on.
- After gathering enough information, summarize their needs and confirm before proceeding.

Do not mention that you are an AI model. Keep the conversation natural and user-focused.

Start the conversation when ready.
''')];

    final response = await _model.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to initiate conversation with Gemini');
    }

    return {
      'response': response.text!.trim(),
      // Removed 'conversationId' as it doesn't exist
    };
  }

  Future<String> sendMessage(String message) async {
    final String apiKey = await _getApiKey();
    final content = [Content.text(message)];

    final response = await _model.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to send message to Gemini');
    }

    return response.text!.trim();
  }
}