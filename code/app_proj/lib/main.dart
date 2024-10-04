import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return ShellPage(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => MyHomePage(title: 'Home Page'),
            ),
            GoRoute(
              path: "/",
              builder: (context, state) => MyHomePage(title: 'Home Page'),
            ),
            GoRoute(
              path: '/text',
              builder: (context, state) => TextPage(),
            ),
            GoRoute(
              path: '/img',
              builder: (context, state) => MyHomePage(title: 'Image Page'),
            ),
            GoRoute(
              path: '/live-update',
              builder: (context, state) => LiveUpdatePage(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: _router,
      title: 'Reviewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class ShellPage extends StatefulWidget {
  final Widget child;

  const ShellPage({required this.child});

  @override
  _ShellPageState createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    TextPage(),
    MyHomePage(title: 'Image Page'),
    LiveUpdatePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            label: 'Text',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Image',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.update),
            label: 'Live Update',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
