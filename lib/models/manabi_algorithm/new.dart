class NewCardHandler {
  static Map<String, dynamic> handleNewCard(double easeFactor, int repetitions, int previousInterval, int quality) {
    double newEaseFactor = easeFactor;
    int newInterval = previousInterval;
    int newRepetitions = repetitions;

    switch (quality) {
      case 0:
        newRepetitions = 0;
        newInterval = 1;
        break;
      case 1:
        newRepetitions = 0;
        newInterval = 1;
        newEaseFactor = easeFactor - 0.14;
        break;
      case 2:
        newRepetitions = 0;
        newInterval = 1;
        newEaseFactor = easeFactor - 0.06;
        break;
      case 3:
        newRepetitions = 1;
        newInterval = 1;
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
