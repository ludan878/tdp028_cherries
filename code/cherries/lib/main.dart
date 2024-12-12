import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Required for async initialization
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString('userId'); // Retrieve the userId from SharedPreferences

    setState(() {
      _isLoggedIn = userId != null; // Check if a userId exists
      _userId = userId; // Save the userId if logged in
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Navigate to MainNavigation if logged in; otherwise, go to LoginPage
    return _isLoggedIn
        ? MainNavigation(userId: _userId!) // Pass userId to MainNavigation
        : const LoginPage();
  }
}
