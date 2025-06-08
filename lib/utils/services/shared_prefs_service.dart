import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _prefsInstance;

Future<SharedPreferences> get prefs async {
  _prefsInstance ??= await SharedPreferences.getInstance();
  return _prefsInstance!;
}
