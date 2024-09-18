import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;
import '../services/firestore_service.dart';
import '../services/auth_service.dart'; // AuthServiceをインポート
import '../widgets/learning_piechart.dart';
import 'learning_session_screen.dart';
import 'course_list_screen.dart';
import '../models/progress_tracker.dart';
import '../widgets/learning_course.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/mod.dart'; // Import mod.dart
import 'package:medical_learning_ai/models/manabi_algorithm/interval_kind.dart'; // Import IntervalKind
import 'package:medical_learning_ai/generated/app_localizations.dart'; // この行を追加
import 'settings_screen.dart'; // SettingsScreenをインポート

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService(); // AuthServiceのインスタンスを追加
  app_user.User? _currentUser;
  ProgressTracker? _progressTracker;
  bool _isLoggingOut = false; // ログアウト状態を管理するフラグ

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    firebase_auth.User? firebaseUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      app_user.User? user = await _firestoreService.getUser(firebaseUser.uid);
      setState(() {
        _currentUser = user;
      });
      _loadProgressData();
    }
  }

  Future<void> _loadProgressData() async {
    if (_currentUser != null) {
      String userId = _currentUser!.id;
      print('Loading progress data for userId: $userId'); // デバッグ用ログ

      try {
        List<Map<String, dynamic>> progressDocuments =
            await _firestoreService.getUserProgressDocuments(userId);
        print('Fetched progress documents: $progressDocuments'); // デバッグ用ログ

        // 最新のドキュメントを選択
        if (progressDocuments.isNotEmpty) {
          Map<String, dynamic> latestProgressData =
              progressDocuments.last; // 最新のドキュメントを選択
          ProgressTracker progressTracker =
              ProgressTracker.fromFirestore(latestProgressData);
          print(
              'Calculated progress tracker: ${progressTracker.cardStatusData}'); // デバッグ用ログ

          setState(() {
            _progressTracker = progressTracker;
          });
        } else {
          throw Exception("No progress documents found");
        }
      } catch (e) {
        print('Error loading progress data: $e'); // デバッグ用ログ
      }
    }
  }

  Future<void> _addCourse(Map<String, dynamic> course) async {
    if (_currentUser != null) {
      String userId = _currentUser!.id;
      String language = Localizations.localeOf(context).languageCode;
      
      // 言語に基づいてコースデータを取得
      Map<String, dynamic> localizedCourse = await _firestoreService.getDeck(course['id'], language);
      
      bool isCourseAlreadyAdded = _currentUser!.currentCourses.any((c) => c['course_id'] == localizedCourse['course_id']);
      if (!isCourseAlreadyAdded) {
        if (localizedCourse['deckId'] == null) {
          print('Error: deckId is null in the course object');
          return;
        }
        await _firestoreService.addCourseToUser(userId, localizedCourse);
        await _loadUserData();
        print('Course added successfully');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.courseAlreadyAdded)),
        );
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildDrawerHeader(),
            _buildDrawerItem(
                Icons.home_rounded,
                AppLocalizations.of(context)!.homeTitle,
                () => Navigator.pop(context)),
            _buildDrawerItem(
                Icons.school_rounded,
                AppLocalizations.of(context)!.coursesTitle,
                _navigateToCourseList),
            _buildDrawerItem(
                Icons.bar_chart_rounded,
                AppLocalizations.of(context)!.progressTitle,
                () => _showComingSoon(
                    AppLocalizations.of(context)!.progressTitle)),
            _buildDrawerItem(
                Icons.settings_rounded,
                AppLocalizations.of(context)!.settingsTitle,
                _navigateToSettings),
            Divider(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            _buildDrawerItem(Icons.logout_rounded,
                AppLocalizations.of(context)!.logout, _logout),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.homeGreeting.replaceFirst('{name}',
                _currentUser?.name ?? AppLocalizations.of(context)!.guest),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading:
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.transparent,
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }

  void _navigateToCourseList() async {
    final selectedCourse = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CourseListScreen()),
    );
    if (selectedCourse != null) {
      await _addCourse(selectedCourse);
      Navigator.pop(context);
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  void _showComingSoon(String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${feature}${AppLocalizations.of(context)!.comingSoon}'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _logout() async {
    print('Logging out...'); // ログアウト開始のログ
    try {
      setState(() {
        _isLoggingOut = true; // ログアウト状態を設定
      });
      await firebase_auth.FirebaseAuth.instance.signOut();
      await _authService.signOut(); // AuthServiceのsignOutを呼び出す
      print('Logged out'); // ログアウト完了のログ
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error during logout: $e'); // エラーログ
      setState(() {
        _isLoggingOut = false; // エラー時にログアウト状態をリセット
      });
    }
  }

  void _onCourseRemoved() {
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded,
                color: Colors.black54), // アイコンカラーをblack54に変更
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title:
            Image.asset('assets/images/medical_learning_ai.png', height: 40), // 変更箇所
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      backgroundColor: Colors.white,
      body: _isLoggingOut
          ? Center(child: CupertinoActivityIndicator()) // ログアウ��中にインジケーターを表示
          : _currentUser == null || _progressTracker == null
              ? Center(child: CupertinoActivityIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Column(
                            children: (_currentUser?.currentCourses?.isNotEmpty ??
                                    false)
                                ? (_currentUser?.currentCourses ?? [])
                                    .map((course) {
                                    return LearningCourseWidget(
                                        course: course,
                                        progressRate:
                                            _progressTracker!.progressRate,
                                        onCourseRemoved: _onCourseRemoved,
                                    );
                                  }).toList()
                                : [
                                    LearningCourseWidget(
                                      course: {
                                        'title': '',
                                        'description':
                                            AppLocalizations.of(context)!.noCourses
                                      },
                                      progressRate: 0.0,
                                      onCourseRemoved: _onCourseRemoved,
                                    ),
                                  ],
                          ),
                          SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight * 0.4,
                              maxWidth: constraints.maxWidth,
                            ),
                            child: DeckProgressPieChart(
                              progressTracker: _progressTracker!,
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: CupertinoButton(
                              color: Color(0xFFFA6E59), // ボタンの色を変更
                              onPressed: () {
                                // currentCoursesが空でなことを確認
                                if (_currentUser?.currentCourses != null &&
                                    _currentUser!.currentCourses.isNotEmpty) {
                                  // 現在のコースの最初のデッキIDを取得
                                  String deckId =
                                      _currentUser!.currentCourses.first['id'];

                                  print(
                                      'Navigating to LearningSessionScreen with deckId: $deckId'); // デバッグ用ログ

                                  // LearningSessionScreenにデッキIDを渡して遷移
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          LearningSessionScreen(deckId: deckId),
                                    ),
                                  );
                                } else {
                                  // currentCourses空の場合の処理
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(AppLocalizations.of(context)!
                                            .noCourses)),
                                  );
                                }
                              },
                              child:
                                  Text(AppLocalizations.of(context)!.startButton),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

ProgressTracker calculateLearningStatus(Map<String, dynamic> progressData) {
  return ProgressTracker(
    progressRate: progressData['progressRate'] ?? 0.0,
    consecutiveStudyDays: progressData['consecutiveStudyDays'] ?? 0,
    badges: List<String>.from(progressData['badges'] ?? []),
    cardStatusData: Map<IntervalKind, int>.from(progressData['cardStatusData']
            ?.map((key, value) => MapEntry(
                IntervalKind.values.firstWhere((e) => e.toString() == key),
                value)) ??
        {
          IntervalKind.newCard: 0,
          IntervalKind.learning: 0,
          IntervalKind.review: 0,
          IntervalKind.relearning: 0,
        }),
    progressStage: progressData['progressStage'] ?? 'initial',
  );
}
