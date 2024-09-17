import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final String privacyPolicyText = '''
# Privacy Policy

## 1. Information We Collect
This application collects the following information:
- User account information (email address, username)
- Application usage data (learning progress, card information)

## 2. Purpose of Information Use
The collected information is used for the following purposes:
- User authentication
- Provision of application features
- Service improvement

## 3. Data Protection
User data is securely stored on Firebase with appropriate access controls implemented.

## 4. Sharing Information with Third Parties
We do not share users' personal information with third parties unless required by law.

## 5. User Rights
Users have the right to request access to, correction of, or deletion of their data.

## 6. Policy Changes
This policy may be changed without prior notice. We will notify users of any changes through appropriate means.

## 7. Contact Information
For any privacy-related questions, please contact us at [aikatekyo@gmail.com].
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Markdown(
        data: privacyPolicyText,
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          p: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}