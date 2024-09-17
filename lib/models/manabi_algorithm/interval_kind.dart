import 'package:medical_learning_ai/models/manabi_algorithm/new.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/learning.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/review.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/relearning.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/mod.dart';  // この行を追加

enum IntervalKind { newCard, learning, review, relearning }

extension IntervalKindExtension on IntervalKind {
  Map<String, dynamic> handleCard(int quality, double easeFactor, int repetitions, int previousInterval) {
    return ManabiAlgorithm.update(quality, easeFactor, repetitions, previousInterval);
  }
}

class InvalidIntervalKindException implements Exception {
  final String message;
  InvalidIntervalKindException(this.message);

  @override
  String toString() {
    return 'InvalidIntervalKindException: $message';
  }
}