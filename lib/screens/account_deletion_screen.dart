import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../generated/app_localizations.dart';

class AccountDeletionScreen extends StatefulWidget {
  @override
  _AccountDeletionScreenState createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.deleteAccount(_passwordController.text);
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.accountDeletionFailed(e.toString()))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.accountDeletionTitle),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.accountDeletionWarning,
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: localizations.currentPasswordLabel,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _deleteAccount,
              child: _isLoading ? CircularProgressIndicator() : Text(localizations.deleteAccountButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.back),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
    
  }
}
