import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/patient.dart';
import '../models/heart_rate.dart';
import '../models/alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_metric.dart';
import '../models/appointment.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration timeoutDuration = Duration(seconds: 10);
  static const int maxRetries = 3;

  final Map<String, dynamic> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static String? get token => _token;

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'];

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      return data;
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to login');
    }
  }

  static Future<Map<String, dynamic>> register(String username, String password, String role) async {
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
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to register');
    }
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Patient endpoints
  Future<List<Patient>> getPatients() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/patients'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Patient.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load patients');
    }
  }

  Future<Patient> getPatient(int id) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/patients/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Patient.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load patient');
    }
  }

  Future<Patient> createPatient(Patient patient) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/patients'),
      headers: _headers,
      body: json.encode(patient.toJson()),
    );

    if (response.statusCode == 201) {
      return Patient.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create patient');
    }
  }

  Future<Patient> updatePatient(int id, Patient patient) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$baseUrl/patients/$id'),
      headers: _headers,
      body: json.encode(patient.toJson()),
    );

    if (response.statusCode == 200) {
      return Patient.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update patient');
    }
  }

  Future<void> deletePatient(int id) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/patients/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete patient');
    }
  }

  // Heart rate endpoints
  Future<List<HeartRate>> getHeartRateHistory() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/health/heart-rate/history'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => HeartRate.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load heart rate history');
    }
  }

  Future<HeartRate> addHeartRateReading(HeartRate reading) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/heart-rate'),
      headers: _headers,
      body: json.encode(reading.toJson()),
    );

    if (response.statusCode == 201) {
      return HeartRate.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add heart rate reading');
    }
  }

  Future<HeartRateStatistics> getHeartRateStatistics(int patientId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/heart-rate/$patientId/statistics'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return HeartRateStatistics.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load heart rate statistics');
    }
  }

  // Alert endpoints
  Future<List<Alert>> getActiveAlerts(int patientId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId/alerts'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Alert.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load alerts');
    }
  }

  Future<void> updateAlertStatus(int alertId, String status) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$baseUrl/heart-rate/alerts/$alertId'),
      headers: _headers,
      body: json.encode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update alert status');
    }
  }

  Future<Map<String, dynamic>> getMeasurements() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/health/measurements'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load measurements');
    }
  }

  Future<void> saveMeasurement(Map<String, dynamic> data) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/health/measurements'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save measurement');
    }
  }

  Future<Map<String, dynamic>> getLatestHealthMetrics() async {
    const String endpoint = '/health/latest';
    final cacheKey = 'latest_metrics';

    // Check cache first
    if (_cache.containsKey(cacheKey) &&
        DateTime.now().difference(_cache['${cacheKey}_time']) < _cacheDuration) {
      return _cache[cacheKey];
    }

    try {
      final response = await _makeRequest(
        'GET',
        endpoint,
        withAuth: true,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Cache the result
        _cache[cacheKey] = data;
        _cache['${cacheKey}_time'] = DateTime.now();
        return data;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      // Return cached data if available during error
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey];
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivityData() async {
    const String endpoint = '/health/weekly';
    final cacheKey = 'weekly_activity';

    if (_cache.containsKey(cacheKey) &&
        DateTime.now().difference(_cache['${cacheKey}_time']) < _cacheDuration) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await _makeRequest(
        'GET',
        endpoint,
        withAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> typedData =
            data.map((item) => Map<String, dynamic>.from(item)).toList();

        _cache[cacheKey] = typedData;
        _cache['${cacheKey}_time'] = DateTime.now();
        return typedData;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (_cache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(_cache[cacheKey]);
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    const String endpoint = '/appointments/upcoming';
    final cacheKey = 'upcoming_appointments';

    if (_cache.containsKey(cacheKey) &&
        DateTime.now().difference(_cache['${cacheKey}_time']) < _cacheDuration) {
      return List<Map<String, dynamic>>.from(_cache[cacheKey]);
    }

    try {
      final response = await _makeRequest(
        'GET',
        endpoint,
        withAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> typedData =
            data.map((item) => Map<String, dynamic>.from(item)).toList();

        _cache[cacheKey] = typedData;
        _cache['${cacheKey}_time'] = DateTime.now();
        return typedData;
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      if (_cache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(_cache[cacheKey]);
      }
      rethrow;
    }
  }

  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    int retryCount = 0,
  }) async {
    final Uri uri = Uri.parse('$baseUrl$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers)
              .timeout(timeoutDuration);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: json.encode(body),
          ).timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: json.encode(body),
          ).timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers)
              .timeout(timeoutDuration);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Handle rate limiting
      if (response.statusCode == 429 && retryCount < maxRetries) {
        final retryAfter = int.tryParse(
          response.headers['retry-after'] ?? '5'
        ) ?? 5;
        await Future.delayed(Duration(seconds: retryAfter));
        return _makeRequest(
          method,
          endpoint,
          body: body,
          withAuth: withAuth,
          retryCount: retryCount + 1,
        );
      }

      return response;
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Exception _handleError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return ApiException('Bad request: ${_parseErrorMessage(response)}');
      case 401:
        return UnauthorizedException('Unauthorized: ${_parseErrorMessage(response)}');
      case 403:
        return ForbiddenException('Forbidden: ${_parseErrorMessage(response)}');
      case 404:
        return NotFoundException('Not found: ${_parseErrorMessage(response)}');
      case 500:
        return ApiException('Server error: ${_parseErrorMessage(response)}');
      default:
        return ApiException('Unknown error: ${response.statusCode}');
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final body = json.decode(response.body);
      return body['message'] ?? body['error'] ?? 'Unknown error';
    } catch (e) {
      return response.body;
    }
  }

  void clearCache() {
    _cache.clear();
  }

  void clearCacheEntry(String key) {
    _cache.remove(key);
    _cache.remove('${key}_time');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}