import 'package:flutter/material.dart';
import 'course_detail_screen.dart'; // 新しいページをインポート

class CreateCourseScreen extends StatefulWidget {
  @override
  _CreateCourseScreenState createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  // Define the main categories and their submenus
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

  // Track expanded categories
  Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Initialize all categories as collapsed
    categories.keys.forEach((category) {
      _expandedCategories[category] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your Own Course'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          String category = categories.keys.elementAt(index);
          return ExpansionTile(
            title: Text(category),
            children: categories[category]!.map((subCategory) {
              return ListTile(
                title: Text(subCategory),
                onTap: () {
                  // 職業がクリックされたら新しいページに移動
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(
                        category: category,
                        profession: subCategory,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedCategories[category] = expanded;
              });
            },
          );
        },
      ),
    );
  }
}