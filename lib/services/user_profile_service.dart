import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart';

class UserProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<String> getInterestOptions(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return [
      localizations.technology,
      localizations.business,
      localizations.healthAndWellness,
      localizations.creative,
      localizations.hobbiesAndLifestyle,
      localizations.other,
    ];
  }

  Future<void> saveUserInterests(String userId, List<String> interests) async {
    try {
      final Map<String, dynamic> data = {
        'interests': interests,
      };

      await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user interests: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getUserInterests(String userId) async {
    try {
      final DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'interests': data['interests'] as List<dynamic>? ?? [],
          'otherInterests': data['otherInterests'] as String? ?? '',
        };
      }
      return {'interests': [], 'otherInterests': ''};
    } catch (e) {
      print('Error getting user interests: $e');
      throw e;
    }
  }
}