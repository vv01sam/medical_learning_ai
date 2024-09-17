import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:medical_learning_ai/models/card_model.dart';
import 'package:medical_learning_ai/screens/home_screen.dart';
import 'package:medical_learning_ai/services/firestore_service.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/new.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/learning.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/review.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/relearning.dart';
import 'package:medical_learning_ai/models/progress_tracker.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/interval_kind.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart'; // Import localization

class LearningSessionScreen extends StatefulWidget {
  final String deckId;

  LearningSessionScreen({required this.deckId});

  @override
  _LearningSessionScreenState createState() => _LearningSessionScreenState();
}

class _LearningSessionScreenState extends State<LearningSessionScreen> {
  List<CardModel> _cards = [];
  CardModel? _currentCard;
  bool _isFront = true;
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  final String userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  late ProgressTracker _progressTracker;
  static int newCardsCountToday = 0;
  static int reviewCardsCountToday = 0;
  static const int maxNewCardsPerDay = 20;
  static const int maxReviewCardsPerDay = 100;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeLearningSession();
  }

  Future<void> _initializeLearningSession() async {
    await _loadProgressTracker();
    print('Starting learning session for deckId: ${widget.deckId}, userId: $userId');
    
    // ウィジェットが完全に構築された後にカードを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCards();
    });
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });

    // デバイスの現在の言語設定を取得
    String currentLanguage = Localizations.localeOf(context).languageCode;
    
    List<CardModel> cards = await _firestoreService.getCards(widget.deckId, currentLanguage);
    // パーソナライズされたエクスプラネーションを取得するための処理
    for (var card in cards) {
      var personalizedExplanation =
          await _firestoreService.getPersonalizedExplanation(userId, card.id);
      if (personalizedExplanation != null) {
        card.explanation = personalizedExplanation; // パーソナライズされたエクスプラネーションを適用
      }
    }

    setState(() {
      _cards = cards;
      if (_cards.isNotEmpty) {
        _currentCard = _cards.first;
      }
      _isLoading = false;
    });

    print('Loaded ${_cards.length} cards for learning session');
    for (var card in _cards) {
      print(
          'Card loaded: ${card.id}, quality: ${card.quality}, repetitions: ${card.repetitions}, easeFactor: ${card.easeFactor}, interval: ${card.interval}');
    }
  }

  Future<void> _loadProgressTracker() async {
    Map<String, dynamic>? progressData =
        await _firestoreService.getUserProgressTracker(userId);
    if (progressData != null) {
      setState(() {
        _progressTracker = ProgressTracker.fromFirestore(progressData);
      });
    } else {
      setState(() {
        _progressTracker = ProgressTracker(
          progressRate: 0.0,
          consecutiveStudyDays: 0,
          badges: [],
          cardStatusData: {
            IntervalKind.newCard: 0,
            IntervalKind.learning: 0,
            IntervalKind.review: 0,
            IntervalKind.relearning: 0,
          },
          progressStage: 'initial',
        );
      });
    }
  }

  void _flipCard() {
    setState(() {
      _isFront = !_isFront;
    });
  }

  void endLearningSession() async {
    await _firestoreService.saveSessionData(_cards); // Save session data
    setState(() {
      _currentCard = null; // セッション終了を示すためにカードをクリア
    });
  }

  void _qualityCard(int quality) async {
    if (_currentCard == null) return;

    print(
        'Starting quality card process for card: ${_currentCard!.id}, user response: $quality');

    if ((_currentCard!.intervalKind == IntervalKind.newCard &&
            newCardsCountToday >= maxNewCardsPerDay) ||
        (_currentCard!.intervalKind != IntervalKind.newCard &&
            reviewCardsCountToday >= maxReviewCardsPerDay)) {
      _showLimitReachedMessage();
      endLearningSession();
      return;
    }

    print('Reviewing card: ${_currentCard!.id}, user response: $quality');

    IntervalKind oldStatus = _currentCard!.intervalKind;
    Map<String, dynamic> updatedData;

    switch (_currentCard!.intervalKind) {
      case IntervalKind.newCard:
        print('Card is in newCard state');
        updatedData = NewCardHandler.handleNewCard(_currentCard!.easeFactor,
            _currentCard!.repetitions, _currentCard!.interval, quality);
        newCardsCountToday++;
        break;
      case IntervalKind.learning:
        print('Card is in learning state');
        updatedData = LearningCardHandler.handleLearningCard(
            quality,
            _currentCard!.easeFactor,
            _currentCard!.repetitions,
            _currentCard!.interval);
        break;
      case IntervalKind.review:
        print('Card is in review state');
        updatedData = ReviewCardHandler.handleReviewCard(
            quality,
            _currentCard!.easeFactor,
            _currentCard!.repetitions,
            _currentCard!.interval);
        reviewCardsCountToday++;
        break;
      case IntervalKind.relearning:
        print('Card is in relearning state');
        updatedData = RelearningCardHandler.handleRelearningCard(
            quality,
            _currentCard!.easeFactor,
            _currentCard!.repetitions,
            _currentCard!.interval);
        break;
      default:
        throw InvalidIntervalKindException('Invalid interval kind');
    }

    _currentCard!.interval = updatedData['interval'];
    _currentCard!.repetitions = updatedData['repetitions'];
    _currentCard!.easeFactor = updatedData['easeFactor'];
    _currentCard!.quality = quality;
    _currentCard!.lastReviewedAt = Timestamp.fromDate(DateTime.now());
    _currentCard!.dueDate = Timestamp.fromDate(
        DateTime.now().add(Duration(days: _currentCard!.interval)));
    _currentCard!.intervalKind =
        _determineIntervalKind(quality, _currentCard!.repetitions);

    print(
        'Updated card: ${_currentCard!.id}, new status: ${_currentCard!.intervalKind}, interval: ${_currentCard!.interval}, repetitions: ${_currentCard!.repetitions}, easeFactor: ${_currentCard!.easeFactor}');

    await _firestoreService.updateCardStatus(_currentCard!);
    _progressTracker.updateCardStatus(oldStatus, _currentCard!.intervalKind);

    print(
        'Updating progress tracker. Old status: $oldStatus, New status: ${_currentCard!.intervalKind}');
    await _firestoreService.updateProgressTracker(userId, _progressTracker);

    setState(() {
      if (_cards.isNotEmpty) {
        _cards.removeAt(0);
        if (_cards.isNotEmpty) {
          _currentCard = _cards.first;
          _isFront = true;
        } else {
          _currentCard = null;
          endLearningSession();
        }
      }
    });

    if (_currentCard != null) {
      print(
          'Updated Card Status: ${_currentCard!.id}, interval: ${_currentCard!.interval}, repetitions: ${_currentCard!.repetitions}, easeFactor: ${_currentCard!.easeFactor}');
    }
  }

  IntervalKind _determineIntervalKind(int quality, int repetitions) {
    print(
        'Determining interval kind for quality: $quality, repetitions: $repetitions');
    if (quality == 0) {
      print('Interval kind set to IntervalKind.newCard due to quality 0');
      return IntervalKind.newCard;
    } else if (repetitions == 0) {
      print('Interval kind set to IntervalKind.learning due to repetitions 0');
      return IntervalKind.learning;
    } else if (repetitions == 1) {
      print('Interval kind set to IntervalKind.learning due to repetitions 1');
      return IntervalKind.learning;
    } else {
      print('Interval kind set to IntervalKind.review');
      return IntervalKind.review;
    }
  }

  void _showLimitReachedMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.cardLimitReached),
          content: Text(AppLocalizations.of(context)!.cardLimitReached),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_currentCard == null) {
      return _buildNoCardsScreen();
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: _showEndSessionDialog,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final isWideScreen = constraints.maxWidth > 600;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 800 : constraints.maxWidth),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildCardContent(isWideScreen),
                          ),
                        ),
                        SizedBox(height: 16),
                        _isFront
                            ? _buildShowAnswerButton(isWideScreen)
                            : _buildAnswerButtons(isWideScreen, constraints),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context)!.preparingSession)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.preparingCards,
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCardsScreen() {
    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context)!.sessionCompleted)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration,
                size: 80, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.congratulations,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.finishedForToday,
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => HomeScreen())),
              child: Text(AppLocalizations.of(context)!.backToHome),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFA6E59),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(bool isWideScreen) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.question,
              style: TextStyle(
                fontSize: isWideScreen ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: isWideScreen ? 15 : 10),
            Text(
              _currentCard!.question,
              style: TextStyle(fontSize: isWideScreen ? 20 : 18),
            ),
            SizedBox(height: isWideScreen ? 25 : 20),
            Text(
              AppLocalizations.of(context)!.options,
              style: TextStyle(
                fontSize: isWideScreen ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            ..._currentCard!.options.map((option) => Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: isWideScreen ? 6.0 : 4.0),
                  child: GestureDetector(
                    onTap: () => _flipCard(),
                    child: Text(
                      option,
                      style: TextStyle(fontSize: isWideScreen ? 18 : 16),
                    ),
                  ),
                )),
            if (!_isFront) ...[
              SizedBox(height: isWideScreen ? 25 : 20),
              Text(
                AppLocalizations.of(context)!.correctAnswer,
                style: TextStyle(
                  fontSize: isWideScreen ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: isWideScreen ? 8 : 5),
              Text(
                _currentCard!.correctAnswer,
                style: TextStyle(
                    fontSize: isWideScreen ? 18 : 16,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: isWideScreen ? 25 : 20),
              Text(
                AppLocalizations.of(context)!.explanation,
                style: TextStyle(
                  fontSize: isWideScreen ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: isWideScreen ? 8 : 5),
              Text(
                _currentCard!.explanation,
                style: TextStyle(fontSize: isWideScreen ? 18 : 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShowAnswerButton(bool isWideScreen) {
    return CupertinoButton(
      color: Colors.blue,
      onPressed: _flipCard,
      child: Text(
        AppLocalizations.of(context)!.showAnswer,
        style: TextStyle(fontSize: isWideScreen ? 20 : 18, color: Colors.white),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 60 : 50,
        vertical: isWideScreen ? 18 : 15,
      ),
      borderRadius: BorderRadius.circular(isWideScreen ? 35 : 30),
    );
  }

  Widget _buildAnswerButtons(bool isWideScreen, BoxConstraints constraints) {
    final buttonList = _buildAnswerButtonList(isWideScreen);
    return isWideScreen
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttonList,
          )
        : Column(
            children: [
              Row(
                children: [
                  Expanded(child: buttonList[0]),
                  SizedBox(width: 8),
                  Expanded(child: buttonList[1])
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: buttonList[2]),
                  SizedBox(width: 8),
                  Expanded(child: buttonList[3])
                ],
              ),
            ],
          );
  }

  List<Widget> _buildAnswerButtonList(bool isWideScreen) {
    return [
      _buildCupertinoAnswerButton(
        AppLocalizations.of(context)!.retry,
        () => _qualityCard(0),
        Color.fromARGB(200, 244, 67, 54),
        isWideScreen,
      ),
      _buildCupertinoAnswerButton(
        AppLocalizations.of(context)!.difficult,
        () => _qualityCard(1),
        Color.fromARGB(200, 255, 153, 0),
        isWideScreen,
      ),
      _buildCupertinoAnswerButton(
        AppLocalizations.of(context)!.normal,
        () => _qualityCard(2),
        Color.fromARGB(200, 76, 175, 79),
        isWideScreen,
      ),
      _buildCupertinoAnswerButton(
        AppLocalizations.of(context)!.easy,
        () => _qualityCard(3),
        Color.fromARGB(200, 33, 149, 243),
        isWideScreen,
      ),
    ];
  }

  Widget _buildCupertinoAnswerButton(
      String label, VoidCallback onPressed, Color color, bool isWideScreen) {
    return CupertinoButton(
      color: color,
      onPressed: onPressed,
      child: Text(label,
          style:
              TextStyle(fontSize: isWideScreen ? 18 : 14, color: Colors.white)),
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 40 : 20,
        vertical: isWideScreen ? 18 : 12,
      ),
      borderRadius: BorderRadius.circular(isWideScreen ? 25 : 20),
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.endSession),
          content: Text(AppLocalizations.of(context)!.progressSaved),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.endSession),
              onPressed: () {
                Navigator.of(context).pop();
                endLearningSession();
              },
            ),
          ],
        );
      },
    );
  }
}
