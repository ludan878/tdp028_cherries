import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_bar.dart';

class UsernameSetupPage extends StatefulWidget {
  final String userId;
  final String email;
  final String? photoUrl;

  const UsernameSetupPage({
    super.key,
    required this.userId,
    required this.email,
    this.photoUrl,
  });

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isChecking = false;
  String? _errorMessage;

  Future<void> _saveUser(String username) async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Check if the username is already taken
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'Username is already taken.';
        });
      } else {
        // Save user to Firestore
        await _firestore.collection('users').doc(widget.userId).set({
          'username': username,
          'email': widget.email,
          'profilePicture': widget.photoUrl ?? '',
          'followers': 0,
          'follows': 0,
          'likes': 0,
          'reviews': [], // Add an empty reviews array for future reviews
        });

        // Navigate to Main Page with userId
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainNavigation(userId: widget.userId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose a Username',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your username',
                hintStyle: const TextStyle(color: Colors.grey),
                errorText: _errorMessage,
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isChecking
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
                    onPressed: () => _saveUser(_usernameController.text.trim()),
                    child: const Text('Save Username'),
                  ),
          ],
        ),
      ),
    );
  }
}
