import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/card_model.dart';
import '../models/progress_tracker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:medical_learning_ai/models/manabi_algorithm/review.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/learning.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/new.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/relearning.dart';
import 'package:medical_learning_ai/models/manabi_algorithm/interval_kind.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> getUser(String userId) async {
    try {
      print('Fetching user data for userId: $userId');
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      print('Fetched user data: ${doc.data()}');
      return User.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (error) {
      print('Error getting user: $error');
      return null;
    }
  }

  Future<void> updateUser(User user) async {
    try {
      print('Updating user data for userId: ${user.id}');
      await _db.collection('users').doc(user.id).update(user.toFirestore());
      print('User data updated for userId: ${user.id}');
    } catch (error) {
      print('Error updating user: $error');
    }
  }

  Future<void> saveCard(CardModel card) async {
    try {
      String userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      String documentId = generateCardDocumentId(userId, card.id);

      DocumentReference cardRef = _db
          .collection('user_progress')
          .doc(userId)
          .collection('cards')
          .doc(documentId);

      await cardRef.set(card.toMap(), SetOptions(merge: true));
      print('Card saved: ${card.id}, Path: ${cardRef.path}');
    } catch (e) {
      print('Error saving card: $e');
    }
  }

  Future<void> savePersonalizedCard(String deckId, CardModel card) async {
    try {
      String userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      
      print('DEBUG: Saving personalized card - deckId: $deckId, cardId: ${card.id}');
      print('DEBUG: Card explanation before saving: ${card.explanation}');

      if (card.id == null || card.id.isEmpty) {
        print('Error: Card ID is null or empty. Generating a new ID.');
        card.id = generateDocumentId('user_progress');
      }

      String documentId = generateCardDocumentId(userId, card.id);
      DocumentReference cardRef = _db
          .collection('user_progress')
          .doc(userId)
          .collection('cards')
          .doc(documentId);

      // 既存のデータを取得してマージ
      DocumentSnapshot existingCard = await cardRef.get();
      if (existingCard.exists) {
        print('DEBUG: Existing card found. Merging data.');
        Map<String, dynamic> existingData = existingCard.data() as Map<String, dynamic>;
        String existingExplanation = existingData['explanation'] ?? '';
        print('DEBUG: Existing explanation: $existingExplanation');
        
        // 冗長な情報を削除
        String newExplanation = _removeRedundantInformation('${existingExplanation} ${card.explanation}');
        print('DEBUG: New explanation after removing redundant information: $newExplanation');
        
        // コンテンツをトリミング
        card.explanation = _truncateContent(newExplanation, maxLength: existingExplanation.length * 3);
        print('DEBUG: Merged and truncated explanation: ${card.explanation}');
      }

      print('DEBUG: Final card explanation to be saved: ${card.explanation}');
      await cardRef.set(card.toMap(), SetOptions(merge: true));
      print('DEBUG: Personalized card saved successfully');

      // 保存後の確認
      DocumentSnapshot savedCard = await cardRef.get();
      Map<String, dynamic> savedData = savedCard.data() as Map<String, dynamic>;
      print('DEBUG: Saved card data: $savedData');
    } catch (e) {
      print('Error saving personalized card: $e');
    }
  }

  // 冗長性を排除するメソッド
  String _removeRedundantInformation(String content) {
    // シンプルな冗長性排除ロジック
    // 必要に応じて高度な自然言語処理を追加
    return content.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // コンテンツの長さを制限するメソッド
  String _truncateContent(String content, {required int maxLength}) {
    if (content.length <= maxLength) return content;
    return content.substring(0, maxLength) + '...';
  }

  Future<String?> getUserInfo(String userId) async {
    try {
      print('Fetching user info for userId: $userId');
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        // フィールドが存在するかをチェック
        if (data != null && data.containsKey('userInfo')) {
          print('Fetched user info: ${data['userInfo']}');
          return data['userInfo'] as String?;
        }
      }
      return null;
    } catch (error) {
      print('Error getting userInfo: $error');
      return null;
    }
  }

  Future<void> saveUserInfo(String newUserInfo) async {
    if (newUserInfo.isEmpty) {
      print('Empty user info, not saving to Firestore.');
      return;
    }

    try {
      String userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      DocumentReference userRef = _db.collection('users').doc(userId);

      // 既存のユーザー情報を取得
      String? existingUserInfo = await getUserInfo(userId);
      print('Existing user info: $existingUserInfo');

      // 新いトピックを既存のトピックに追加
      String updatedUserInfo;
      if (existingUserInfo != null && existingUserInfo.isNotEmpty) {
        updatedUserInfo = '$existingUserInfo, $newUserInfo';
      } else {
        updatedUserInfo = newUserInfo;
      }

      // 更新されたトピック情報をFirestoreに保存
      await userRef.set({
        'userInfo': updatedUserInfo,
      }, SetOptions(merge: true));
      print('User info saved for userId: $userId');
    } catch (e) {
      print('Error saving user info: $e');
    }
  }

  Future<void> reviewCard(String cardId, String deckId, int quality) async {
    try {
      print('Reviewing card: $cardId in deck: $deckId with quality: $quality');
      DocumentReference cardRef =
          _db.collection('decks').doc(deckId).collection('cards').doc(cardId);
      DocumentSnapshot cardSnapshot = await cardRef.get();
      if (cardSnapshot.exists) {
        var cardData = cardSnapshot.data() as Map<String, dynamic>;
        var intervalKind = IntervalKind.values.firstWhere(
            (e) => e.toString() == cardData['interval_kind'],
            orElse: () => IntervalKind.newCard);

        Map<String, dynamic> updatedData;

        switch (intervalKind) {
          case IntervalKind.newCard:
            updatedData = NewCardHandler.handleNewCard(cardData['ease_factor'],
                cardData['repetitions'], cardData['interval'], quality);
            break;
          case IntervalKind.learning:
            updatedData = LearningCardHandler.handleLearningCard(
                quality,
                cardData['ease_factor'],
                cardData['repetitions'],
                cardData['interval']);
            break;
          case IntervalKind.review:
            updatedData = ReviewCardHandler.handleReviewCard(
                quality,
                cardData['ease_factor'],
                cardData['repetitions'],
                cardData['interval']);
            break;
          case IntervalKind.relearning:
            updatedData = RelearningCardHandler.handleRelearningCard(
                quality,
                cardData['ease_factor'],
                cardData['repetitions'],
                cardData['interval']);
            break;
          default:
            throw InvalidIntervalKindException('Invalid interval kind');
        }

        await cardRef.update({
          'ease_factor': updatedData['easeFactor'],
          'interval': updatedData['interval'],
          'repetitions': updatedData['repetitions'],
          'last_reviewed_at': Timestamp.fromDate(DateTime.now()),
          'due_date': Timestamp.fromDate(
              DateTime.now().add(Duration(days: updatedData['interval']))),
          'status': convertQualityToStatus(quality),
          'interval_kind':
              _determineIntervalKind(quality, updatedData['repetitions'])
                  .toString(),
        });
        print('Card reviewed: $cardId');
      } else {
        print('Card not found: $cardId');
      }
    } catch (e) {
      print('Error reviewing card: $e');
    }
  }

  IntervalKind _determineIntervalKind(int quality, int repetitions) {
    if (quality == 0) {
      return IntervalKind.newCard;
    } else if (repetitions == 0) {
      return IntervalKind.learning;
    } else if (repetitions == 1) {
      return IntervalKind.learning;
    } else {
      return IntervalKind.review;
    }
  }

  Future<List<Map<String, dynamic>>> getUserProgressDocuments(
      String userId) async {
    try {
      print('Fetching user progress documents for userId: $userId');
      QuerySnapshot querySnapshot = await _db
          .collection('user_progress')
          .doc(userId)
          .collection('progress_tracker')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Found ${querySnapshot.docs.length} progress documents');
        return querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception("No progress documents found");
      }
    } catch (e) {
      print('Error fetching user progress documents: $e');
      return [];
    }
  }

  Future<void> saveSessionData(List<CardModel> cards) async {
    try {
      WriteBatch batch = _db.batch();
      String userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;

      for (var card in cards) {
        String documentId = generateCardDocumentId(userId, card.id);
        DocumentReference cardRef = _db
            .collection('user_progress')
            .doc(userId)
            .collection('cards')
            .doc(documentId);

        batch.update(cardRef, card.toMap());
      }
      await batch.commit();
      print('Session data saved for ${cards.length} cards');
    } catch (e) {
      print('Error saving session data: $e');
    }
  }

  Future<List<CardModel>> getCards(String deckId, String language) async {
    try {
      print('Fetching cards for deckId: $deckId, language: $language');
      
      // デッキのドキュメントを取得して言語を確認
      DocumentSnapshot deckDoc = await _db.collection('decks').doc(deckId).get();
      if (!deckDoc.exists) {
        print('Error: Deck not found for deckId: $deckId');
        return [];
      }
      
      Map<String, dynamic> deckData = deckDoc.data() as Map<String, dynamic>;
      String deckLanguage = deckData['language'] ?? 'en';
      
      if (deckLanguage != language) {
        print('Warning: Deck language ($deckLanguage) does not match requested language ($language)');
        // 要求された言語と一致するデッキを探す
        QuerySnapshot matchingDecks = await _db.collection('decks')
            .where('course_id', isEqualTo: deckData['course_id'])
            .where('language', isEqualTo: language)
            .limit(1)
            .get();
        
        if (matchingDecks.docs.isNotEmpty) {
          deckId = matchingDecks.docs.first.id;
          print('Found matching deck in requested language. New deckId: $deckId');
        } else {
          print('No matching deck found in requested language. Using original deck.');
        }
      }

      QuerySnapshot snapshot = await _db
          .collection('decks')
          .doc(deckId)
          .collection('cards')
          .get();

      List<CardModel> cards = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Card data: $data');
        return CardModel.fromMap(doc.id, deckId, data);
      }).toList();

      print('Fetched ${cards.length} cards for deckId: $deckId, language: $language');
      return cards;
    } catch (e) {
      print('Error loading cards: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDeckCards(String deckId) async {
    try {
        print('Fetching deck cards for deckId: $deckId');
        QuerySnapshot snapshot = await _db.collection('decks').doc(deckId).collection('cards').get();
        List<Map<String, dynamic>> cards = snapshot.docs.map((doc) {
            print('Fetched card: ${doc.id} with data: ${doc.data()}');
            // doc.idをcardに含めるようにする
            var cardData = doc.data() as Map<String, dynamic>;
            cardData['id'] = doc.id;
            return cardData;
        }).toList();
        print('Total cards fetched: ${cards.length} for deckId: $deckId');
        return cards;
    } catch (e) {
        print('Error getting deck cards: $e');
        return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllDecks() async {
    try {
      print('Fetching all decks');
      QuerySnapshot snapshot = await _db.collection('decks').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all decks: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllDecksForLanguage(String language) async {
    try {
      print('Fetching all decks for language: $language');
      QuerySnapshot snapshot = await _db.collection('decks').where('language', isEqualTo: language).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting decks for language $language: $e');
      return [];
    }
  }

  Future<void> addCourseToUser(String userId, Map<String, dynamic> course) async {
    try {
      print('DEBUG: Starting addCourseToUser for userId: $userId with course: $course');
      
      // Validate course fields
      if (course['id'] == null || course['id'].isEmpty) {
        throw Exception('Course ID is null or empty');
      }
      if (course['deckId'] == null || course['deckId'].isEmpty) {
        throw Exception('Deck ID is null or empty in the course object');
      }

      DocumentReference userRef = _db.collection('users').doc(userId);
      DocumentSnapshot userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        List<dynamic> currentCourses = userData.containsKey('currentCourses') ? userData['currentCourses'] : [];
        if (currentCourses.any((c) => c['id'] == course['id'])) {
          print('WARNING: Course already exists for user: $userId');
          return;
        }
      } else {
        await userRef.set({'currentCourses': []}, SetOptions(merge: true));
        print('DEBUG: Initialized currentCourses for user: $userId');
      }

      await userRef.update({
        'currentCourses': FieldValue.arrayUnion([course])
      });
      print('DEBUG: Updated user currentCourses for userId: $userId');

      // Proceed with fetching and saving cards
      // ... existing implementation

    } catch (e) {
      print('ERROR: Error adding course to user: $e');
      throw e; // Rethrow to be caught by higher-level handlers
    }
  }

  Future<void> updateLearningStatus(String userId) async {
    try {
      print('Updating learning status for userId: $userId');
      QuerySnapshot progressTrackerSnapshot = await _db
          .collection('user_progress')
          .doc(userId)
          .collection('progress_tracker')
          .get();

      if (progressTrackerSnapshot.docs.isNotEmpty) {
        for (var doc in progressTrackerSnapshot.docs) {
          Map<String, dynamic> progressData =
              doc.data() as Map<String, dynamic>;
          progressData['cardStatusData'][IntervalKind.review.toString()] =
              (progressData['cardStatusData'][IntervalKind.review.toString()] ??
                      0) +
                  1;
          await doc.reference
              .update({'cardStatusData': progressData['cardStatusData']});
        }
        print('Learning status updated for userId: $userId');
      } else {
        ProgressTracker initialProgress = ProgressTracker(
          progressRate: 0.0,
          consecutiveStudyDays: 0,
          badges: [],
          cardStatusData: {
            IntervalKind.newCard: 0,
            IntervalKind.learning: 0,
            IntervalKind.review: 1,
            IntervalKind.relearning: 0,
          },
          progressStage: 'initial',
        );
        await _db
            .collection('user_progress')
            .doc(userId)
            .collection('progress_tracker')
            .doc(userId)
            .set(initialProgress.toFirestore());
        print('Initialized learning status for userId: $userId');
      }
    } catch (e) {
      print('Error updating learning status: $e');
    }
  }

  Future<void> updateProgressTracker(
      String userId, ProgressTracker progressTracker) async {
    try {
      print('Updating progress tracker for userId: $userId');
      DocumentReference progressRef = _db
          .collection('user_progress')
          .doc(userId)
          .collection('progress_tracker')
          .doc(userId);
      await progressRef.update(progressTracker.toFirestore());
      print('Progress tracker updated for userId: $userId');
    } catch (e) {
      print('Error updating progress tracker: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProgressTracker(String userId) async {
    try {
      print('Fetching progress tracker for userId: $userId');
      DocumentSnapshot doc = await _db
          .collection('user_progress')
          .doc(userId)
          .collection('progress_tracker')
          .doc(userId)
          .get();
      print('Fetched progress tracker: ${doc.data()}');
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching progress tracker: $e');
      return null;
    }
  }

  Future<void> updateCardStatus(CardModel card) async {
    try {
      String userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      String documentId = generateCardDocumentId(userId, card.id);
      DocumentReference cardRef = _db
          .collection('user_progress')
          .doc(userId)
          .collection('cards')
          .doc(documentId);

      print('Updating card status: ${card.id} with data: ${card.toMap()}');

      await cardRef.update(card.toMap()).then((_) {
        print("Card status successfully updated: ${card.id}");
      }).catchError((error) {
        print("Failed to update card status: $error");
      });
    } catch (e) {
      print('Error updating card status: $e');
    }
  }

  String convertQualityToStatus(int quality) {
    switch (quality) {
      case 0:
        return IntervalKind.newCard.toString();
      case 1:
        return IntervalKind.learning.toString();
      case 2:
        return IntervalKind.review.toString();
      case 3:
        return IntervalKind.review.toString();
      default:
        return IntervalKind.newCard.toString();
    }
  }

  Future<void> createUserProgressTracker(
      String userId, Map<String, dynamic> initialProgress) async {
    try {
      print('Creating user progress tracker for userId: $userId');
      await _db
          .collection('user_progress')
          .doc(userId)
          .collection('progress_tracker')
          .doc(userId)
          .set(initialProgress);
      print('User progress tracker created for userId: $userId');
    } catch (e) {
      print('Error creating progress tracker: $e');
    }
  }

  // ドキュメントID生成メソッドを追加
  String generateDocumentId(String collectionPath) {
    return _db.collection(collectionPath).doc().id;
  }

  Future<String?> getPersonalizedExplanation(String userId, String cardId) async {
    try {
      String documentId = generateCardDocumentId(userId, cardId);
      DocumentSnapshot doc = await _db
          .collection('user_progress')
          .doc(userId)
          .collection('cards')
          .doc(documentId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        return data['explanation'] as String?;
      }
    } catch (e) {
      print('Error fetching personalized explanation: $e');
    }
    return null; // パーソナライズされたエクスプラネーションがつからなかった場合
  }

  Future<Map<String, dynamic>> getDeck(String deckId, String language) async {
    try {
      print('DEBUG: Fetching deck with deckId: $deckId and language: $language');
      DocumentSnapshot deckSnapshot = await _db.collection('decks').doc(deckId).get();

      if (!deckSnapshot.exists) {
        throw Exception('Deck not found for deckId: $deckId');
      }

      Map<String, dynamic> deckData = deckSnapshot.data() as Map<String, dynamic>;
      print('DEBUG: Retrieved deck data: $deckData');

      // Check if language matches
      if (deckData['language'] != language) {
        print('DEBUG: Deck language (${deckData['language']}) does not match requested language ($language). Searching for matching deck.');

        QuerySnapshot matchingDecks = await _db.collection('decks')
            .where('course_id', isEqualTo: deckData['course_id'])
            .where('language', isEqualTo: language)
            .limit(1)
            .get();

        if (matchingDecks.docs.isNotEmpty) {
          deckData = matchingDecks.docs.first.data() as Map<String, dynamic>;
          deckData['id'] = matchingDecks.docs.first.id;
          print('DEBUG: Found matching deck: $deckData');
        } else {
          print('WARNING: No matching deck found in requested language. Using original deck data.');
        }
      }

      return deckData;
    } catch (e) {
      print('ERROR: Error fetching deck: $e');
      rethrow;
    }
  }

  Future<void> removeCourseFromUser(String userId, String courseId) async {
    try {
      print('Removing course $courseId for user $userId');
      
      // 1. ユーザードキュメントからコースを削除
      DocumentReference userRef = _db.collection('users').doc(userId);
      DocumentSnapshot userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        List<dynamic> currentCourses = userData['currentCourses'] ?? [];
        currentCourses.removeWhere((course) => course['id'] == courseId);
        await userRef.update({'currentCourses': currentCourses});
      }
      
      // 2. カードサブコレクションから該当コースのカードを削除
      QuerySnapshot cardSnapshot = await _db
          .collection('user_progress')
          .doc(userId)
          .collection('cards')
          .where('deckId', isEqualTo: courseId)
          .get();
      
      WriteBatch batch = _db.batch();
      for (var doc in cardSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // 3. プログレストラッカーを更新
      DocumentReference progressTrackerRef = _db
          .collection('user_progress')
          .doc(userId)
          .collection('progress_tracker')
          .doc(userId);
      
      DocumentSnapshot progressTrackerSnapshot = await progressTrackerRef.get();
      if (progressTrackerSnapshot.exists) {
        Map<String, dynamic> progressData = progressTrackerSnapshot.data() as Map<String, dynamic>;
        Map<String, int> cardStatusData = Map<String, int>.from(progressData['cardStatusData'] ?? {});
        
        // 削除されたカードの数を各テータスから減算
        cardStatusData.forEach((key, value) {
          cardStatusData[key] = (value - cardSnapshot.docs.length) > 0 ? value - cardSnapshot.docs.length : 0;
        });
        
        await progressTrackerRef.update({'cardStatusData': cardStatusData});
      }
      
      print('Successfully removed course $courseId for user $userId');
    } catch (e) {
      print('Error removing course from user: $e');
      rethrow;
    }
  }

  Future<void> savePersonalizedCardsToUserProgress(String userId, String deckId, List<CardModel> cards) async {
    try {
      const int batchSize = 500; // Firestoreのバッチ制限に合わせる
      for (int i = 0; i < cards.length; i += batchSize) {
        final batch = _db.batch();
        final batchCards = cards.skip(i).take(batchSize);

        for (var card in batchCards) {
          if (card.id == null || card.id.isEmpty) {
            print('ERROR: Card ID is null or empty. Skipping card.');
            continue; // 無効なIDのカードはスキップ
          }

          String documentId = generateCardDocumentId(userId, card.id);
          DocumentReference cardRef = _db
              .collection('user_progress')
              .doc(userId)
              .collection('cards')
              .doc(documentId);

          // デバッグ情報の追加
          print('DEBUG: Saving card ID: ${card.id} with data: ${card.toMap()}');

          batch.set(cardRef, card.toMap(), SetOptions(merge: true));
        }

        await batch.commit();
        print('DEBUG: Successfully saved batch of personalized cards to user progress');
      }
    } catch (e) {
      print('ERROR: Error saving personalized cards to user progress: $e');
      throw e;
    }
  }

  // 文単位でトリミングするメソッドを追加
  String _truncateContentAtSentenceLevel(String content, String language) {
    // 最大文字数を設定（例として500文字）
    int maxLength = 500;
    if (content.length <= maxLength) return content;

    List<String> sentences = _splitIntoSentences(content, language);

    StringBuffer truncatedContent = StringBuffer();
    int currentLength = 0;

    for (String sentence in sentences) {
      if ((currentLength + sentence.length) > maxLength) {
        break;
      }
      truncatedContent.write(sentence);
      currentLength += sentence.length;
    }

    return truncatedContent.toString().trim();
  }

  // 文を分割するメソッドを追加
  List<String> _splitIntoSentences(String text, String language) {
    RegExp regExp;
    if (language == 'ja') {
      regExp = RegExp(r'.+?[。！？](?=\s|$)', multiLine: true, dotAll: true);
    } else {
      regExp = RegExp(r'.+?[.!?](?=\s|$)', multiLine: true, dotAll: true);
    }
    return regExp.allMatches(text).map((m) => m.group(0)!).toList();
  }

  String generateCardDocumentId(String userId, String cardId) {
    return '${userId}_$cardId';
  }

  // Save cards to the 'decks/{deckId}/cards' collection
  Future<void> saveCardsToDeck(String deckId, List<CardModel> cards) async {
    try {
      const int batchSize = 500; // Firestore's batch limit
      for (int i = 0; i < cards.length; i += batchSize) {
        final batch = _db.batch();
        final batchCards = cards.skip(i).take(batchSize);

        for (var card in batchCards) {
          if (card.id == null || card.id.isEmpty) {
            print('ERROR: Card ID is null or empty. Skipping card.');
            continue; // Skip invalid cards
          }

          DocumentReference cardRef = _db
              .collection('decks')
              .doc(deckId)
              .collection('cards')
              .doc(card.id);

          batch.set(cardRef, card.toMap(), SetOptions(merge: true));
        }

        await batch.commit();
        print('DEBUG: Successfully saved batch of cards to deck');
      }
    } catch (e) {
      print('ERROR: Error saving cards to deck: $e');
      throw e;
    }
  }

  // Save the course to Firestore
  Future<void> saveCourse(Map<String, dynamic> courseMap) async {
    // Save the course data to the 'decks' collection
    Map<String, dynamic> courseData = Map.from(courseMap);
    courseData.remove('cards'); // Remove cards before saving course metadata
    await _db.collection('decks').doc(courseMap['deck_id']).set(courseData);
    print('DEBUG: Course saved with deck_id: ${courseMap['deck_id']}');
  }
}
