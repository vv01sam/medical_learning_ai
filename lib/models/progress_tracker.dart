import 'package:medical_learning_ai/models/manabi_algorithm/interval_kind.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/review.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/learning.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/new.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/mod.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/relearning.dart';

class ProgressTracker {
  double progressRate;
  int consecutiveStudyDays;
  List<String> badges;
  Map<IntervalKind, int> cardStatusData;
  final String progressStage;

  ProgressTracker({
    required this.progressRate,
    required this.consecutiveStudyDays,
    required this.badges,
    required this.cardStatusData,
    required this.progressStage,
  });

  void updateProgressRate(double newRate) {
    progressRate = newRate;
  }

  void updateConsecutiveStudyDays(int days) {
    consecutiveStudyDays = days;
  }

  void addBadge(String badge) {
    if (!badges.contains(badge)) {
      badges.add(badge);
    }
  }

  void updateCardStatus(IntervalKind oldStatus, IntervalKind newStatus) {
    print('Updating card status from $oldStatus to $newStatus');
    print('Before update: $cardStatusData');

    if (oldStatus != newStatus) {
      if (cardStatusData.containsKey(oldStatus) && cardStatusData[oldStatus]! > 0) {
        cardStatusData[oldStatus] = (cardStatusData[oldStatus] ?? 1) - 1;
      } else {
        print('Warning: oldStatus $oldStatus not found in cardStatusData or value is already 0.');
      }
      cardStatusData[newStatus] = (cardStatusData[newStatus] ?? 0) + 1;
    }

    print('After update: $cardStatusData');
  }

  void updateProgress(int completedSessions) {
    progressRate += completedSessions;
  }

  static ProgressTracker fromFirestore(Map<String, dynamic> data) {
    return ProgressTracker(
      progressRate: data['progressRate'] ?? 0.0,
      consecutiveStudyDays: data['consecutiveStudyDays'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      cardStatusData: Map<IntervalKind, int>.from(data['cardStatusData']?.map((key, value) => MapEntry(IntervalKind.values.firstWhere((e) => e.toString() == key), value)) ?? {
        IntervalKind.newCard: 0,
        IntervalKind.learning: 0,
        IntervalKind.review: 0,
        IntervalKind.relearning: 0,
      }),
      progressStage: data['progressStage'] ?? 'initial',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'progressRate': progressRate,
      'consecutiveStudyDays': consecutiveStudyDays,
      'badges': badges,
      'cardStatusData': cardStatusData.map((key, value) => MapEntry(key.toString(), value)),
      'progressStage': progressStage,
    };
  }
}