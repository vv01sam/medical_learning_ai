import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'firestore_service.dart';
import '../models/card_model.dart'; // 追加: CardModelのインポートパスに応じて調整してください

class MedlmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Initialize MedLM model
  final GenerativeModel _medlmModel;

  MedlmService()
      : _medlmModel = FirebaseVertexAI.instance.generativeModel(
          model: 'medlm-large',
          temperature: 0.7, // 'temp' から 'temperature' に修正
          maxOutputTokens: 1024,
          topP: 0.8,
          topK: 40,
        );

  Future<String> _getApiKey() async {
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      firebase_auth.IdTokenResult tokenResult = await user.getIdTokenResult();
      return tokenResult.token ?? '';
    } else {
      throw Exception('User not authenticated');
    }
  }

  // Method to create a custom course using MedLM
  Future<void> createCourse(List<String> userResponses) async {
    // Generate course data based on user responses using MedLM
    String courseData = await _generateCourseData(userResponses);

    // Parse the course data into a Map
    Map<String, dynamic> courseMap = parseCourseData(courseData);

    // Save the course to Firestore
    await saveCourse(courseMap);

    // Get current user ID
    String userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;

    // Add the course to the user's list of courses
    await _firestoreService.addCourseToUser(userId, {
      'id': courseMap['course_id'],
      'deckId': courseMap['deck_id'],
      'title': courseMap['title'],
      'description': courseMap['description'],
      'language': courseMap['language'],
      // Include any other necessary fields
    });

    // Save the personalized cards to user's progress
    await _savePersonalizedCards(userId, courseMap);
  }

  // Generate course data using MedLM based on user responses
  Future<String> _generateCourseData(List<String> userResponses) async {
    final String apiKey = await _getApiKey();

    // Combine user responses into a single prompt
    String userNeeds = userResponses.join(' ');

    // Build the prompt for MedLM
    final content = [
      Content.text(
        '''
You are an AI language model specialized in creating medical educational content.

Based on the following user inputs, generate a JSON-formatted custom course tailored to the user's needs. The course should be in the following structure:

{
    "deck_id": "<unique_deck_id>",
    "title": "<Course Title>",
    "description": "<Course Description>",
    "language": "en",
    "course_id": "<unique_course_id>",
    "cards": [
        {
            "question": "<Question 1>",
            "options": [
                "A. <Option A>",
                "B. <Option B>",
                "C. <Option C>",
                "D. <Option D>"
            ],
            "correct_answer": "<Correct Option>",
            "explanation": "<Detailed Explanation>"
        },
        // Add more cards as needed
    ]
}

User Inputs:
$userNeeds

Ensure that:
- The content is accurate and appropriate for medical professionals.
- The JSON is properly formatted.
- Questions are relevant to the user's inputs.
- Explanations are clear and evidence-based.
''',
      ),
    ];

    // Generate the content using MedLM
    final response = await _medlmModel.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to generate course data using MedLM');
    }

    return response.text!.trim();
  }

  // Parse the generated course data from JSON
  Map<String, dynamic> parseCourseData(String courseData) {
    try {
      return jsonDecode(courseData);
    } catch (e) {
      print('Error parsing course data: $e');
      throw Exception('Invalid course data format');
    }
  }

  // Save the course to Firestore
  Future<void> saveCourse(Map<String, dynamic> courseMap) async {
    // Generate a unique deck ID if not provided
    if (courseMap['deck_id'] == null || courseMap['deck_id'].isEmpty) {
      courseMap['deck_id'] =
          'custom_course_${DateTime.now().millisecondsSinceEpoch}';
    }
    // Save the course data to the 'decks' collection
    await _db.collection('decks').doc(courseMap['deck_id']).set(courseMap);
  }

  // Save personalized cards to the user's progress
  Future<void> _savePersonalizedCards(
      String userId, Map<String, dynamic> courseMap) async {
    // Extract cards from the course map
    List<dynamic> cardsData = courseMap['cards'];
    List<CardModel> cards = cardsData.map((cardData) {
      // Generate a unique ID for the card if not provided
      String cardId =
          cardData['id'] ?? _firestoreService.generateDocumentId('cards');
      return CardModel.fromMap(cardId, courseMap['deck_id'], cardData);
    }).toList();

    // Save the cards to the user's progress
    await _firestoreService.savePersonalizedCardsToUserProgress(
        userId, courseMap['deck_id'], cards);
  }
}