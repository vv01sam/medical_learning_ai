import 'dart:async'; // Timerクラスを使用するために追加
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'dart:math';

// 必要なモデルをインポート
import '../models/card_model.dart' as card_model;

// カスタム例外クラス
class ContentGenerationException implements Exception {
  final String message;
  ContentGenerationException(this.message);
  @override
  String toString() => 'ContentGenerationException: $message';
}

// AIサービスのインターフェース
abstract class AIService {
  Future<String> generateContent(String userMessage);
  Future<String> generatePersonalizedQuestion(String deckId, String userInfo, String lastAnswer, String extractedTopic, List<String> previousQuestions, String language);
  Future<String> extractTopics(String userAnswer, String selectedInterests);
  Future<String> generateDetailedContent(String question, String correctAnswer, String explanation, String topic, String language);
  Future<List<String>> generateContentBatch(List<card_model.CardModel> cards, String topic, String language);
}

class GeminiService implements AIService {
  final GenerativeModel _model;
  final Map<String, String> _cache = {};
  final Queue<DateTime> _apiCallsMinute = Queue();
  final Queue<DateTime> _apiCallsHour = Queue();
  final int _maxCallsPerMinute = 60;
  final int _maxCallsPerHour = 1000;
  final int _batchSize = 10;

  // 定数
  static const int _maxAttempts = 3;
  static const int _minWordCount = 100;
  static const int _maxWordCount = 150;
  static const double _similarityThreshold = 0.5;

  // _minApiCallInterval を2秒から5秒に増加
  final Duration _minApiCallInterval = Duration(seconds: 5);

  // APIリクエスト数の監視と制限
  int _requestCount = 0;
  final int _maxRequestsPerMinute = 30; // クォータに応じて調整

