import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _userKey = 'user';
  static const String _tokenKey = 'token';
  static User? _currentUser;
  static const String baseUrl = 'http://localhost:3000/api';
  static const String coreIoTBaseUrl = 'https://app.coreiot.io/api';
  static const String coreIoTUsername = 'an.nguyencse03@gmail.com';
  static const String coreIOTPassword = '02121209An';

  // Get the current logged-in user
  static User? get currentUser => _currentUser;

  // Initialize the auth service
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = User.fromJson(json.decode(userJson));
      // Try to refresh CoreIoT token if user exists
      await loginCoreIoT();
    }
  }

  // Login to Core IoT
  static Future<String?> loginCoreIoT() async {
    try {
      final response = await http.post(
        Uri.parse('$coreIoTBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': coreIoTUsername,
          'password': coreIOTPassword,
        }),
      );

      print('CoreIoT Status: ${response.statusCode}');
      print('CoreIoT Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        // Save token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        return token;
      }
      return null;
    } catch (e) {
      print('CoreIoT Login error: $e');
      return null;
    }
  }

  // Login with username and password
  static Future<User> login(String username, String password) async {
    try {
      final token = await loginCoreIoT();
      if (token == null) {
        throw Exception('Failed to login to CoreIoT');
      }

      final user = User(
        id: 1,
        username: username,
        role: 'user',
        createdAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toJson()));

      _currentUser = user;
      return user;
    } catch (e) {
      print('Login error: $e');
      throw Exception('Failed to login: $e');
    }
  }

  // Register a new user
  static Future<User> register(String username, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User(
          id: data['user']['id'],
          username: data['user']['username'],
          role: data['user']['role'],
          createdAt: DateTime.parse(data['user']['createdAt'] ?? DateTime.now().toIso8601String()),
        );

        // Save user to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(user.toJson()));

        _currentUser = user;

        // Call Core IoT API after successful registration
        await loginCoreIoT();

        return user;
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to register');
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Failed to register: $e');
    }
  }

  // Logout the current user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    _currentUser = null;
  }

  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;

  // Get current token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      // Try to refresh token if not found
      return await loginCoreIoT();
    }
    return token;
  }
}