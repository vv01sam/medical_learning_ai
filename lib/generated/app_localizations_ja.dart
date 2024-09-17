import 'app_localizations.dart';

class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get emailHint => 'メールアドレス';
  @override
  String get passwordHint => 'パスワード';
  @override
  String get loginButton => 'ログイン';
  @override
  String get signupButton => '新規登録';
  @override
  String get loginFailed => 'ログインに失敗しました';

  @override
  String get nicknameHint => 'ニックネーム';
  @override
  String get registerButton => '新規登録';
  @override
  String get alreadyHaveAccount => 'すでにアカウントをお持ちですか？';
  @override
  String get registerFailed => '登録に失敗しました';
  @override
  String registerError(String error) => 'エラーが発生しました: $error';

  @override
  String get homeGreeting => 'こんにちは、{name}さん！';
  @override
  String get homeTitle => 'ホーム';
  @override
  String get coursesTitle => 'コース一覧';
  @override
  String get progressTitle => '学習進捗';
  @override
  String get settingsTitle => '設定';
  @override
  String get logout => 'ログアウト';
  @override
  String get courseAlreadyAdded => 'このコースは既に追加されています。';
  @override
  String get noCoursesMessage => 'コースを選択してください。';
  @override
  String get startButton => 'スタート';

  @override
  String get guest => 'ゲスト';
  @override
  String get comingSoon => 'は準備中です。お楽しみに！';
  @override
  String get noCourses => 'まだコースがありません';

  @override
  String get selectCourse => 'コースを選択してください';
  @override
  String get waitingForNewCourses => '新しいコースが追加され��のをお待ちください';
  @override
  String get noDescription => '説明がありません';
  @override
  String get addCourseQuestion => 'このコースを追加しますか？';
  @override
  String get aiPersonalizedAdd => 'AI パーソナライズして追加';
  @override
  String get defaultAdd => 'デフォルトで追加';
  @override
  String get cancel => 'キャンセル';
  @override
  String get inputFieldEmptyError => '入力フィールドは空にできません。';
  @override
  String get courseAdded => 'コースが追加されました';
  @override
  String get inputHint => '質問を入力してください...';
  @override
  String get personalizeAction => 'パーソナライズを実行する';
  @override
  String get nextAction => '次へ';
  @override
  String get errorOccurred => 'エラーが発生しました。もう一度お試しください。';

  @override
  String get chatbotTitle => 'チャットボットと話す';
  @override
  String get closeChat => 'チャットを閉じる';

  @override
  String get learningCourse => '学習中コース :';
  @override
  String get startLabel => '開始';
  @override
  String get learningTimeLabel => '学習時間';
  @override
  String get consecutiveDaysLabel => '連続学習日数';
  @override
  String get daysSuffix => '日';
  @override
  String get secondsSuffix => '秒';

  @override
  String get newCardsLabel => '新しいカード';
  @override
  String get learningCardsLabel => '学習中のカード';
  @override
  String get reviewCardsLabel => '復習カード';
  @override
  String get relearningCardsLabel => '再学習カード';
  @override
  String get progressPieChartTitle => '学習の進捗';

  @override
  String get noData => 'データがありません';
  @override
  String get unknownStatus => '不明なステータス';
  @override
  String get preparingCards => 'カードの準備をしています';

  // LearningSessionScreen用の
  @override
  String get preparingSession => 'セッション準備中';
  @override
  String get sessionCompleted => 'セッション完了';
  @override
  String get congratulations => 'おめでとうございます！';
  @override
  String get finishedForToday => '今日の学習を終えました。';
  @override
  String get backToHome => 'ホームに戻る';
  @override
  String get question => '問題';
  @override
  String get options => '選択肢';
  @override
  String get correctAnswer => '正解';
  @override
  String get explanation => '解説';
  @override
  String get showAnswer => '答えを見る';
  @override
  String get retry => '���う一度';
  @override
  String get difficult => '難しい';
  @override
  String get normal => '普通';
  @override
  String get easy => '簡単';
  @override
  String get endSession => '学習を終了しますか？';
  @override
  String get progressSaved => '進捗は保存されます。';
  @override
  String get cardLimitReached => '1日のカード枚数制限に達しました。';

  @override
  String get privacyPolicy => 'プライバシーポリシー';
  @override
  String get privacyPolicyTitle => 'Katekyoアプリのプライバシーポリシー';
  @override
  String get privacyPolicyContent =>
      'このプライバシーポリシーは、当社が個人情報をどのように収集、使用、保護するかを説明しています...';
  @override
  String get dataCollectionTitle => 'データ収集';
  @override
  String get dataCollectionContent =>
      '当社は以下の種類のデータを収集します：ユーザーアカウント情報、学習進捗データ...';
  @override
  String get dataUsageTitle => 'データの使用';
  @override
  String get dataUsageContent =>
      '当社はあなたのデータを、パーソナライズされた学習体験の提供、進捗の追跡などに使用します...';
  @override
  String get childrenPrivacyTitle => '子供のプ��イバシー';
  @override
  String get childrenPrivacyContent => '当社は13歳未満の子供のプライバシー保護に努めています...';
  @override
  String get privacyPolicyAgreement => '続行するには、プライバシーポリシーをお読みいただき、同意してください';
  @override
  String get viewPrivacyPolicy => 'プライバシーポリシーを表示';
  @override
  String get agreeAndContinue => '同意して続行';
  @override
  String get reportInappropriateContent => '不適切なコンテンツを報告';
  @override
  String get reportConfirmation => 'このコンテンツを報告してもよろしいですか？';
  @override
  String get report => '警告';
  @override
  String get reportThanks => 'ご報告ありがとうございます。速やかに確認いたします。';
  @override
  String get settings => '設定';
  @override
  String get languageSettings => '言語設定';
  @override
  String get parentalControls => 'ペアレンタルコントロール';
  @override
  String get childMode => '子供モード';
  @override
  String get privacyPolicyAgreementRequired => '登録するにはプライバシーポリシーに同意する必要があります。';

  @override
  String get accountDeletionTitle => 'アカウント削除';
  @override
  String get accountDeletionWarning =>
      'アカウントを削除すると、すべてのデータが永久に失われます。この操作は取り消せません。';
  @override
  String get currentPasswordLabel => '現在のパスワード';
  @override
  String get deleteAccountButton => 'アカウントを削除';
  @override
  String get accountDeletionSuccess => 'アカウントが正常に削除されました。';
  @override
  String accountDeletionFailed(String error) => 'アカウント削除に失敗しました: $error';

  @override
  String get back => '戻る';

  @override
  String get rememberMe => 'ログイン状態を保持';

  @override
  String get deleteCourseTitle => 'コースの削除';
  @override
  String get deleteCourseConfirmation =>
      'このコースを削除してもよろしいですか？このコースの学習進捗がすべて失われます。';
  @override
  String get delete => '削除';
  @override
  String get courseDeletedSuccess => 'コースが正常に削除されました。';
  @override
  String get courseDeletedError => 'コースの削除中にエラーが発生しました。もう一度お試しください。';

  @override
  String get selectInterests => '興味のある分野を選択してください';
  @override
  String get technology => 'テクノ��ジー';
  @override
  String get business => 'ビジネス';
  @override
  String get healthAndWellness => '健康とウェルネス';
  @override
  String get creative => 'クリエイティブ';
  @override
  String get hobbiesAndLifestyle => '趣味・ライフスタイル';
  @override
  String get other => 'その他';
  @override
  String get otherInterestsHint => 'その他の興味を入力してください...';

  @override
  String get done => '完了';
}
