import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/progress_tracker.dart';
import '../models/manabi_algorithm/interval_kind.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart'; // ローカライズ対応のインポート
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _agreedToPrivacyPolicy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 30),
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/medical_learning_ai.png', // 変更箇所
                    height: 120,
                  ),
                ),
                SizedBox(height: 30),
                _buildTextField(
                  controller: _nameController,
                  hintText: AppLocalizations.of(context)!.nicknameHint,
                  prefixIcon: Icons.person,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  hintText: AppLocalizations.of(context)!.emailHint,
                  prefixIcon: Icons.email,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  hintText: AppLocalizations.of(context)!.passwordHint,
                  prefixIcon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.registerButton,
                      style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _register,
                ),
                SizedBox(height: 20),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.alreadyHaveAccount,
                      style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon:
              Icon(prefixIcon, color: Theme.of(context).colorScheme.secondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  void _register() async {
    try {
      firebase_auth.User? user = await _auth.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      if (user == null) {
        _showErrorSnackBar(AppLocalizations.of(context)!.registerFailed);
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'created_at': Timestamp.now(),
          'last_login': Timestamp.now(),
        });

        await _firestore.collection('user_progress').doc(user.uid).set({});

        ProgressTracker initialProgress = ProgressTracker(
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

        await _firestore
            .collection('user_progress')
            .doc(user.uid)
            .collection('progress_tracker')
            .doc(user.uid)
            .set(initialProgress.toFirestore());

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('agreedToPrivacyPolicy', true);

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Error: $e');
      _showErrorSnackBar(
          AppLocalizations.of(context)!.registerError(e.toString()));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
