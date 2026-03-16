import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveToken(String token) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<String?> getToken() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<void> saveUserName(String name) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_name', name);
}

Future<String?> getUserName() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_name');
}

Future<void> saveUserId(int userId) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('user_id', userId);
}

Future<int?> getUserId() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('user_id');
}

Future<void> saveUserEmail(String email) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_email', email);
}

Future<String?> getUserEmail() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_email');
}

Future<void> saveUserPhone(String phone) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_phone', phone);
}

Future<String?> getUserPhone() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_phone');
}



Future<void> setIsLogedIn(bool isLogedIn) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('user_isLogedIn', isLogedIn);
}
Future<bool?> getIsLogedIn() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('user_isLogedIn');
}
Future<void> saveTokenToPrefs(String? token) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcm_token', token ?? "");
}
