import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authをインポート

class CreateCourseGeminiService {
  final String _apiEndpoint = 'https://api.example.com/gemini-1.5-flash'; // Replace with actual endpoint

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
    final String apiKey = await _getApiKey(); // APIキーを取得
    final response = await http.post(
      Uri.parse(_apiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gemini-1.5-flash',
        'prompt': initialPrompt,
        'max_tokens': 1500,
        'temperature': 0.7,
        'n': 1,
        'stop': null,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return {
        'response': data['choices'][0]['text'],
        'conversationId': data['conversation_id'], // Assuming the API returns a conversation ID
      };
    } else {
      throw Exception('Failed to initiate conversation with Gemini');
    }
  }

  Future<String> sendMessage(String conversationId, String message) async {
    final String apiKey = await _getApiKey(); // APIキーを取得
    final response = await http.post(
      Uri.parse('$_apiEndpoint/conversations/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'message': message,
        'max_tokens': 1500,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['choices'][0]['text'];
    } else {
      throw Exception('Failed to send message to Gemini');
    }
  }
}