  GeminiService() : _model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash') {
    // 1分ごとにリクエストカウントをリセット
    Timer.periodic(Duration(minutes: 1), (Timer t) {
      _requestCount = 0;
    });
  }

  Future<void> _enforceApiCallInterval() async {
    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCall);
    if (timeSinceLastCall < _minApiCallInterval) {
      await Future.delayed(_minApiCallInterval - timeSinceLastCall);
    }
    _lastApiCall = DateTime.now();
  }

  final Map<String, String> _contentCache = {};

  @override
  Future<String> generateContent(String userMessage) async {
    try {
      print('Generating content for message: $userMessage');
      final content = [Content.text(userMessage)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw ContentGenerationException('Failed to generate content');
      }

      print('Generated content: ${response.text!}');
      return response.text!;
    } catch (e) {
      print('Error generating content: $e');
      rethrow;
    }
  }

  @override
  Future<String> generatePersonalizedQuestion(
      String deckId,
      String userInterests,
      String lastAnswer,
      String extractedTopic,
      List<String> previousQuestions,
      String language) async {
    try {
      final prompt = _buildPersonalizedQuestionPrompt(userInterests, lastAnswer, previousQuestions, language);
      print('Generating personalized question with prompt: $prompt');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw ContentGenerationException('Failed to generate personalized question');
      }

      String generatedQuestion = response.text!;
      generatedQuestion = _ensureCorrectLanguage(generatedQuestion, language);

      print('Generated personalized question: $generatedQuestion');
      return generatedQuestion;
    } catch (e) {
      print('Error generating personalized question: $e');
      return _getDefaultQuestion(language, userInterests);
    }
  }

  String _buildPersonalizedQuestionPrompt(String userInterests, String lastAnswer, List<String> previousQuestions, String language) {
    return '''
You are an AI assistant aiming to discover the user's interests to provide personalized learning content.

Based on the following information:
- User Interests: $userInterests
- Last Answer: $lastAnswer
- Previous Questions: ${previousQuestions.join(", ")}
- Language: $language

Guidelines:
1. Ask open-ended questions that help reveal the topics the user is interested in.
2. Encourage the user to share specific details about their interests.
3. Design questions that draw out the user's passions and curiosities.
4. Avoid repeating previous questions or topics.
5. Keep the question engaging and relevant to the user's potential interests.
6. The question must be in the specified language ($language).

Please provide only the question, without any additional explanations.
''';
  }

  String _ensureCorrectLanguage(String text, String targetLanguage) {
    if (targetLanguage == 'ja' && !_isJapanese(text)) {
      return '申し訳ありませんが、日本語で質問を生成できませんでした。代わりに一般的な質問をします：最近、何か新しいことを学びましたか？それについて教えてください。';
    } else if (targetLanguage != 'ja' && _isJapanese(text)) {
      return "I apologize, but I couldn't generate a question in the target language. Instead, here's a general question: Have you learned something new recently? Please tell me about it.";
    }
    return text;
  }

  bool _isJapanese(String text) {
    // 簡易的な日本判定（ひらがな、カタカナ、漢字のいずれかを含む）
    return RegExp(r'[\u3040-\u309F]|[\u30A0-\u30FF]|[\u4E00-\u9FAF]').hasMatch(text);
  }

  String _getDefaultQuestion(String language, String userInterests) {
    if (userInterests.isNotEmpty) {
      if (language == 'ja') {
        return '$userInterestsについて、あなたの経験や意見を教えてください。';
      } else {
        return 'Can you tell me about your experience or opinion on $userInterests?';
      }
    } else {
      if (language == 'ja') {
        return '最近、何か新しいことを学びましたか？それについて教えてください。';
      } else {
        return 'Have you learned something new recently? Please tell me about it.';
      }
    }
  }

  @override
  Future<String> extractTopics(String userAnswer, String selectedInterests) async {
    try {
      print('DEBUG: Extracting topics from userAnswer: $userAnswer with selectedInterests: $selectedInterests');
      final prompt = _buildTopicExtractionPrompt(userAnswer, selectedInterests);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw ContentGenerationException('Failed to extract topics');
      }

      print('DEBUG: Extracted topics: ${response.text}');
      return response.text!;
    } catch (e) {
      print('Error extracting topics: $e');
      rethrow;
    }
  }

  String _buildTopicExtractionPrompt(String userAnswer, String selectedInterests) {
    return '''
Based on the following user answer and their selected interests, extract a single main topic that best represents their specific interest within the selected categories:

User Answer: "$userAnswer"
Selected Interests: $selectedInterests

Please provide a concise, specific topic that combines elements from both the user's answer and their selected interests.
''';
  }

  @override
  Future<String> generateDetailedContent(
      String question,
      String correctAnswer,
      String explanation,
      String topic,
      String language) async {
    String cacheKey = '$question:$correctAnswer:$explanation:$topic:$language';
    if (_contentCache.containsKey(cacheKey)) {
      print('DEBUG: Returning cached content.');
      return _contentCache[cacheKey]!;
    }

    int retryCount = 0;
    const int maxRetries = 5;
    const Duration retryDelay = Duration(seconds: 10);

    while (retryCount < maxRetries) {
      try {
        if (_requestCount >= _maxRequestsPerMinute) {
          throw Exception('API request quota exceeded. Please try again later.');
        }

        _requestCount++;
        await _enforceApiCallInterval();

        // APIリクエストの実行
        final prompt = _buildDetailedContentPrompt(question, correctAnswer, explanation, topic, language);
        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);

        if (response.text == null) {
          throw ContentGenerationException('Failed to generate detailed content');
        }

        String detailedContent = response.text!;
        detailedContent = _adjustExampleRatio(detailedContent, explanation);

        print('DEBUG: Generated detailed content: $detailedContent');
        _contentCache[cacheKey] = detailedContent;
        return detailedContent;
      } catch (e) {
        if (e.toString().contains('Quota exceeded')) {
          retryCount++;
          print('Quota exceeded. Retrying in ${retryDelay.inSeconds} seconds... (Attempt $retryCount)');
          await Future.delayed(retryDelay);
        } else {
          rethrow;
        }
      }
    }
    throw Exception('Failed to generate content after $maxRetries retries due to quota exceeded.');
  }

  String _buildDetailedContentPrompt(String question, String correctAnswer, String explanation, String topic, String language) {
    return '''
You are an AI assistant tasked with generating a specific example that helps to understand the explanation of a learning card.

Card Information:
- Question: "$question"
- Correct Answer: "$correctAnswer"
- Explanation: "$explanation"

Based on the above, generate a specific example that relates to the topic "$topic".

Guidelines:
1. Ensure that the example is consistent with the question, correct answer, and explanation.
2. The example should help in understanding the explanation better.
3. Do not repeat the existing explanation.
4. The content must be in the specified language ("$language").
5. Provide the example directly without any additional text.

Please generate the example now.
''';
  }

  String _adjustExampleRatio(String detailedContent, String explanation) {
    final explanationWordCount = explanation.split(' ').length;
    final minExampleWordCount = (explanationWordCount * 0.3).round();
    final maxExampleWordCount = (explanationWordCount * 0.5).round();

    final detailedContentWords = detailedContent.split(' ');
    final exampleWords = detailedContentWords.sublist(explanationWordCount);

    if (exampleWords.length < minExampleWordCount) {
      print('DEBUG: Example content is too short. Adjusting to minimum ratio.');
      return detailedContentWords.take(explanationWordCount + minExampleWordCount).join(' ');
    } else if (exampleWords.length > maxExampleWordCount) {
      print('DEBUG: Example content is too long. Adjusting to maximum ratio.');
      return detailedContentWords.take(explanationWordCount + maxExampleWordCount).join(' ');
    }

    return detailedContent;
  }

  @override
  Future<List<String>> generateContentBatch(
      List<card_model.CardModel> cardModels, String topic, String language) async {
    List<String> generatedContents = [];
    List<Future<String>> batchRequests = [];

    for (var card in cardModels) {
      if (card.explanation == null || card.explanation.isEmpty) {
        print('WARNING: Card ${card.id} has empty explanation. Skipping content generation.');
        generatedContents.add(''); // 空文字を追加してリストの順序を保つ
        continue;
      }

      // バッチリクエストをキューに追加
      batchRequests.add(generateDetailedContent(
          card.question, card.correctAnswer, card.explanation, topic, language));
    }

    // 同時に実行するバッチサイズを制限（例: 5）
    const int batchSize = 5;
    for (int i = 0; i < batchRequests.length; i += batchSize) {
      final currentBatch = batchRequests.skip(i).take(batchSize).toList();
      try {
        final results = await Future.wait(currentBatch);
        generatedContents.addAll(results);
      } catch (e) {
        print('Error generating content batch: $e');
        // エラーハンドリング: 必要に応じて再試行やスキップ
        generatedContents.addAll(List.filled(currentBatch.length, '')); // エラー時は空文字を追加
      }
    }

    return generatedContents;
  }

  // ヘルパーメソッド
  String _processExtractedTopic(String rawTopic) {
    return rawTopic.split(RegExp(r'[:：]')).last.trim();
  }

  String _processDetailedExample(String example) {
    example = _removeRedundantInformation(example);
    example = _removeEmojis(example);
    return _truncateDetailedContent(example, minLength: _minWordCount, maxLength: _maxWordCount);
  }

  bool _checkDetailedQuality(String example, String explanation, String topic) {
    final wordCount = example.split(' ').length;
    final containsTopic = example.toLowerCase().contains(topic.toLowerCase());
    final relatedToExplanation = _calculateSimilarity(example, explanation) > _similarityThreshold;

    return wordCount >= _minWordCount && wordCount <= _maxWordCount && containsTopic && relatedToExplanation;
  }

  String _truncateDetailedContent(String content, {required int minLength, required int maxLength}) {
    final words = content.split(' ');
    if (words.length < minLength) {
      print('Warning: Generated content is too short.');
      return content;
    }
    return words.take(maxLength).join(' ');
  }

  double _calculateSimilarity(String text1, String text2) {
    final Set<String> words1 = text1.toLowerCase().split(' ').toSet();
    final Set<String> words2 = text2.toLowerCase().split(' ').toSet();
    final int commonWords = words1.intersection(words2).length;
    return commonWords / (words1.length + words2.length - commonWords);
  }

  String _removeRedundantInformation(String content) {
    return content.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _removeEmojis(String content) {
    return content.replaceAll(
        RegExp(
            r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{1F700}-\u{1F77F}|\u{1F780}-\u{1F7FF}|\u{1F800}-\u{1F8FF}|\u{1F900}-\u{1F9FF}|\u{1FA00}-\u{1FA6F}|\u{1FA70}-\u{1FAFF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
            unicode: true),
        '');
  }

  bool _checkRateLimit() {
    final now = DateTime.now();
    _updateApiCalls(_apiCallsMinute, now, Duration(minutes: 1), _maxCallsPerMinute);
    _updateApiCalls(_apiCallsHour, now, Duration(hours: 1), _maxCallsPerHour);
    return _apiCallsMinute.length < _maxCallsPerMinute && _apiCallsHour.length < _maxCallsPerHour;
  }

  void _updateApiCalls(Queue<DateTime> queue, DateTime now, Duration window, int maxCalls) {
    queue.addLast(now);
    while (queue.isNotEmpty && now.difference(queue.first) > window) {
      queue.removeFirst();
    }
    if (queue.length > maxCalls) {
      queue.removeFirst();
    }
  }

  String _fallbackContent(String explanation, String topic, String language) {
    if (language == 'ja') {
      return '$explanation 例えば、$topicの文脈では、この概念を適用して革新的なソリューションを生み出したり、既存のプロセスを改善したりすることができます。';
    } else {
      return '$explanation For example, in the context of $topic, this concept could be applied to create innovative solutions or improve existing processes.';
    }
  }

  DateTime _lastApiCall = DateTime.now().subtract(Duration(minutes: 1));
}