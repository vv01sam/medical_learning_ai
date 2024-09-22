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
      You are an AI assistant helping users customize their learning courses. The user wants to create a course for:
      
      Profession: ${initialPrompt}
      
      Greet the user warmly. Ask clear questions to understand their goals, experience, and needs. Keep the conversation natural and focused.
      
      Avoid lists, bullet points, and mentioning you are an AI. Keep interactions engaging and concise.
      
      Start the conversation.
    ''')];

    final response = await _model.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to initiate conversation with Gemini');
    }

    return {
      'response': response.text!.trim(),
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