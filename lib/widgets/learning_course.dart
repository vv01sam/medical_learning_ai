import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart'; // ローカライズのインポートを追加
import 'package:medical_learning_ai/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LearningCourseWidget extends StatelessWidget {
  final Map<String, dynamic> course;
  final double progressRate;
  final Function onCourseRemoved;

  LearningCourseWidget({
    required this.course,
    required this.progressRate,
    required this.onCourseRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.learningCourse,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            course['title'],
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            course['description'] ?? AppLocalizations.of(context)!.noDescription,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progressRate / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(Colors.green),
                ),
              ),
              SizedBox(width: 16),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.play_arrow, color: Colors.orange),
                onPressed: () {
                  // 学習開始処理
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.startLabel, style: TextStyle(color: Colors.grey)),
                  Text('0/100', style: TextStyle(fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.learningTimeLabel, style: TextStyle(color: Colors.grey)),
                  Text('0${AppLocalizations.of(context)!.secondsSuffix}', style: TextStyle(fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.consecutiveDaysLabel, style: TextStyle(color: Colors.grey)),
                  Text('0${AppLocalizations.of(context)!.daysSuffix}', style: TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteCourseTitle),
          content: Text(AppLocalizations.of(context)!.deleteCourseConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.delete),
              onPressed: () {
                _deleteCourse(context);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCourse(BuildContext context) async {
    final FirestoreService _firestoreService = FirestoreService();
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String courseId = course['id'];

    try {
      await _firestoreService.removeCourseFromUser(userId, courseId);
      onCourseRemoved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.courseDeletedSuccess)),
      );
    } catch (e) {
      print('Error deleting course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.courseDeletedError)),
      );
    }
  }
}