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
You are an AI assistant dedicated to helping users customize their learning courses. The user is looking to create a course for the following profession:

Profession: ${initialPrompt}

Start the conversation with a warm greeting. Engage the user by asking open-ended questions to understand their goals, experience level, and specific needs. Ensure the dialogue flows naturally based on the user's responses.

Please avoid using bullet points or structured lists. Do not mention that you are an AI model. Keep the interaction conversational, engaging, and focused on the user's input.

Begin the conversation whenever you are ready.
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
    final content = [Content.text('''
${message}

Please respond in a conversational manner, keeping your replies at a natural length suitable for a dialogue. Avoid overly long or overly brief responses.
    ''')];

    final response = await _model.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to send message to Gemini');
    }

    return response.text!.trim();
  }

  /// 新しく追加するメソッド
  Future<List<String>> generateSuggestedResponses(String aiQuestion) async {
    final String apiKey = await _getApiKey();
    final content = [Content.text('''
Provide three concise and relevant responses to the following question as potential answers a user might give. Do not include any explanations.

Question: "${aiQuestion}"
Responses:
1.
2.
3.
''')];

    final response = await _model.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to generate suggested responses');
    }

    // レスポンスを分割してリストに変換
    List<String> responses = response.text!
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), ''))
        .toList();

    return responses;
  }
}