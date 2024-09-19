import 'package:flutter/material.dart';
import '../services/create_course_gemini_service.dart';
import '../services/medlm_service.dart';

class CreateCourseScreen extends StatefulWidget {
  @override
  _CreateCourseScreenState createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCreating = false;

  void _createCourse() async {
    setState(() {
      _isCreating = true;
    });

    String title = _titleController.text;
    String description = _descriptionController.text;

    try {
      // AIエージェントによるコース内容の生成
      var geminiService = CreateCourseGeminiService();
      var courseData = await geminiService.generateCourseData(title, description, 'gemini-1.5-flash');

      // コースをFirestoreに保存
      var medlmService = MedlmService();
      await medlmService.createCourse(courseData); // Stringを渡す

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course created successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error creating course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create course')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your Own Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Course Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Course Description'),
            ),
            SizedBox(height: 20),
            _isCreating
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createCourse,
                    child: Text('Create Course'),
                  ),
          ],
        ),
      ),
    );
  }
}