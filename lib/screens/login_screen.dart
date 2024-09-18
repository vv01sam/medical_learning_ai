import 'package:flutter/material.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart'; // ローカライズ対応のインポート
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false; // New state variable for Remember Me checkbox

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    bool shouldAutoLogin = await _auth.shouldAutoLogin();
    if (shouldAutoLogin) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _signIn() async {
    try {
      await _auth.signInWithEmailAndPersist(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _rememberMe,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginFailed + ': ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

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
                SizedBox(height: 50),
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/medical_learning_ai.png', // 変更箇所
                    height: 150,
                  ),
                ),
                SizedBox(height: 40),
                _buildTextField(
                  controller: _emailController,
                  hintText:
                      AppLocalizations.of(context)!.emailHint, // ローカライズされたテキスト
                  prefixIcon: Icons.email,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  hintText: AppLocalizations.of(context)!
                      .passwordHint, // ローカライズされたテキスト
                  prefixIcon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 20),
                // New Remember Me checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                      side: BorderSide(color: Colors.black54), // 枠線の色を黒に変更
                    ),
                    Text(AppLocalizations.of(context)!.rememberMe),
                  ],
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.loginButton,
                      style: TextStyle(fontSize: 18)), // ローカライズされたテキスト
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _signIn,
                ),
                SizedBox(height: 20),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.signupButton,
                      style: TextStyle(fontSize: 16)), // ローカライズされたテキスト
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
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
}
