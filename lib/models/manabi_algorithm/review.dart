class ReviewCardHandler {
  static Map<String, dynamic> handleReviewCard(int quality, double easeFactor, int repetitions, int previousInterval) {
    double newEaseFactor = easeFactor;
    int newInterval = previousInterval;
    int newRepetitions = repetitions;

    switch (quality) {
      case 0:
        newRepetitions = 0;
        newInterval = 1;
        break;
      case 1:
        newRepetitions = repetitions;
        newInterval = (previousInterval * 0.5).round();
        newEaseFactor = easeFactor - 0.2;
        break;
      case 2:
        newRepetitions = repetitions;
        newInterval = (previousInterval * 0.7).round();
        newEaseFactor = easeFactor - 0.15;
        break;
      case 3:
        newRepetitions = repetitions;
        newInterval = (previousInterval * newEaseFactor).round();
        break;
    }

    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    return {
      'easeFactor': newEaseFactor,
      'interval': newInterval,
      'repetitions': newRepetitions,
    };
  }
}
