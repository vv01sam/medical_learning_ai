import 'package:medical_learning_ai/models/manabi_algorithm/mod.dart';

class LearningCardHandler {
  static Map<String, dynamic> handleLearningCard(int quality, double easeFactor, int repetitions, int previousInterval) {
    return ManabiAlgorithm.update(quality, easeFactor, repetitions, previousInterval);
  }
}
