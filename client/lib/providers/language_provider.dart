import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('hu');

  Locale get currentLocale => _currentLocale;
  String get languageCode => _currentLocale.languageCode;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('selected_language');
    if (savedLang != null) {
      _currentLocale = Locale(savedLang);
    } else {
      final systemLocale = const Locale('hu');
      if (systemLocale.languageCode == 'hu') {
        _currentLocale = const Locale('hu');
      } else {
        _currentLocale = const Locale('en');
      }
    }
    notifyListeners();
  }

  String getText(String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'hu': {
      'register_button_main': 'Még nincs fiókod? Regisztráció',
      'login_button_main': 'Már van fiókod? Bejelntkezés',
      'username_hint': 'Felhasználónév',
      'email_hint': 'Email',
      'password_hint': 'Jelszó',
      'continue_register': 'Regisztráció folytatása',
      'my_details': 'Adataim',
      'height': 'Magasság',
      'weight': 'Súly',
      'born_in': 'Szül. idő',
      'gender': 'Nem',
      'male': 'Férfi',
      'female': 'Nő',
      'goals': 'Célok',
      'bulking': 'Tömegelés',
      'level_maintenance': 'Szintentartás',
      'weight_loss': 'Fogyás',
      'activity': 'Aktivitás',
      'slightly_active': 'Enyhén aktív',
      'slightly_active_desc': 'Napi séta, heti 1-3 könnyű edzés.',
      'moderately_active': 'Közepesen aktív',
      'moderately_active_desc': 'Heti 3-5 edzés, ülőmunka.',
      'very_active': 'Nagyon aktív',
      'very_active_desc': 'Napi edzés, fizikai munka.',
      'extremely_active': 'Extrém aktív',
      'extremely_active_desc': 'Napi 2 edzés, például sportkarrier.',
      'finish_register': 'Regisztráció befejezése',
      'username_and_email_hint': 'Felhasználónév / Email',
      'login': 'Bejelentkezés',
      'home_page': 'Főoldal',
      'calorie_deficit': 'Kalóriadeficit',
      'recent_workout': 'Legutóbbi edzés',
      'recent_meal': 'Legutóbbi étkezés',
      'workout_page': 'Edzés',
      'previous_workouts': 'Korábbi edzések',
      'previous_meals': 'Korábbi étkezések',
      'my_templates': 'Sablonjaim',
      'health_page': 'Egészség',
      'nutrients_consumed': 'Bevitt tápanyagok',
      'protein': 'Fehérje',
      'carbs': 'Szénhidrát',
      'fat': 'Zsír',
      'profile_page': 'Profil',
      'personal_details': 'Személyes adatok',
      'user': 'Felhasználó',
      'calories': 'Kalória',
      'daily_goals': 'Napi célok',
      'modify_details': 'Adatok módosítása',
      'logout': 'Kijelentkezés',
      'language': 'Nyelv',
      'new_password': 'Új jelszó',
      'save_changes': 'Módosítások mentése',
      'no_data_on_this_day': 'Ezen a napon nincs adat',
      'close': 'Bezárás',
      'add_new_meal': 'Új étkezés hozzáadása',
      'new_meal': 'Új étkezés',
      'breakfast': 'Reggeli',
      'lunch': 'Ebéd',
      'dinner': 'Vacsora',
      'other': 'Egyéb',
      'no_added_meal_yet': 'Nincsenek hozzáadott ételek',
      'summary': 'Összegzés',
      'add': 'Hozzáadás',
      'continue': 'Tovább',
      'save_sample': 'Sablon mentése',
      'sample_name': 'Sablon neve',
      'save_without_sample': 'Mentés sablon nélkül',
      'save': 'Mentés',
      'search_hint': 'Keresés',
      'choose_quantity': 'válassz mennyiséget!',
      'save_as_meal': 'Mentés étkezésként',
      'edit': 'Szerkesztés',
      'continue_meal': 'Étkezés folytatása',
      'create_new': 'Új létrehozása',
      'new_workout': 'Új edzés',
      'no_added_exercise_yet': 'Nincsenek hozzáadott gyakorlatok',
      'no_added_template_yet': 'Nincsenek hozzáadott sablonok',
      'start': 'Kezdés',
      'delete': 'Törlés',
      'unknown_template': 'Ismeretlen sablon',
      'piece(s)': 'Darab',
      'portion': 'Adag',
      'description': 'Leírás',
      'category': 'Kategória',
      'equipment': 'Felszerelés',
      'force': 'Típus',
      'mechanic': 'Mechanic',
      'level': 'Szint',
      'primary_muscles': 'Elsődleges izomcsoport',
      'cancel': 'Mégse',
      'loading': 'Betöltés',
      'exercise': 'Gyakorlat',
      'set(s)': 'gyakorlat(ok)',
    },
    'en': {
      'register_button_main': "Don't have an account yet? Register",
      'login_button_main': 'Do you have an account? Login',
      'username_hint': 'Username',
      'email_hint': 'Email',
      'password_hint': 'Password',
      'continue_register': 'Continue registration',
      'my_details': 'My details',
      'height': 'Height',
      'weight': 'Weight',
      'born_in': 'Date of birth',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'goals': 'Goals',
      'bulking': 'Bulking',
      'level_maintenance': 'Level maintenance',
      'weight_loss': 'Weight loss',
      'activity': 'Activity',
      'slightly_active': 'Slightly active',
      'slightly_active_desc': 'Daily walking, 1-3 light workout per week.',
      'moderately_active': 'Moderately active',
      'moderately_active_desc': '3-5 workout per week, sedentary work.',
      'very_active': 'Very active',
      'very_active_desc': 'Daily workout, physical work.',
      'extremely_active': 'Extremely active',
      'extremely_active_desc': '2 daily workouts, e.g. sports career.',
      'finish_register': 'Finish registration',
      'username_and_email_hint': 'Username / Email',
      'login': 'Login',
      'home_page': 'Home',
      'calorie_deficit': 'Calorie deficit',
      'recent_workout': 'Recent workout',
      'recent_meal': 'Recent meal',
      'workout_page': 'Workout',
      'previous_workouts': 'Previous workouts',
      'previous_meals': 'Previous meals',
      'my_templates': 'My templates',
      'health_page': 'Health',
      'nutrients_consumed': 'Nutrients consumed',
      'protein': 'Protein',
      'carbs': 'Carbonhidrates',
      'fat': 'Fat',
      'profile_page': 'Profile',
      'personal_details': 'Personal details',
      'user': 'User',
      'calories': 'Calories',
      'daily_goals': 'Daily goals',
      'modify_details': 'Modify details',
      'logout': 'Logout',
      'language': 'Language',
      'new_password': 'New password',
      'save_changes': 'Save changes',
      'no_data_on_this_day': 'No data on this day',
      'close': 'Close',
      'add_new_meal': 'Add new meal',
      'new_meal': 'New meal',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'other': 'Other',
      'no_added_meal_yet': 'No added meal yet',
      'summary': 'Summary',
      'add': 'Add',
      'continue': 'Continue',
      'save_sample': 'Save sample',
      'sample_name': 'Sample name',
      'save_without_sample': 'Save without sample',
      'save': 'Save',
      'search_hint': 'Search',
      'choose_quantity': 'Choose quantity!',
      'save_as_meal': 'Save as meal',
      'edit': 'Edit',
      'continue_meal': 'Continue meal',
      'create_new': 'Create new',
      'new_workout': 'New workout',
      'no_added_exercise_yet': 'No added exercise yet',
      'no_added_template_yet': 'No added template yet',
      'start': 'Start',
      'delete': 'Delete',
      'unknown_template': 'Unknown template',
      'piece(s)': 'piece(s)',
      'portion': 'Portion',
      'description': 'Description',
      'category': 'Category',
      'equipment': 'Equipment',
      'force': 'Force',
      'mechanic': 'Mechanic',
      'level': 'Level',
      'primary_muscles': 'Primary muscle',
      'cancel': 'Cancel',
      'loading': 'Loading',
      'exercise': 'Exercise',
      'set(s)': 'set(s)',
    },
  };
}
