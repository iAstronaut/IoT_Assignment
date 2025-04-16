import 'package:flutter/material.dart';
import 'package:heart_pulse_app/screens/login_screen.dart';
import 'package:heart_pulse_app/screens/main_navigation.dart';
import 'package:heart_pulse_app/screens/measure_screen.dart';
import 'package:heart_pulse_app/screens/history_screen.dart';
import 'package:heart_pulse_app/screens/about_screen.dart';
import 'package:heart_pulse_app/screens/help_screen.dart';
import 'package:heart_pulse_app/theme/app_theme.dart';
import 'package:heart_pulse_app/services/auth_service.dart';
import 'package:heart_pulse_app/services/api_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Future.wait([
      AuthService.init(),
      ApiService.init(),
    ]);
    runApp(const MyApp());
  } catch (e) {
    print('Initialization error: $e');
    // Show error UI if needed
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Pulse Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AuthService.isLoggedIn ? '/home' : '/login',
      onGenerateRoute: (settings) {
        // Check if user is authenticated for protected routes
        if (!AuthService.isLoggedIn &&
            settings.name != '/login' &&
            settings.name != '/register') {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          );
        }

        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const MainNavigation(),
            );
          case '/measure':
            return MaterialPageRoute(
              builder: (_) => const MeasureScreen(),
            );
          case '/history':
            return MaterialPageRoute(
              builder: (_) => const HistoryScreen(),
            );
          case '/about':
            return MaterialPageRoute(
              builder: (_) => const AboutScreen(),
            );
          case '/help':
            return MaterialPageRoute(
              builder: (_) => const HelpScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const NotFoundScreen(),
            );
        }
      },
      builder: (context, child) {
        return MediaQuery(
          // Prevent system text scaling
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}