import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  // ログイン画面のテキスト
  String get emailHint;
  String get passwordHint;
  String get loginButton;
  String get signupButton;
  String get loginFailed;

  // 登録画面のテキスト
  String get nicknameHint;
  String get registerButton;
  String get alreadyHaveAccount;
  String get registerFailed;
  String registerError(String error);

  // ホーム画面のテキスト
  String get homeGreeting;
  String get homeTitle;
  String get coursesTitle;
  String get progressTitle;
  String get settingsTitle;
  String get logout;
  String get courseAlreadyAdded;
  String get noCoursesMessage;
  String get startButton;

  // 新規追加したプロパティ
  String get guest;
  String get comingSoon;
  String get noCourses;

  // 新しいプロパティ
  String get selectCourse;
  String get waitingForNewCourses;
  String get noDescription;
  String get addCourseQuestion;
  String get aiPersonalizedAdd;
  String get defaultAdd;
  String get cancel;

  // 新しいプロパティ
  String get inputFieldEmptyError;
  String get courseAdded;
  String get inputHint;
  String get personalizeAction;
  String get nextAction;
  String get errorOccurred;

  // 新しく追加するプロパティ
  String get chatbotTitle;  // チャットポップアップのタイトル
  String get closeChat;     // チャットを閉じるツールチップ

  // Learning Course ウィジェットの翻訳キー
  String get learningCourse;
  String get startLabel;
  String get learningTimeLabel;
  String get consecutiveDaysLabel;
  String get daysSuffix;
  String get secondsSuffix;

  // Learning Pie Chart ウィジェットの翻訳キー
  String get newCardsLabel;
  String get learningCardsLabel;
  String get reviewCardsLabel;
  String get relearningCardsLabel;
  String get progressPieChartTitle;

  // 新しいプロパティ
  String get noData;
  String get unknownStatus;
  String get preparingCards;

  // LearningSessionScreen用のプロパティ
  String get preparingSession;
  String get sessionCompleted;
  String get congratulations;
  String get finishedForToday;
  String get backToHome;
  String get question;
  String get options;
  String get correctAnswer;
  String get explanation;
  String get showAnswer;
  String get retry;
  String get difficult;
  String get normal;
  String get easy;
  String get endSession;
  String get progressSaved;
  String get cardLimitReached;

  // 新しいプロパティ
  String get privacyPolicy;
  String get privacyPolicyTitle;
  String get privacyPolicyContent;
  String get dataCollectionTitle;
  String get dataCollectionContent;
  String get dataUsageTitle;
  String get dataUsageContent;
  String get childrenPrivacyTitle;
  String get childrenPrivacyContent;
  String get privacyPolicyAgreement;  // 新しいプロパティ
  String get viewPrivacyPolicy;
  String get agreeAndContinue;
  String get reportInappropriateContent;
  String get reportConfirmation;
  String get report;
  String get reportThanks;
  String get settings;
  String get languageSettings;
  String get parentalControls;
  String get childMode;
  String get privacyPolicyAgreementRequired;  // 新しいプロパティ

  // アカウント削除関連のプロパティ
  String get accountDeletionTitle;
  String get accountDeletionWarning;
  String get currentPasswordLabel;
  String get deleteAccountButton;
  String get accountDeletionSuccess;
  String accountDeletionFailed(String error);

  // 新しく追加するゲッター
  String get back;
  String get rememberMe;

  // 新しい翻訳キー
  String get deleteCourseTitle;
  String get deleteCourseConfirmation;
  String get delete;
  String get courseDeletedSuccess;
  String get courseDeletedError;

  // ... (既存のコードはそのまま)

  // cancel は既に定義されているため、ここでは追加しません

  // 新しく追加するゲッター
  String get selectInterests;
  String get technology;
  String get business;
  String get healthAndWellness;
  String get creative;
  String get hobbiesAndLifestyle;
  String get other;
  String get otherInterestsHint;

  // ... 既存のコード ...

  // 新しく追加するゲッター
  String get done;

  // ... 既存のコード ...
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}