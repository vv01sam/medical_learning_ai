import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'firestore_service.dart';
import '../models/card_model.dart';

class MedlmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Initialize MedLM model with GenerationConfig
  final GenerativeModel _medlmModel;

  // Add a field to store the number of cards to generate
  final int _numberOfCards = 10;

  MedlmService()
      : _medlmModel = FirebaseVertexAI.instance.generativeModel(
          model: 'med-palm-2', // Update model if needed
          generationConfig: GenerationConfig(
            maxOutputTokens: 512,
            temperature: 0.7,
            topP: 0.8,
            topK: 40,
          ),
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
    // Generate course metadata
    Map<String, dynamic> courseMetadata = await _generateCourseMetadata(userResponses);

    // Generate cards in batches
    List<Map<String, dynamic>> cards = await _generateCourseCards(
      userResponses,
      _numberOfCards,
    );

    // Combine course metadata and cards
    courseMetadata['cards'] = cards;

    // Print the complete course data
    print('Complete course data:');
    print(jsonEncode(courseMetadata));

    // Save the course to Firestore
    await saveCourse(courseMetadata);

    // Get current user ID
    String userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;

    // Add the course to the user's list of courses
    await _firestoreService.addCourseToUser(userId, {
      'id': courseMetadata['course_id'],
      'deckId': courseMetadata['deck_id'],
      'title': courseMetadata['title'],
      'description': courseMetadata['description'],
      'language': courseMetadata['language'],
      // Include any other necessary fields
    });

    // Save the personalized cards to user's progress
    await _savePersonalizedCards(userId, courseMetadata);
  }

  // Method to generate course metadata
  Future<Map<String, dynamic>> _generateCourseMetadata(List<String> userResponses) async {
    // Combine user responses into a single prompt
    String userNeeds = userResponses.join(' ');

    final content = [
      Content.text('''
You are an AI assistant that generates JSON-formatted course metadata.

Based on the following user inputs, generate JSON-formatted course metadata using the exact structure provided below.

**Output only the JSON data, without any additional text or explanations.**

Course metadata structure:

{
    "deck_id": "<unique_deck_id>",
    "title": "<Course Title>",
    "description": "<Course Description>",
    "language": "en",
    "course_id": "<unique_course_id>"
}

User Inputs:
$userNeeds

Instructions:
- Ensure the metadata is accurate and appropriate for medical professionals.
- The JSON must be properly formatted and valid.
- Output only the JSON data, without any additional text or explanations.

Begin output:
'''),
    ];

    // Generate the content using MedLM
    final response = await _medlmModel.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to generate course metadata using MedLM');
    }

    // Parse the JSON string into a Map
    String jsonString = _extractJson(response.text!.trim());
    Map<String, dynamic> courseMetadata = jsonDecode(jsonString);

    return courseMetadata;
  }

  // Method to generate course cards in batches
  Future<List<Map<String, dynamic>>> _generateCourseCards(
      List<String> userResponses, int numberOfCards) async {
    List<Map<String, dynamic>> cards = [];
    int batchSize = 5; // Adjust batch size as needed

    for (int i = 0; i < numberOfCards; i += batchSize) {
      int currentBatchSize = (i + batchSize > numberOfCards) ? numberOfCards - i : batchSize;
      List<Future<Map<String, dynamic>>> batchRequests = [];

      for (int j = 0; j < currentBatchSize; j++) {
        batchRequests.add(_generateCourseCard(userResponses, i + j + 1));
      }

      // Execute batch requests in parallel
      List<Map<String, dynamic>> batchCards = await Future.wait(batchRequests);
      cards.addAll(batchCards);
    }

    return cards;
  }

  // Method to generate a single course card
  Future<Map<String, dynamic>> _generateCourseCard(
      List<String> userResponses, int cardNumber) async {
    // Combine user responses into a single prompt
    String userNeeds = userResponses.join(' ');

    final content = [
      Content.text('''
You are an AI assistant that generates JSON-formatted course cards.

Based on the following user inputs, generate JSON-formatted course card number $cardNumber using the exact structure provided below.

**Output only the JSON data, without any additional text or explanations.**

Card structure:

{
    "question": "<Question>",
    "options": [
        "A. <Option A>",
        "B. <Option B>",
        "C. <Option C>",
        "D. <Option D>"
    ],
    "correct_answer": "<Correct Option>",
    "explanation": "<Detailed Explanation>"
}

User Inputs:
$userNeeds

Instructions:
- Ensure the card content is accurate and appropriate for medical professionals.
- The JSON must be properly formatted and valid.
- The question should be relevant to the user's inputs.
- The explanation should be clear and evidence-based.
- Output only the JSON data, without any additional text or explanations.

Begin output:
'''),
    ];

    // Generate the content using MedLM
    final response = await _medlmModel.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to generate course card using MedLM');
    }

    // Parse the JSON string into a Map
    String jsonString = _extractJson(response.text!.trim());
    Map<String, dynamic> card = jsonDecode(jsonString);

    return card;
  }

  // Helper method to extract JSON from the response
  String _extractJson(String response) {
    final jsonStart = response.indexOf('{');
    final jsonEnd = response.lastIndexOf('}');

    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd >= jsonStart) {
      return response.substring(jsonStart, jsonEnd + 1);
    } else {
      throw FormatException('No JSON object found in the response');
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
    Map<String, dynamic> courseData = Map.from(courseMap);
    courseData.remove('cards'); // Remove cards before saving course metadata
    await _db.collection('decks').doc(courseMap['deck_id']).set(courseData);
  }

  // Save personalized cards to the user's progress and the decks collection
  Future<void> _savePersonalizedCards(
      String userId, Map<String, dynamic> courseMap) async {
    // Extract cards from the course map
    List<dynamic> cardsData = courseMap['cards'];
    List<CardModel> cards = cardsData.map((cardData) {
      // Generate a unique ID for the card if not provided
      String cardId = _firestoreService.generateDocumentId('cards');
      return CardModel.fromMap(cardId, courseMap['deck_id'], cardData);
    }).toList();

    // Save the cards to the 'decks/{deckId}/cards' collection
    await _firestoreService.saveCardsToDeck(courseMap['deck_id'], cards);

    // Save the cards to the user's progress
    await _firestoreService.savePersonalizedCardsToUserProgress(
        userId, courseMap['deck_id'], cards);
  }
}
