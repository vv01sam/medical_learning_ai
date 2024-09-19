import 'dart:convert'; // この行を追加
import 'package:cloud_firestore/cloud_firestore.dart';

class MedlmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createCourse(String courseData) async {
    // courseData を解析して適切な形式に変換
    // ここでは仮にJSON形式で受け取るとします
    Map<String, dynamic> courseMap = parseCourseData(courseData);

    await _db.collection('decks').doc(courseMap['deck_id']).set(courseMap);
  }

  Map<String, dynamic> parseCourseData(String courseData) {
    // AIからのレスポンスを解析し、Firestoreに適した形式に変換
    // ここでは単純にJSONとしてパースする例を示します
    return jsonDecode(courseData);
  }
}