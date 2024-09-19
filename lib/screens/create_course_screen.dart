import 'package:flutter/material.dart';
import 'course_detail_screen.dart'; // 新しいページをインポート

class CreateCourseScreen extends StatefulWidget {
  @override
  _CreateCourseScreenState createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final Map<String, List<String>> categories = {
    'Medical Professionals': ['Doctor (Physician)', 'Dentist'],
    'Nursing Professionals': ['Nurse', 'Midwife', 'Public Health Nurse'],
    'Pharmacy and Nutrition': ['Pharmacist', 'Registered Dietitian (Nutritionist)'],
    'Rehabilitation and Therapy': [
      'Physical Therapist',
      'Occupational Therapist',
      'Speech-Language-Hearing Therapist',
      'Prosthetist and Orthotist',
      'Anma Massage Shiatsu Practitioner',
      'Judo Therapist',
      'Acupuncturist and Moxibustion Therapist'
    ],
    'Diagnostic and Support Technicians': [
      'Clinical Laboratory Technician',
      'Radiological Technologist',
      'Clinical Engineer',
      'Dental Hygienist',
      'Dental Technician',
      'Orthoptist',
      'Emergency Medical Technician (EMT)'
    ],
    'Mental Health and Welfare': [
      'Mental Health Social Worker',
      'Certified Psychologist',
      'Certified Care Worker'
    ],
  };

  String? selectedCategory;
  String? selectedProfession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your Own Course'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Text(
            'Select your profession:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          ...categories.entries.map((entry) => _buildCategoryExpansionTile(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildCategoryExpansionTile(String category, List<String> professions) {
    return Card(
      child: ExpansionTile(
        title: Text(category),
        children: professions.map((profession) => ListTile(
          title: Text(profession),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(
                  category: category,
                  profession: profession,
                ),
              ),
            );
          },
        )).toList(),
      ),
    );
  }
}