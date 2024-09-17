import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/interval_kind.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/new.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/learning.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/review.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/relearning.dart';

class CardModel {
  String id;
  String question;
  List<String> options;
  String correctAnswer;
  String explanation;
  Timestamp? lastReviewedAt; // Nullableに変更
  double easeFactor;
  int interval;
  int repetitions;
  int quality;
  String deckId;
  Timestamp? dueDate; // Nullableに変更
  IntervalKind intervalKind;

  IntervalKind get status => intervalKind;

  CardModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.lastReviewedAt,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.quality = 0,
    required this.deckId,
    this.dueDate,
    this.intervalKind = IntervalKind.newCard,
  });

  void updateReview(int newQuality) {
    Map<String, dynamic> updatedData;

    switch (intervalKind) {
      case IntervalKind.newCard:
        updatedData = NewCardHandler.handleNewCard(easeFactor, repetitions, interval, newQuality);
        break;
      case IntervalKind.learning:
        updatedData = LearningCardHandler.handleLearningCard(newQuality, easeFactor, repetitions, interval);
        break;
      case IntervalKind.review:
        updatedData = ReviewCardHandler.handleReviewCard(newQuality, easeFactor, repetitions, interval);
        break;
      case IntervalKind.relearning:
        updatedData = RelearningCardHandler.handleRelearningCard(newQuality, easeFactor, repetitions, interval);
        break;
      default:
        throw InvalidIntervalKindException('Invalid interval kind');
    }

    interval = updatedData['interval'];
    repetitions = updatedData['repetitions'];
    easeFactor = updatedData['easeFactor'];
    quality = newQuality;
    lastReviewedAt = Timestamp.fromDate(DateTime.now());
    dueDate = Timestamp.fromDate(DateTime.now().add(Duration(days: interval)));
    intervalKind = determineIntervalKind(newQuality, repetitions);
  }

  IntervalKind determineIntervalKind(int quality, int repetitions) {
    if (quality == 0) {
      return IntervalKind.newCard;
    } else if (repetitions == 0) {
      return IntervalKind.learning;
    } else if (repetitions == 1) {
      return IntervalKind.learning;
    } else {
      return IntervalKind.review;
    }
  }

  void updateRepetitionData(int newInterval, int newRepetitions, double newEaseFactor, Timestamp? newLastReviewedAt, Timestamp? newDueDate) {
    interval = newInterval;
    repetitions = newRepetitions;
    easeFactor = newEaseFactor;
    lastReviewedAt = newLastReviewedAt;
    dueDate = newDueDate;
  }

  Map<String, dynamic> toMap() {
    var map = {
      'id': id,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'last_reviewed_at': lastReviewedAt,
      'ease_factor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'quality': quality,
      'deck_id': deckId,
      'due_date': dueDate,
      'interval_kind': intervalKind.toString(),
    };
    return map;
  }

  static CardModel fromMap(String id, String deckId, Map<String, dynamic> map) {
    // Debug: Print the incoming map data
    print('DEBUG: Parsing CardModel from map: $map');
    
    // Extract fields with null checks
    String question = map['question'] ?? '';
    String correctAnswer = map['correct_answer'] ?? '';
    String explanation = map['explanation'] ?? '';

    // Debug: Check for null or empty fields
    if (question.isEmpty) {
      print('WARNING: "question" field is missing or empty for card ID: $id');
    }
    if (correctAnswer.isEmpty) {
      print('WARNING: "correct_answer" field is missing or empty for card ID: $id');
    }
    if (explanation.isEmpty) {
      print('WARNING: "explanation" field is missing or empty for card ID: $id');
    }

    List<String> options = [];
    try {
      options = List<String>.from(map['options'] ?? []);
      if (options.isEmpty) {
        print('WARNING: "options" field is missing or empty for card ID: $id');
      }
    } catch (e) {
      print('ERROR: Error parsing "options" for card ID: $id - $e');
    }

    return CardModel(
      id: id,
      question: question,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      lastReviewedAt: map['last_reviewed_at'] != null ? (map['last_reviewed_at'] as Timestamp) : null,
      easeFactor: (map['ease_factor'] ?? 2.5).toDouble(),
      interval: map['interval'] ?? 0,
      repetitions: map['repetitions'] ?? 0,
      quality: map['quality'] ?? 0,
      deckId: deckId,
      dueDate: map['due_date'] != null ? (map['due_date'] as Timestamp) : null,
      intervalKind: IntervalKind.values.firstWhere(
        (e) => e.toString() == map['interval_kind'],
        orElse: () => IntervalKind.newCard,
      ),
    );
  }
}