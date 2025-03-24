import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'user';
  static User? _currentUser;

  // Get the current logged-in user
  static User? get currentUser => _currentUser;

  // Initialize the auth service
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = User.fromJson(json.decode(userJson));
    }
  }

  // Login with email and password
  static Future<User> login(String email, String password) async {
    // TODO: Implement actual API call for authentication
    await Future.delayed(Duration(seconds: 2)); // Simulate API call

    // For demo purposes, create a mock user
    final user = User(
      id: '1',
      name: 'John Doe',
      email: email,
      createdAt: DateTime.now(),
    );

    // Save user to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));

    _currentUser = user;
    return user;
  }

  // Register a new user
  static Future<User> register(String name, String email, String password) async {
    // TODO: Implement actual API call for registration
    await Future.delayed(Duration(seconds: 2)); // Simulate API call

    // For demo purposes, create a mock user
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    // Save user to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));

    _currentUser = user;
    return user;
  }

  // Logout the current user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _currentUser = null;
  }

  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;
}