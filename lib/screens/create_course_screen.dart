import 'package:flutter/material.dart';
import 'course_detail_screen.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart'; // Import for localization

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
        title: Text(
          AppLocalizations.of(context)!.createYourOwnCourse, // Localized text
          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Text(
              AppLocalizations.of(context)!.selectYourProfession, // Localized text
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 16),
            ...categories.entries.map((entry) => _buildCategoryExpansionTile(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryExpansionTile(String category, List<String> professions) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            category,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          children: professions.map((profession) => ListTile(
            title: Text(
              profession,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
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
      ),
    );
  }
}