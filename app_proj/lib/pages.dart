import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  NetworkImage _image = const NetworkImage('https://picsum.photos/200/300');

  void _buttonPress() {
    setState(() {
      _counter++;
      _image = NetworkImage('https://picsum.photos/200/300?random=$_counter');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: _image,
            ),
            const SizedBox(height: 20),
            Text(
              'Random Image Generator',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _buttonPress,
        tooltip: 'Press to see something cool!',
        child: const Icon(Icons.add),
      ),
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
        ],
        currentIndex: 1,
        onTap: (int index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/text');
          }
        },
      ),
    );
  }
}

class TextPage extends StatefulWidget {
  const TextPage({super.key});

  @override
  TextPageState createState() => TextPageState();
}

class TextPageState extends State<TextPage> {
  List<String> _randomTexts = [];
  String _displayedText = "Press the button!";

  @override
  void initState() {
    super.initState();
    _fetchRandomTexts();
  }

  Future<void> _fetchRandomTexts() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('randomTexts').get();
    final List<String> texts =
        snapshot.docs.map((doc) => doc['text'] as String).toList();
    // Log the texts to the console
    print(texts);
    setState(() {
      _randomTexts = texts;
    });
  }

  void _showRandomText() {
    if (_randomTexts.isNotEmpty) {
      setState(() {
        _displayedText = _randomTexts[Random().nextInt(_randomTexts.length)];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Random Text Generator"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _displayedText,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showRandomText,
              child: const Text("Show Random Text"),
            ),
          ],
        ),
      ),
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
        ],
        currentIndex: 0,
        onTap: (int index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/img');
          }
        },
      ),
    );
  }
}
