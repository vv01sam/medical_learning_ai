class ManabiAlgorithm {
  static const double minEaseFactor = 1.3;
  static const int maxNewCardsPerDay = 20;  // 一致させる
  static const int maxReviewCardsPerDay = 100;

  static Map<String, dynamic> update(int Q, double E_prev, int R_prev, int I_prev) {
    double E_new;
    int I_new;
    int R_new = R_prev;

    // Ease Factorの更新
    E_new = E_prev + (0.1 - (3 - Q) * (0.08 + (3 - Q) * 0.02));
    if (E_new < minEaseFactor) {
      E_new = minEaseFactor;
    }

    // IntervalとRepetitionsの更新
    if (Q >= 1) {  // 回答品質が1以上の場合は正解とみなす
      R_new += 1;
      if (R_new == 1) {
        I_new = 1;
      } else if (R_new == 2) {
        I_new = 6;
      } else {
        I_new = (I_prev * E_new).ceil();
      }
    } else {  // 回答品質が0の場合は不正解
      R_new = 0;
      I_new = 1;
    }

    return {
      'interval': I_new,
      'repetitions': R_new,
      'easeFactor': E_new,
    };
  }
}
