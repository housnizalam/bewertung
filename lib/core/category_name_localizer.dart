import 'package:flutter/widgets.dart';

const Map<String, String> _defaultArabicToEnglish = <String, String>{
  'ديني': 'Religion',
  'أخلاقي': 'Ethics',
  'عائلة': 'Family',
  'عمل': 'Work',
  'صحة': 'Health',
  'تعلّم': 'Learning',
  'رياضة': 'Sport',
  'أخرى': 'Other',
};

const Map<String, String> _defaultEnglishToArabic = <String, String>{
  'Religion': 'ديني',
  'Ethics': 'أخلاقي',
  'Family': 'عائلة',
  'Work': 'عمل',
  'Health': 'صحة',
  'Learning': 'تعلّم',
  'Sport': 'رياضة',
  'Other': 'أخرى',
};

String localizedCategoryName(
  BuildContext context,
  String name, {
  required bool isDefault,
}) {
  if (!isDefault) return name;

  final languageCode = Localizations.localeOf(context).languageCode;
  if (languageCode == 'ar') {
    return _defaultEnglishToArabic[name] ?? name;
  }

  return _defaultArabicToEnglish[name] ?? name;
}
