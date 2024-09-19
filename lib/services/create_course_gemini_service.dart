import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateCourseGeminiService {
  final String _apiEndpoint = 'https://api.example.com/gemini-1.5-flash'; // 実際のエンドポイントに置き換えてください
  final String _apiKey = 'YOUR_API_KEY'; // APIキーを設定

  Future<String> generateCourseData(String title, String description, String model) async {
    final response = await http.post(
      Uri.parse(_apiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': model,
        'prompt': 'Create a course with title "$title" and description "$description". Include several cards with questions, options, correct answers, and explanations.',
        'max_tokens': 1500,
      }),
    );

    if (response.statusCode == 200) {
      // レスポンスをパースしてコースデータを抽出
      var data = jsonDecode(response.body);
      return data['choices'][0]['text']; // Ensure this is a String
    } else {
      throw Exception('Failed to generate course data');
    }
  }
}