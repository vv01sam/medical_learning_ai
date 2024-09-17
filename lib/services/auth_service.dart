import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as AppUser;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ユーザーのStream
  Stream<AppUser.User?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // FirebaseUserをAppUser.Userに変換する
  AppUser.User? _userFromFirebaseUser(firebase_auth.User? user) {
    return user != null
        ? AppUser.User(
            id: user.uid,
            email: user.email!,
            name: '', // Firestoreから取得する
            createdAt: DateTime.now(), // Firestoreから取得する
            lastLogin: DateTime.now(), // Firestoreから取得する
          )
        : null;
  }

  // サインイン
  Future<void> signInWithEmailAndPersist(String email, String password, bool rememberMe) async {
    try {
      await _setRememberMeMobile(rememberMe);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (error) {
      print(error.toString());
      rethrow;
    }
  }

  Future<void> _setRememberMeMobile(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
  }

  Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rememberMe') ?? false;
  }

  Future<firebase_auth.User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // サインアウト
  Future<void> signOut() async {
    try {
      print('flutter: User signed out');
      await _auth.signOut();
      await _clearRememberMe(); // リメンバー・ミーの状態をクリア
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  Future<void> _clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
  }

  // アカウント削除
  Future<void> deleteAccount(String password) async {
    try {
      firebase_auth.User? user = _auth.currentUser;
      if (user != null) {
        // 1. ユーザーの再認証
        firebase_auth.AuthCredential credential =
            firebase_auth.EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

        // 2. user_progressコレクション内のユーザーに関連するすべてのデータを削除
        await _deleteUserProgress(user.uid);

        // 3. 削除の確認と再試行
        bool isDeleted = await _confirmUserProgressDeletion(user.uid);
        if (!isDeleted) {
          throw Exception('Failed to delete user progress data after multiple attempts');
        }

        // 4. Firestoreからユーザーデータを削除
        await _firestore.collection('users').doc(user.uid).delete();

        // 5. Authenticationからユーザーを削除
        await user.delete();

        print('flutter: User account and all related data deleted: ${user.uid}');
      }
    } catch (error) {
      print('Error deleting account: ${error.toString()}');
      throw error;
    }
  }

  Future<void> _deleteUserProgress(String userId) async {
    try {
      DocumentSnapshot userProgressDoc = await _firestore.collection('user_progress').doc(userId).get();
      if (userProgressDoc.exists) {
        await _firestore.collection('user_progress').doc(userId).delete();
        print('flutter: User progress data deletion initiated for user: $userId');
      } else {
        print('flutter: No user progress data found for user: $userId');
      }
    } catch (error) {
      print('Error deleting user progress: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> _confirmUserProgressDeletion(String userId) async {
    const int maxAttempts = 5; // 再試行回数を増やす
    const int delaySeconds = 5; // 再試行間隔を長くする

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        DocumentSnapshot userProgressDoc = await _firestore.collection('user_progress').doc(userId).get();
        
        if (!userProgressDoc.exists) {
          print('flutter: User progress data confirmed deleted for user: $userId');
          return true;
        }

        print('flutter: User progress data still exists. Attempting deletion again...');
        await _deleteUserProgress(userId);

        await Future.delayed(Duration(seconds: delaySeconds));
      } catch (error) {
        print('Error confirming user progress deletion: ${error.toString()}');
      }
    }

    return false;
  }

  Future<firebase_auth.User?> registerWithEmail(String email, String password, String name) async {
    try {
      firebase_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebase_auth.User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'name': name,
          'created_at': Timestamp.now(),
          'last_login': Timestamp.now(),
        });
      }

      return user;
    } catch (error) {
      print('Error registering with email: $error');
      rethrow;
    }
  }
}
