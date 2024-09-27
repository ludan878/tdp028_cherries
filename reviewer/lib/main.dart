import 'package:flutter/material.dart';
import 'pages.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reviewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/home', // Set initial route to /home
      routes: {
        '/home': (context) =>
            MyHomePage(title: 'Home Page'), // Ensure this route is correct
        '/text': (context) => TextPage(),
        '/img': (context) => MyHomePage(title: "Image Page"),
      },
    );
  }
}
