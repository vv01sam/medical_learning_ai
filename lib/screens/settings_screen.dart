import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../main.dart';
import './privacy_policy_screen.dart';
import './account_deletion_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Locale _currentLocale = Locale('en'); // Default value set

  @override
  void initState() {
    super.initState();
    _loadCurrentLocale();
  }

  Future<void> _loadCurrentLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('language_code');
    if (mounted) {
      setState(() {
        _currentLocale = savedLanguageCode != null
            ? Locale(savedLanguageCode)
            : Locale('en'); // Default to 'en'
      });
    }
  }

  Future<void> _changeLanguage(Locale? newLocale) async {
    if (newLocale != null) {
      setState(() {
        _currentLocale = newLocale;
      });
      MyApp.setLocale(context, newLocale);

      // Save the selected language
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', newLocale.languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<Locale>(
                value: _currentLocale,
                isExpanded: true,
                underline: SizedBox(),
                onChanged: _changeLanguage,
                items: [
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: Locale('ja'),
                    child: Text('日本語'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text(localizations.privacyPolicy),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                );
              },
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text(localizations.accountDeletionTitle),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AccountDeletionScreen()),
                );
              },
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              trailing: Icon(Icons.delete_forever, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
