import 'package:flutter/material.dart';
import 'course_detail_screen.dart'; // 新しいページをインポート

class CreateCourseScreen extends StatelessWidget {
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
          List<String> professions = categories[category]!;
          return Card(
            margin: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.headlineSmall, // Updated from headline6 to headlineSmall
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                  ),
                  itemCount: professions.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(
                              category: category,
                              profession: professions[index],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: Center(
                          child: Text(
                            professions[index],
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}