//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: constants.dart holds the fixed choice lists used by the enrolment form dropdowns
// (grades, genders and guardian relationships).

/// AppLists (class) - static-only collection of dropdown options; the private constructor
/// AppLists._() prevents instances.
class AppLists {
  AppLists._();

  /// applyGrades - the grades a learner can apply for (Grade 8 to Grade 12).
  /// Grades offered for admission (high school).
  static const List<String> applyGrades = [
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  /// passedGrades - the options for "highest grade passed" (Grade 7 to Grade 11).
  /// Highest grade passed may include primary grades.
  static const List<String> passedGrades = [
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
  ];

  /// genders - the gender options on the learner step.
  static const List<String> genders = ['Male', 'Female'];

  /// relationships - the options for the guardian's relationship to the learner.
  static const List<String> relationships = [
    'Mother',
    'Father',
    'Legal Guardian',
    'Grandparent',
    'Aunt / Uncle',
    'Sibling',
    'Other',
  ];
}
