import 'package:flutter/material.dart';
import 'course_detail_screen.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart'; // Import for localization

class CreateCourseScreen extends StatefulWidget {
  @override
  _CreateCourseScreenState createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  String? selectedCategory;
  String? selectedProfession;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> categories = {
      AppLocalizations.of(context)!.medicalProfessionals: [
        AppLocalizations.of(context)!.doctor,
        AppLocalizations.of(context)!.dentist
      ],
      AppLocalizations.of(context)!.nursingProfessionals: [
        AppLocalizations.of(context)!.nurse,
        AppLocalizations.of(context)!.midwife,
        AppLocalizations.of(context)!.publicHealthNurse
      ],
      AppLocalizations.of(context)!.pharmacyAndNutrition: [
        AppLocalizations.of(context)!.pharmacist,
        AppLocalizations.of(context)!.registeredDietitian
      ],
      AppLocalizations.of(context)!.rehabilitationAndTherapy: [
        AppLocalizations.of(context)!.physicalTherapist,
        AppLocalizations.of(context)!.occupationalTherapist,
        AppLocalizations.of(context)!.speechLanguageHearingTherapist,
        AppLocalizations.of(context)!.prosthetistAndOrthotist,
        AppLocalizations.of(context)!.anmaMassageShiatsuPractitioner,
        AppLocalizations.of(context)!.judoTherapist,
        AppLocalizations.of(context)!.acupuncturistAndMoxibustionTherapist
      ],
      AppLocalizations.of(context)!.diagnosticAndSupportTechnicians: [
        AppLocalizations.of(context)!.clinicalLaboratoryTechnician,
        AppLocalizations.of(context)!.radiologicalTechnologist,
        AppLocalizations.of(context)!.clinicalEngineer,
        AppLocalizations.of(context)!.dentalHygienist,
        AppLocalizations.of(context)!.dentalTechnician,
        AppLocalizations.of(context)!.orthoptist,
        AppLocalizations.of(context)!.emergencyMedicalTechnician
      ],
      AppLocalizations.of(context)!.mentalHealthAndWelfare: [
        AppLocalizations.of(context)!.mentalHealthSocialWorker,
        AppLocalizations.of(context)!.certifiedPsychologist,
        AppLocalizations.of(context)!.certifiedCareWorker
      ],
    };

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
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.black54), // Match AppBar text style
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
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: professions.map((profession) => ListTile(
            title: Text(
              profession,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Colors.black54,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailScreen(
                    category: category,
                    profession: profession,
                    language: AppLocalizations.of(context)!.localeName, // 'language' パラメータを追加
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