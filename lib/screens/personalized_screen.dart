import 'package:flutter/material.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';
import '../services/user_profile_service.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart' as card_model;

class PersonalizedScreen extends StatefulWidget {
  final String deckId;

  PersonalizedScreen({required this.deckId});

  @override
  _PersonalizedScreenState createState() => _PersonalizedScreenState();
}

class _PersonalizedScreenState extends State<PersonalizedScreen> {
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _firestoreService = FirestoreService();
  final UserProfileService _userProfileService = UserProfileService();
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  int _slideIndex = 0;
  List<String> _questions = [];
  String _lastAnswer = '';
  Map<String, dynamic> _userInterests = {};
  List<String> _selectedInterests = [];
  TextEditingController _otherInterestsController = TextEditingController();
  List<String> _conversationHistory = [];
  int _conversationStage = 0;
  final int _maxConversationStages = 2;

  final Color _primaryColor = Colors.blue.shade300;
  final Color _backgroundColor = Colors.blue.shade50;
  final Color _accentColor = Colors.orange.shade300;

  double _questionFontSize = 16.0;
  Color _questionTextColor = Colors.black54;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }

  Future<void> _loadUserInterests() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    _userInterests = await _userProfileService.getUserInterests(userId);
    if (_userInterests['interests'].isEmpty) {
      _showInterestSelectionDialog();
    } else {
      _generateInitialQuestion();
    }
  }

  void _showInterestSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.selectInterests,
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildInterestCheckboxes(setState),
                    if (_selectedInterests.contains(AppLocalizations.of(context)!.other))
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextField(
                          controller: _otherInterestsController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.otherInterestsHint,
                            hintStyle: TextStyle(color: Colors.black54),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.done,
                style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _saveUserInterests();
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _backgroundColor,
        );
      },
    );
  }

  List<Widget> _buildInterestCheckboxes(StateSetter setState) {
    return getInterestOptions(context).map((interest) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: CheckboxListTile(
          title: Text(
            interest,
            style: TextStyle(color: _questionTextColor, fontWeight: FontWeight.bold),
          ),
          value: _selectedInterests.contains(interest),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedInterests.add(interest);
              } else {
                _selectedInterests.remove(interest);
              }
            });
          },
          activeColor: _primaryColor,
          checkColor: Colors.white,
          controlAffinity: ListTileControlAffinity.leading,
          side: BorderSide(color: Colors.black54), // チェックボックスの枠の色を変更
        ),
      );
    }).toList();
  }

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

  Future<void> _saveUserInterests() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    List<String> interests = _selectedInterests;
    if (interests.contains(AppLocalizations.of(context)!.other)) {
      interests.remove(AppLocalizations.of(context)!.other);
      if (_otherInterestsController.text.isNotEmpty) {
        interests.add(_otherInterestsController.text);
      }
    }
    await _userProfileService.saveUserInterests(userId, interests);
    _generateInitialQuestion();
  }

  Future<void> _generateInitialQuestion() async {
    try {
      setState(() {
        _isLoading = true;
      });
      String language = Localizations.localeOf(context).languageCode;
      
      String userInterests = _selectedInterests.join(', ');

      String initialQuestion = await _geminiService.generatePersonalizedQuestion(
          widget.deckId, 
          userInterests,
          '', 
          '', 
          _questions, 
          language
      );
      print('DEBUG: Initial question generated: $initialQuestion'); // デバッグコード追加
      setState(() {
        _questions.add(initialQuestion);
        _isLoading = false;
        _conversationStage = 1;
        _slideIndex = _questions.length - 1; // 追加: 最新の質問を表示するためにインデックスを更新
      });
    } catch (e) {
      print('Error generating initial question: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.errorOccurred),
      ));
    }
  }

  void _handleUserAnswer() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterAnswer)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String userAnswer = _textController.text;
    _conversationHistory.add(userAnswer);
    _textController.clear();

    try {
      // ユーザーの回答から話題を抽出
      String extractedTopic = await _geminiService.extractTopics(
        userAnswer,
        _selectedInterests.join(', '),
      );

      // 次の質問を生成
      String language = Localizations.localeOf(context).languageCode;
      String nextQuestion = await _geminiService.generatePersonalizedQuestion(
        widget.deckId,
        _selectedInterests.join(', '),
        userAnswer,
        extractedTopic,
        _questions,
        language,
      );

      setState(() {
        _questions.add(nextQuestion);
        _slideIndex = _questions.length - 1;
        _conversationStage++;

        if (_conversationStage > _maxConversationStages) {
          // パーソナライズされたデッキの表示や次の画面への遷移をここで実装
          // 例: Navigator.push(...)
        }
      });
    } catch (e) {
      print('Error handling user answer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        elevation: 0,
      ),
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_questions.isNotEmpty)
                      _buildQuestionCard(_questions[_slideIndex]),
                    SizedBox(height: 24),
                    _buildInputField(),
                    SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.question_answer, size: 48, color: _primaryColor),
            SizedBox(height: 16),
            Text(
              question,
              style: TextStyle(fontSize: _questionFontSize, fontWeight: FontWeight.bold, color: _questionTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor, width: 2),
      ),
      child: TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.inputHint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleUserAnswer,
      child: Text(
        _conversationStage == _maxConversationStages ? AppLocalizations.of(context)!.personalizeAction : AppLocalizations.of(context)!.nextAction,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class MultiSelectChip extends StatefulWidget {
  final List<String> reportList;
  final Function(List<String>) onSelectionChanged;

  MultiSelectChip(this.reportList, {required this.onSelectionChanged});

  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  List<String> selectedChoices = [];

  _buildChoiceList() {
    List<Widget> choices = [];

    widget.reportList.forEach((item) {
      choices.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedChoices.contains(item),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedChoices.add(item);
              } else {
                selectedChoices.remove(item);
              }
              widget.onSelectionChanged(selectedChoices);
            });
          },
        ),
      ));
    });

    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: _buildChoiceList(),
    );
  }
}