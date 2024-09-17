import 'package:cloud_firestore/cloud_firestore.dart'; // この行を追加

class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<Map<String, dynamic>> currentCourses;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.lastLogin,
    this.currentCourses = const [],
  });

  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      email: data['email'],
      name: data['name'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      lastLogin: (data['last_login'] as Timestamp).toDate(),
      currentCourses: List<Map<String, dynamic>>.from(data['currentCourses'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'created_at': createdAt,
      'last_login': lastLogin,
      'currentCourses': currentCourses,
    };
  }
}