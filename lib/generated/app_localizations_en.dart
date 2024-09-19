import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get emailHint => 'Email Address';
  @override
  String get passwordHint => 'Password';
  @override
  String get loginButton => 'Log In';
  @override
  String get signupButton => 'Sign Up';
  @override
  String get loginFailed => 'Failed to log in';

  @override
  String get nicknameHint => 'Nickname';
  @override
  String get registerButton => 'Register';
  @override
  String get alreadyHaveAccount => 'Already have an account?';
  @override
  String get registerFailed => 'Registration failed';
  @override
  String registerError(String error) => 'An error occurred: $error';

  @override
  String get homeGreeting => 'Hello, {name}!';
  @override
  String get homeTitle => 'Home';
  @override
  String get coursesTitle => 'Courses';
  @override
  String get progressTitle => 'Progress';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get logout => 'Logout';
  @override
  String get courseAlreadyAdded => 'This course has already been added.';
  @override
  String get noCoursesMessage => 'Please select a course.';
  @override
  String get startButton => 'Start';

  @override
  String get guest => 'Guest';
  @override
  String get comingSoon => 'Coming soon!';
  @override
  String get noCourses => 'No courses available';

  @override
  String get selectCourse => 'Select a course';
  @override
  String get waitingForNewCourses => 'Please wait for new courses to be added';
  @override
  String get noDescription => 'No description available';
  @override
  String get addCourseQuestion => 'Do you want to add this course?';
  @override
  String get aiPersonalizedAdd => 'Add with AI Personalization';
  @override
  String get defaultAdd => 'Add as Default';
  @override
  String get cancel => 'Cancel';
  @override
  String get inputFieldEmptyError => 'Input field cannot be empty.';
  @override
  String get courseAdded => 'Course has been added.';
  @override
  String get inputHint => 'Enter your question...';
  @override
  String get personalizeAction => 'Execute Personalization';
  @override
  String get nextAction => 'Next';
  @override
  String get errorOccurred => 'An error occurred. Please try again.';

  @override
  String get chatbotTitle => 'Chat with Bot';
  @override
  String get closeChat => 'Close chat';

  @override
  String get learningCourse => 'Learning Course:';
  @override
  String get startLabel => 'Start';
  @override
  String get learningTimeLabel => 'Learning Time';
  @override
  String get consecutiveDaysLabel => 'Consecutive Days';
  @override
  String get daysSuffix => 'd';
  @override
  String get secondsSuffix => 's';

  @override
  String get newCardsLabel => 'New Cards';
  @override
  String get learningCardsLabel => 'Learning Cards';
  @override
  String get reviewCardsLabel => 'Review Cards';
  @override
  String get relearningCardsLabel => 'Relearning Cards';
  @override
  String get progressPieChartTitle => 'Learning Progress';

  @override
  String get noData => 'No Data';
  @override
  String get unknownStatus => 'Unknown Status';
  @override
  String get preparingCards => 'Preparing learning cards...';

  // LearningSessionScreen用の翻訳
  @override
  String get preparingSession => 'Preparing Session';
  @override
  String get sessionCompleted => 'Session Completed';
  @override
  String get congratulations => 'Congratulations!';
  @override
  String get finishedForToday => 'You have finished for today.';
  @override
  String get backToHome => 'Back to Home';
  @override
  String get question => 'Question';
  @override
  String get options => 'Options';
  @override
  String get correctAnswer => 'Correct Answer';
  @override
  String get explanation => 'Explanation';
  @override
  String get showAnswer => 'Show Answer';
  @override
  String get retry => 'again';
  @override
  String get difficult => 'hard';
  @override
  String get normal => 'good';
  @override
  String get easy => 'Easy';
  @override
  String get endSession => 'End Session?';
  @override
  String get progressSaved => 'Progress will be saved.';
  @override
  String get cardLimitReached => 'You have reached the card limit for today.';
  @override
  String get privacyPolicy => 'Privacy Policy';
  @override
  String get privacyPolicyTitle => 'Privacy Policy for Katekyo App';
  @override
  String get privacyPolicyContent =>
      'This privacy policy outlines how we collect, use, and protect your personal information...';
  @override
  String get dataCollectionTitle => 'Data Collection';
  @override
  String get dataCollectionContent =>
      'We collect the following types of data: user account information, learning progress data...';
  @override
  String get dataUsageTitle => 'Data Usage';
  @override
  String get dataUsageContent =>
      'We use your data to provide personalized learning experiences, track your progress...';
  @override
  String get childrenPrivacyTitle => 'Children\'s Privacy';
  @override
  String get childrenPrivacyContent =>
      'We are committed to protecting the privacy of children under 13...';
  @override
  String get privacyPolicyAgreement =>
      'Please read and agree to our Privacy Policy to continue';
  @override
  String get viewPrivacyPolicy => 'View Privacy Policy';
  @override
  String get agreeAndContinue => 'Agree and Continue';
  @override
  String get reportInappropriateContent => 'Report Inappropriate Content';
  @override
  String get reportConfirmation =>
      'Are you sure you want to report this content?';
  @override
  String get report => 'Report';
  @override
  String get reportThanks =>
      'Thank you for your report. We will review it shortly.';
  @override
  String get settings => 'Settings';
  @override
  String get languageSettings => 'Language Settings';
  @override
  String get parentalControls => 'Parental Controls';
  @override
  String get childMode => 'Child Mode';
  @override
  String get privacyPolicyAgreementRequired =>
      'You must agree to the Privacy Policy to register.';

  @override
  String get accountDeletionTitle => 'Account Deletion';
  @override
  String get accountDeletionWarning =>
      'Deleting your account will permanently remove all your data. This action cannot be undone.';
  @override
  String get currentPasswordLabel => 'Current Password';
  @override
  String get deleteAccountButton => 'Delete Account';
  @override
  String get accountDeletionSuccess =>
      'Your account has been successfully deleted.';
  @override
  String accountDeletionFailed(String error) =>
      'Account deletion failed: $error';

  @override
  String get back => 'Back';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get deleteCourseTitle => 'Delete Course';
  @override
  String get deleteCourseConfirmation => 'Are you sure you want to delete this course? All learning progress for this course will be lost.';
  @override
  String get delete => 'Delete';
  @override
  String get courseDeletedSuccess => 'Course has been successfully deleted.';
  @override
  String get courseDeletedError => 'An error occurred while deleting the course. Please try again.';

  @override
  String get selectInterests => 'Select your interests';
  @override
  String get technology => 'Technology';
  @override
  String get business => 'Business';
  @override
  String get healthAndWellness => 'Health and Wellness';
  @override
  String get creative => 'Creative';
  @override
  String get hobbiesAndLifestyle => 'Hobbies and Lifestyle';
  @override
  String get other => 'Other';
  @override
  String get otherInterestsHint => 'Enter other interests...';

  @override
  String get done => 'Done';

  @override
  String get createYourOwnCourse => 'Create your own course'; // 新しいプロパティ
}
