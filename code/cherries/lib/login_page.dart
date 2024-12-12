import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_bar.dart';
import 'username_setup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _googleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Force account picker

      // Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        print('Signed in with UID: ${user.uid}');
        // Check if the user exists in Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          print('New user detected: ${user.uid}');
          // Navigate to username setup page for new users
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => UsernameSetupPage(
                userId: user.uid,
                email: user.email ?? '',
                photoUrl: user.photoURL,
              ),
            ),
          );
        } else {
          print('Existing user detected: ${user.uid}');
          // Save session for returning users
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', user.uid); // Save the userId

          // Navigate to MainNavigation
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainNavigation(userId: user.uid),
            ),
          );
        }
      }
    } catch (e) {
      print('Error during Google Sign-In: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during Google Sign-In: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60, color: Colors.black),
              ),
              const SizedBox(height: 40),
              const Text(
                "Cherry'View",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton.icon(
                      onPressed: _googleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 24.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Image(
                        image: AssetImage('assets/google_logo.png'),
                        height: 24,
                      ),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
