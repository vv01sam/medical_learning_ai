import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../screens/personalized_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../generated/app_localizations.dart';

class CourseListScreen extends StatefulWidget {
  @override
  _CourseListScreenState createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _courses = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    String language = Localizations.localeOf(context).languageCode;
    List<Map<String, dynamic>> courses = await _firestoreService.getAllDecksForLanguage(language);
    setState(() {
      _courses = courses;
    });
  }

  Future<void> _addCourse(Map<String, dynamic> deck) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    Map<String, dynamic> course = {
      'id': deck['id'],
      'title': deck['title'],
      'description': deck['description'],
      'created_by': deck['created_by'],
      'deckId': deck['id'],
    };
    await _firestoreService.addCourseToUser(userId, course);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  void _showCourseDialog(Map<String, dynamic> deck) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(deck['title']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(deck['description'] ?? AppLocalizations.of(context)!.noDescription),
              SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.addCourseQuestion),
            ],
          ),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.aiPersonalizedAdd),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      PersonalizedScreen(deckId: deck['id']),
                ));
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.defaultAdd),
              onPressed: () {
                Navigator.of(context).pop();
                _addCourse(deck);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectCourse,
            style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: _courses.isEmpty
          ? _buildEmptyState()
          : _buildCourseList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school,
              size: 80, color: Theme.of(context).colorScheme.secondary),
          SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.noCourses,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.waitingForNewCourses,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    return ListView.builder(
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> deck = _courses[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                deck['title'][0].toUpperCase(),
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              deck['title'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(deck['description'] ?? AppLocalizations.of(context)!.noDescription),
            trailing: Icon(Icons.add_circle,
                color: Theme.of(context).colorScheme.primary),
            onTap: () => _showCourseDialog(deck),
          ),
        );
      },
    );
  }
}